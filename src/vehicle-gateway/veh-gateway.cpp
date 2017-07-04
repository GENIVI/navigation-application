/**************************************************************************
* @licence app begin@
*
* SPDX-License-Identifier: MPL-2.0
*
* \ingroup Vehicle gateway
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \copyright Copyright (C) 2017, PSA Group
* 
* \license
* This Source Code Form is subject to the terms of the
* Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
* this file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
* @licence end@
**************************************************************************/

#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <memory.h>
#include <time.h>
#include <inttypes.h>
#include <pthread.h>
#include <semaphore.h>
#include <termios.h>

#include <common.h>
#include <obd2.h>
#include <gnss.h>

#include <log.h>

#define MSGIDLEN 20
#define BUFLEN 256
#define PORT1 9930   //port used for GNSS data
#define PORT2 9931   //port used for sensor data
#define PORT3 9932   //port used for vehicle data
const char * IPADDR_DEFAULT = "127.0.0.1";

#define SCAN_LOOP_TIME 100000 //100 ms
#define MAXDELTA 1000  //max value to avoid overflow

#define BAUDRATE_OBD2 B38400

#define NMEA_TOKEN ","
#define NMEA_RMC_STATUS 2
#define NMEA_RMC_LATITUDE 3
#define NMEA_RMC_LATITUDE_INDICATOR 4
#define NMEA_RMC_LONGITUDE 5
#define NMEA_RMC_LONGITUDE_INDICATOR 6
#define NMEA_RMC_DATE 9
#define NMEA_DATA_VALID "A"
#define NMEA_WEST "W"
#define NMEA_SOUTH "S"
#define BAUDRATE_GNSS B38400

#define CAN_MESSAGE_FILTER 0x123
#define CAN_MESSAGE_MASK 0x7FF

typedef struct
{
    double latitude;
    double longitude;
    double altitude;
} geocoordinate3D_t;

DLT_DECLARE_CONTEXT(gContext);

bool isRunning=true;
bool can_reader_mode;

static int g_obd2_fd = -1;
static struct termios g_oldtio;

//scan the buffer, if nmea status is OK (so there's a valid location)
//allocate the memory and compose the frame into sock_buf
bool get_geolocation(char*& sock_buf,char* buffer,const uint64_t timestamp)
{
    geocoordinate3D_t geolocation;
    char* tmp = new char[BUFLEN];
    char *token;
    uint8_t cnt=0;
    bool retval = false;
    double fract;
    geolocation.latitude=0;
    geolocation.longitude=0;
    geolocation.altitude=0;
    token=strtok(buffer,NMEA_TOKEN); //to load the pipe
    cnt++;
    while(token != NULL)
    {
        token=strtok(NULL,NMEA_TOKEN);
        switch (cnt) {
        case NMEA_RMC_STATUS:
            if(strcmp(token,NMEA_DATA_VALID)==0){
                retval=true;
            }else{
                LOG_INFO_MSG(gContext,"NMEA DATA NOT VALID");
                return retval;
            }
            break;
        case NMEA_RMC_LATITUDE:
            fract=modf(atof(token)/100,&(geolocation.latitude));
            geolocation.latitude+=(fract*100)/60;
            break;
        case NMEA_RMC_LATITUDE_INDICATOR:
            if(token==NMEA_SOUTH) geolocation.latitude=(-1)*geolocation.latitude;
            break;
        case NMEA_RMC_LONGITUDE:
            fract=modf(atof(token)/100,&(geolocation.longitude));
            geolocation.longitude+=(fract*100)/60;
            break;
        case NMEA_RMC_LONGITUDE_INDICATOR:
            if(token==NMEA_WEST) geolocation.longitude=(-1)*geolocation.longitude;
            break;
        case NMEA_RMC_DATE:
            //to do
            break;
        default:
            break;
        }
        cnt++;
    }
    LOG_DEBUG(gContext,"Lat: %f Lon: %f Alt: %f",geolocation.latitude,geolocation.longitude,geolocation.altitude);

    //compose frame data: TIMESTAMP,0$GVGNSP,TIMESTAMP,LAT,LON,ALT,0X07
    sprintf(tmp,"%d,%s,%d,%.6f,%.6f,%.6f,0x07",timestamp,"0$GVGNSP",timestamp,geolocation.latitude,geolocation.longitude,geolocation.altitude);
    sock_buf=tmp;
    return retval;
}

