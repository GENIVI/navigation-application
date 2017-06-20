/**************************************************************************
* @licence app begin@
*
* SPDX-License-Identifier: MPL-2.0
*
* \ingroup LogReplayer
* \author Marco Residori <marco.residori@xse.de>
*
* \copyright Copyright (C) 2013, XS Embedded GmbH
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

#include <obd2.h>
#include <gnss.h>

#include <log.h>

#define MSGIDLEN 20
#define BUFLEN 256
#define PORT1 9930   //port used for GNSS data
#define PORT2 9931   //port used for sensor data
#define PORT3 9932   //port used for vehicle data
const char * IPADDR_DEFAULT = "127.0.0.1";
const char * GNS_PREFIX = "GVGNS";
const char * SNS_PREFIX = "GVSNS";
const char * VEH_PREFIX = "GVVEH";

#define MAXDELTA 1000  //max value to avoid overflow

#define BAUDRATE_OBD2 B38400
#define ELM_RESET_ALL "AT Z\r\n"
#define ELM_GET_ID "AT I\r\n"

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

typedef struct
{
    double latitude;
    double longitude;
    double altitude;
} geocoordinate3D_t;

DLT_DECLARE_CONTEXT(gContext);

bool isRunning=true;

static int g_obd2_fd = -1;
static struct termios g_oldtio;

uint64_t get_timestamp()
{
  struct timespec time_value;
  if (clock_gettime(CLOCK_MONOTONIC, &time_value) != -1)
  {
    return (time_value.tv_sec*1000 + time_value.tv_nsec/1000000);
  }
  else
  {
    return 0xFFFFFFFFFFFFFFFF;
  }
}

bool get_geolocation(char*& sock_buf,char* buffer)
{
    geocoordinate3D_t geolocation;
    char* tmp = new char[BUFLEN];
    char *token;
    uint8_t cnt=0;
    bool retval = false;
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
                LOG_INFO_MSG(gContext,"NMEA DATA NOT VALID\n");
                return retval;
            }
            break;
        case NMEA_RMC_LATITUDE:
            geolocation.latitude=atof(token);
            break;
        case NMEA_RMC_LATITUDE_INDICATOR:
            if(token==NMEA_SOUTH) geolocation.latitude=(-1)*geolocation.latitude;
            break;
        case NMEA_RMC_LONGITUDE:
            geolocation.longitude=atof(token);
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
    LOG_DEBUG(gContext,"Lat: %f Lon: %f Alt: %f\n",geolocation.latitude,geolocation.longitude,geolocation.altitude);

    //compose frame data: TIMESTAMP,0$GVGNSP,TIMESTAMP,LAT,LON,ALT,0X07
    sprintf(tmp,"%d,%s,%d,%.6f,%.6f,%.6f,0x07",1000,"0$GVGNSP",1000,geolocation.latitude,geolocation.longitude,geolocation.altitude);
    sock_buf=tmp;
    return retval;
}

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
    char msgId[MSGIDLEN];
    char * ipaddr = 0;

    // OBD and GNSS devices
    bool result;
    uint64_t start, stop;
    char* answer;
    size_t answer_length;
    char * modem_device_obd2 = 0;
    char * modem_device_gnss = 0;
    char* gnssprefix = (char*)GNS_PREFIX;
    char* snsprefix = (char*)SNS_PREFIX;
    char* vehprefix = (char*)VEH_PREFIX;
    char gnss_buf[MAX_GNSS_BUFFER_SIZE];

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
        if(argc < 4)
            ipaddr = (char*)IPADDR_DEFAULT;
        else
            ipaddr = argv[3];
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
      LOG_INFO(gContext,"INIT OBD2 OK [DURATION = %" PRIu64 " ms]\n", stop-start);
    }
    else
    {
      LOG_DEBUG(gContext,"INIT OBD2 FAILURE [DURATION = %" PRIu64 " ms]\n", stop-start);
      LOG_DEBUG(gContext,"Do you have access rights to %s ?\n", modem_device_obd2);
      return(-1);
    }

    gnssDataReady=false; //set the flag to false (no need of semaphore now because thread is not started yet)
    start = get_timestamp();
    result = gnss_init(modem_device_gnss, BAUDRATE_GNSS);
    stop = get_timestamp();
    if (result)
    {
      LOG_INFO(gContext,"INIT GNSS OK [DURATION = %" PRIu64 " ms]\n", stop-start);
    }
    else
    {
      LOG_DEBUG(gContext,"INIT GNSS FAILURE [DURATION = %" PRIu64 " ms]\n", stop-start);
      LOG_DEBUG(gContext,"Do you have access rights to %s ?\n", modem_device_gnss);
      return(-1);
    }

    // reset the OBD2 device
    if (obd2_send_command(ELM_RESET_ALL)){
        answer=NULL;
        if(obd2_read_answer(answer,&answer_length)!=true){
            LOG_ERROR_MSG(gContext,"RESET OBD2 FAILURE\n");
            return(-1);
        }
    }else{
        LOG_ERROR_MSG(gContext,"RESET OBD2 FAILURE\n");
        return(-1);
    }

    //config the GNSS device to send given frames (TBD)

    bool snsDataReady=false;
    bool vehDataReady=false;
    //main loop
    do{
        if (obd2_send_command(ELM_GET_ID)!=true){
            LOG_DEBUG(gContext,"WRITE OBD2 FAILURE ON COMMAND: %s\n",ELM_GET_ID);
            isRunning=false;
        }

        //GNSS: list of supported message IDs
        //char* gnssstr = "GVGNSP,GVGNSC,GVGNSAC,GVGNSSAT";
        pthread_mutex_lock(&mutex_gnss);       /* down semaphore */
        if(gnssDataReady)
        {
            gnssDataReady=false;
            strcpy(gnss_buf,gnssBuffer); //get the gnss buffer (end of string is added in gnss code)
            pthread_mutex_unlock(&mutex_gnss);       /* up semaphore */
            if(get_geolocation(sock_buf,gnss_buf))
            {
                LOG_DEBUG(gContext,"Sending Packet to %s:%d\n",ipaddr,PORT1);
                LOG_DEBUG(gContext,"MsgID:%s\n", gnssprefix);
                LOG_DEBUG(gContext,"Len:%d\n", (int)strlen(sock_buf));
                LOG_DEBUG(gContext,"Data:%s\n", sock_buf);

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
        if(snsDataReady)
        {
            snsDataReady=false;
            LOG_DEBUG(gContext,"Sending Packet to %s:%d",ipaddr,PORT2);
            LOG_DEBUG(gContext,"MsgID:%s", msgId);
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
        if(vehDataReady)
        {
            vehDataReady=false;
            LOG_DEBUG(gContext,"Sending Packet to %s:%d",ipaddr,PORT3);
            LOG_DEBUG(gContext,"MsgID:%s", msgId);
            LOG_DEBUG(gContext,"Len:%d", (int)strlen(sock_buf));
            LOG_DEBUG(gContext,"Data:%s", sock_buf);

            si_other.sin_port = htons(PORT3);
            if(sendto(sock, sock_buf, strlen(sock_buf)+1, 0, (struct sockaddr *)&si_other, slen) == -1)
            {
                LOG_ERROR_MSG(gContext,"sendto() failed!");
                return EXIT_FAILURE;
            }
        }

        sleep(1);
    } while(isRunning);

    LOG_INFO_MSG(gContext,"Shutting down Vehicle gateway...");

    gnss_destroy();

    /* restore the old port settings */
    tcsetattr(g_obd2_fd,TCSANOW,&g_oldtio);

    close(sock);

    return EXIT_SUCCESS;
}