bool get_engine_speed(char*& sock_buf)
{
    uint16_t rpm;
    uint64_t timestamp;
    char* tmp = new char[BUFLEN];

    if(can_reader_mode){
        if (can_read_engine_rpm(rpm,timestamp)!=true){
            LOG_ERROR_MSG(gContext,"Read engine rpm failed");
            return false;
        }
    }else{
        if (obd2_read_engine_rpm(rpm,timestamp)!=true){
            LOG_ERROR_MSG(gContext,"Read engine rpm failed");
            return false;
        }
    }

    LOG_DEBUG(gContext,"Engine speed: %d",rpm);

    //compose frame data: TIMESTAMP,0$GVVEHENGSPEED,TIMESTAMP,RPM,0X01
    sprintf(tmp,"%d,%s,%d,%d,0x01",timestamp,"0$GVVEHENGSPEED",timestamp,rpm);
    sock_buf=tmp;

    return true;
}

bool get_fuel_tank_level(char*& sock_buf)
{
    uint8_t fuel_level;
    uint64_t timestamp;
    char* tmp = new char[BUFLEN];

    if(can_reader_mode){
        if (can_read_fuel_tank_level(fuel_level,timestamp)!=true){
            LOG_ERROR_MSG(gContext,"Read fuel tank level failed");
            return false;
        }
    }else{
        if (obd2_read_fuel_tank_level(fuel_level,timestamp)!=true){
            LOG_ERROR_MSG(gContext,"Read fuel tank level failed");
            return false;
        }
    }

    LOG_DEBUG(gContext,"Fuel tank level: %d\%",fuel_level);

    //compose frame data: TIMESTAMP,0$GVVEHFUELLEVEL,TIMESTAMP,LEVEL,0X01
    sprintf(tmp,"%d,%s,%d,%d,0x01",timestamp,"0$GVVEHFUELLEVEL",timestamp,fuel_level);
    sock_buf=tmp;

    return true;
}

bool get_vehicle_speed(char*& sock_buf)
{
    return false;
}

//GVVEHFUELLEVEL
//GVVEHFUELCONS
//GVVEHTOTALODO

void sighandler(int sig)
{
  LOG_INFO_MSG(gContext,"Signal received");
  isRunning = false;
}

int main(int argc, char* argv[])
{
    // socket
    struct sockaddr_in si_other;
    socklen_t slen = sizeof(si_other);
    int sock;
    char* sock_buf;
    char * ipaddr = 0;

    // OBD and GNSS devices
    bool result;
    uint64_t start, stop;
    char * modem_device_obd2 = 0;
    char * modem_device_gnss = 0;
    char gnss_buf[MAX_GNSS_BUFFER_SIZE];
    uint64_t gnss_timestamp;

    // default arguments
    can_reader_mode=false;
    ipaddr = (char*)IPADDR_DEFAULT;
    // arguments check
    if(argc < 3)
    {
       LOG_ERROR_MSG(gContext,"missing input parameters: ELM327DEVICE GNSSDEVICE");
       return EXIT_FAILURE;
    }
    else
    {
        modem_device_obd2 = argv[1];
        modem_device_gnss = argv[2];
        if(argc == 4)
            can_reader_mode= argv[3];
        else{
            if(argc == 5)
                ipaddr = argv[4];
            else
            if(argc > 5)
                LOG_ERROR_MSG(gContext,"two many parameters");
        }
    }


    // DLT init and start banner
    DLT_REGISTER_APP("GTWY", "VEH-GATEWAY");
    DLT_REGISTER_CONTEXT(gContext,"EMBD", "Global Context");

    LOG_INFO_MSG(gContext,"------------------------------------------------");
    LOG_INFO_MSG(gContext,"VEH GATEWAY STARTED");
    LOG_INFO_MSG(gContext,"------------------------------------------------");

    // socket initialization
    signal(SIGTERM, sighandler);
    signal(SIGINT, sighandler);
    if((sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
    {
        LOG_ERROR_MSG(gContext,"socket() failed!");
        return EXIT_FAILURE;
    }

    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
    //si_other.sin_port = htons(<port number>);
    if(inet_aton(ipaddr, &si_other.sin_addr) == 0)
    {
        LOG_ERROR_MSG(gContext,"inet_aton() failed!");
        return EXIT_FAILURE;
    }

    LOG_INFO(gContext,"Started reading devices OBD2: %s GNSS: %s",modem_device_obd2, modem_device_gnss);

    // connect to the devices
    start = get_timestamp();
    result = obd2_init(modem_device_obd2, BAUDRATE_OBD2);
    stop = get_timestamp();
    if (result)
    {
      LOG_INFO(gContext,"INIT OBD2 OK [DURATION = %" PRIu64 " ms]", stop-start);
    }
    else
    {
      LOG_DEBUG(gContext,"INIT OBD2 FAILURE [DURATION = %" PRIu64 " ms]", stop-start);
      LOG_DEBUG(gContext,"Do you have access rights to %s ?", modem_device_obd2);
      return(-1);
    }

    gnssDataReady=false; //set the flag to false (no need of semaphore now because thread is not started yet)
    start = get_timestamp();
    result = gnss_init(modem_device_gnss, BAUDRATE_GNSS);
    stop = get_timestamp();
    if (result)
    {
      LOG_INFO(gContext,"INIT GNSS OK [DURATION = %" PRIu64 " ms]", stop-start);
    }
    else
    {
      LOG_DEBUG(gContext,"INIT GNSS FAILURE [DURATION = %" PRIu64 " ms]", stop-start);
      LOG_DEBUG(gContext,"Do you have access rights to %s ?", modem_device_gnss);
      return(-1);
    }

    // reset the OBD2 device
    start = get_timestamp();
    if(!obd2_reset(stop)){
        LOG_DEBUG(gContext,"RESET OBD2 FAILURE [DURATION = %" PRIu64 " ms]", stop-start);
        return(-1);
    }

    if(can_reader_mode){
        // can reader mode
        start = get_timestamp();
        if(!obd2_config_can_reader(stop)){
            LOG_DEBUG(gContext,"ECHO OFF OBD2 FAILURE [DURATION = %" PRIu64 " ms]", stop-start);
            return(-1);
        }
        start = get_timestamp();
        if(!obd2_set_filter(CAN_MESSAGE_FILTER,CAN_MESSAGE_MASK,stop)){
            LOG_DEBUG(gContext,"ECHO OFF OBD2 FAILURE [DURATION = %" PRIu64 " ms]", stop-start);
            return(-1);
        }
    }else{
        // config standard OBD2 with AT command
        start = get_timestamp();
        if(!obd2_config(stop)){
            LOG_DEBUG(gContext,"ECHO OFF OBD2 FAILURE [DURATION = %" PRIu64 " ms]", stop-start);
            return(-1);
        }
    }

    //config the GNSS device to send given frames (TBD)

    //main loop
    do{

        //GNSS: list of supported message IDs
        //char* gnssstr = "GVGNSP,GVGNSC,GVGNSAC,GVGNSSAT";
        //for the moment only GVGNSP is managed
        pthread_mutex_lock(&mutex_gnss);       /* down semaphore */
        if(gnssDataReady)
        {
            gnssDataReady=false;
            strcpy(gnss_buf,gnssBuffer); //get the gnss buffer (end of string is added in gnss code)
            gnss_timestamp=gnssTimestamp; //get the gnss timestamp
            pthread_mutex_unlock(&mutex_gnss);       /* up semaphore */
            if(get_geolocation(sock_buf,gnss_buf,gnss_timestamp))
            {
                LOG_DEBUG(gContext,"Sending Packet to %s:%d",ipaddr,PORT1);
                LOG_DEBUG(gContext,"Len:%d", (int)strlen(sock_buf));
                LOG_DEBUG(gContext,"Data:%s", sock_buf);

                si_other.sin_port = htons(PORT1);
                if(sendto(sock, sock_buf, strlen(sock_buf)+1, 0, (struct sockaddr *)&si_other, slen) == -1)
                {
                    LOG_ERROR_MSG(gContext,"sendto() failed!");
                    return EXIT_FAILURE;
                }
            }
        }else{
            pthread_mutex_unlock(&mutex_gnss);       /* up semaphore */
        }

        //SNS: list of supported message IDs
        //char* snsstr = "GVVEHSP,GVGYRO,GVGYROCONF,GVDRVDIR,GVODO,GVWHTK,GVWHTKCONF";
        //char* snsstr = "GVSNSVEHSP,GVSNSGYRO,GVSNSWHTK"; //subset currently supported for new log format
        //for the moment no ID managed
        if(get_vehicle_speed(sock_buf)){
            LOG_DEBUG(gContext,"Sending Packet to %s:%d",ipaddr,PORT2);
            LOG_DEBUG(gContext,"Len:%d", (int)strlen(sock_buf));
            LOG_DEBUG(gContext,"Data:%s", sock_buf);

            si_other.sin_port = htons(PORT2);
            if(sendto(sock, sock_buf, strlen(sock_buf)+1, 0, (struct sockaddr *)&si_other, slen) == -1)
            {
                LOG_ERROR_MSG(gContext,"sendto() failed!");
                return EXIT_FAILURE;
            }
        }

        //VHL: list of supported message IDs
        //char* vhlstr = "GVVEHVER,GVVEHENGSPEED,GVVEHFUELLEVEL,GVVEHFUELCONS,GVVEHTOTALODO";
        //for the moment GVVEHENGSPEED, GVVEHFUELLEVEL managed
        if(get_engine_speed(sock_buf))
        {
            LOG_DEBUG(gContext,"Sending Packet to %s:%d",ipaddr,PORT3);
            LOG_DEBUG(gContext,"Len:%d", (int)strlen(sock_buf));
            LOG_DEBUG(gContext,"Data:%s", sock_buf);

            si_other.sin_port = htons(PORT3);
            if(sendto(sock, sock_buf, strlen(sock_buf)+1, 0, (struct sockaddr *)&si_other, slen) == -1)
            {
                LOG_ERROR_MSG(gContext,"sendto() failed!");
                return EXIT_FAILURE;
            }
        }
        if(get_fuel_tank_level(sock_buf))
        {
            LOG_DEBUG(gContext,"Sending Packet to %s:%d",ipaddr,PORT3);
            LOG_DEBUG(gContext,"Len:%d", (int)strlen(sock_buf));
            LOG_DEBUG(gContext,"Data:%s", sock_buf);

            si_other.sin_port = htons(PORT3);
            if(sendto(sock, sock_buf, strlen(sock_buf)+1, 0, (struct sockaddr *)&si_other, slen) == -1)
            {
                LOG_ERROR_MSG(gContext,"sendto() failed!");
                return EXIT_FAILURE;
            }
        }

        usleep(SCAN_LOOP_TIME);
    } while(isRunning);

    LOG_INFO_MSG(gContext,"Shutting down Vehicle gateway...");

    gnss_destroy();

    /* restore the old port settings */
    tcsetattr(g_obd2_fd,TCSANOW,&g_oldtio);

    close(sock);

    return EXIT_SUCCESS;
}


