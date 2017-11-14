/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2017, PSA GROUP
*
* \file obd2.c
*
* \brief This file is part of the FSA project.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \version 0.1
*
*
* @ref http://tldp.org/HOWTO/Serial-Programming-HOWTO/x115.html
*
* Part of this code has been inspired by Helmut Schmidt <https://github.com/huirad>
*
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
* <date>, <name>, <description of change>
*
* @licence end@
*/

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <inttypes.h>

#include <obd2.h>
#include <common.h>
#include <can.h>

/* baudrate settings are defined in <asm/termbits.h>, which is
included by <termios.h> */

#define OBD_GET_PID_LIST "0100\r\n"

#define OBD_HEADER_LENGTH 5 //41 0C for instance

#define OBD_FUEL_LEVEL_PID "012F\r\n"
#define OBD_FUEL_LEVEL_MESSAGE_HEADER "41 2F"
#define OBD_FUEL_LEVEL_MESSAGE_DATA_LENGTH 1
#define OBD_FUEL_LEVEL_MESSAGE_LENGTH OBD_HEADER_LENGTH+3*OBD_FUEL_LEVEL_MESSAGE_DATA_LENGTH //41 2F 00

#define OBD_RPM_PID "010C\r\n"
#define OBD_RPM_MESSAGE_HEADER "41 0C"
#define OBD_RPM_MESSAGE_DATA_LENGTH 2
#define OBD_RPM_MESSAGE_LENGTH OBD_HEADER_LENGTH+3*OBD_RPM_MESSAGE_DATA_LENGTH //41 0C 00 00

#define OBD_VEH_SPEED_PID "010D\r\n"

#define ELM_RESET_ALL "AT Z\r\n"
#define ELM_ECHO_OFF "AT E0\r\n"
#define ELM_GET_ID "AT I\r\n"
#define ELM_PROMPT '>'
#define ELM_READ_LOOP 5000 //5 ms
#define ELM_READ_TIMEOUT 100000 //100 ms
#define ELM_HEADER_ON "AT H1\r\n"
#define ELM_CAN_FORMAT_OFF "AT CAF0\r\n"
#define ELM_MONITOR_ALL "AT MA\r\n"
#define ELM_SET_PROTOCOL "AT SP"
#define ELM_SET_PROTOCOL_LENGTH 10
#define ELM_SET_CAN_ID_MASK "AT CM"
#define ELM_SET_CAN_ID_MASK_LENGTH 12
#define ELM_SET_CAN_ID_FILTER "AT CF"
#define ELM_SET_CAN_ID_FILTER_LENGTH 12
#define ELM_LINEFEEDS_ON "AT L1\r\n"
#define ELM_PRINTING_SPACES_OFF "AT S0\r\n"
#define ELM_ALLOW_LONG_MESSAGES "AT AL\r\n"
#define ELM_DISPLAY_DLC_ON "AT D1\r\n"

#define BUFFER_MAX_LENGTH 512


static int g_obd2_fd = -1;
static struct termios g_oldtio;

int obd2_open_device(char* obd2_device, unsigned int baudrate)
{
    int fd;
    struct termios newtio;
  /*
    Open modem device for reading and writing and not as controlling tty
    because we don't want to get killed if linenoise sends CTRL-C.
  */
   fd = open(obd2_device, O_RDWR | O_NOCTTY );
   if (fd <0) {perror(obd2_device); return (-1); }

   tcgetattr(fd,&g_oldtio); /* save current serial port settings */
   bzero(&newtio, sizeof(newtio)); /* clear struct for new port settings */

  /*
    BAUDRATE: Set bps rate. You could also use cfsetispeed and cfsetospeed.
    CRTSCTS : output hardware flow control (only used if the cable has
              all necessary lines. See sect. 7 of Serial-HOWTO)
    CS8     : 8n1 (8bit,no parity,1 stopbit)
    CLOCAL  : local connection, no modem contol
    CREAD   : enable receiving characters
  */
   newtio.c_cflag = baudrate | CS8 | CLOCAL | CREAD;

  /*
    IGNPAR  : ignore bytes with parity errors
    ICRNL   : map CR to NL (otherwise a CR input on the other computer
              will not terminate input)
    otherwise make device raw (no other input processing)
  */
   newtio.c_iflag = IGNPAR;

  /*
   Raw output.
  */
   newtio.c_oflag = 0;

  /*
    ICANON  : enable canonical input
    disable all echo functionality, and don't send signals to calling program
  */
   newtio.c_lflag = ISIG;

  /*
    initialize all control characters
    default values can be found in /usr/include/termios.h, and are given
    in the comments, but we don't need them here
  */
   newtio.c_cc[VINTR]    = 0;     /* Ctrl-c */
   newtio.c_cc[VQUIT]    = 0;     /* Ctrl-\ */
   newtio.c_cc[VERASE]   = 0;     /* del */
   newtio.c_cc[VKILL]    = 0;     /* @ */
   newtio.c_cc[VEOF]     = 4;     /* Ctrl-d */
   newtio.c_cc[VTIME]    = 0;     /* inter-character timer unused */
   newtio.c_cc[VMIN]     = 0;     /* non blocking read */
   newtio.c_cc[VSWTC]    = 0;     /* '\0' */
   newtio.c_cc[VSTART]   = 0;     /* Ctrl-q */
   newtio.c_cc[VSTOP]    = 0;     /* Ctrl-s */
   newtio.c_cc[VSUSP]    = 0;     /* Ctrl-z */
   newtio.c_cc[VEOL]     = 0;     /* '\0' */
   newtio.c_cc[VREPRINT] = 0;     /* Ctrl-r */
   newtio.c_cc[VDISCARD] = 0;     /* Ctrl-u */
   newtio.c_cc[VWERASE]  = 0;     /* Ctrl-w */
   newtio.c_cc[VLNEXT]   = 0;     /* Ctrl-v */
   newtio.c_cc[VEOL2]    = 0;     /* '\0' */

  /*
    now clean the modem line and activate the settings for the port
  */
   tcflush(fd, TCIFLUSH);
   tcsetattr(fd,TCSANOW,&newtio);

   return fd;
}

bool obd2_read(char*& data,size_t& length,uint64_t& timestamp)
{ //data is allocated dynamically
    bool isRead=false;
    bool isBufferOverflow=false;
    char buf=EOS;
    ssize_t read_result;
    size_t buf_length=0;
    useconds_t timeout=0;
    char* tmp = new char[BUFFER_MAX_LENGTH];
    do{
        read_result=read(g_obd2_fd,&buf,1);
        if(read_result==(-1))
            isRead=false;
        else{
            if(read_result>0)
            {
                timeout=0; //data received so reset the time out
                if(buf_length>BUFFER_MAX_LENGTH)
                {
                    printf("%s\n","buffer overflow");
                    isBufferOverflow=true;
                    delete tmp; //free the buffer
                    break;
                }else{
                    if(buf==ELM_PROMPT){
                        isRead=true;
                        *(tmp+buf_length)=buf;
                        data = tmp; //copy the pointer, so it'll be freed into the caller
                        length=buf_length;
                    }
                    else{
                        if(buf==CR)
                            buf=SPACE;
                        *(tmp+buf_length)=buf; //push back char
                    }
                    buf_length++;
                }
            }
        }
        usleep(ELM_READ_LOOP);
        timeout+=ELM_READ_LOOP;
    }while((isRead==false)&&(timeout<ELM_READ_TIMEOUT)&&(isBufferOverflow==false));

    timestamp=get_timestamp();
    return isRead;
}

bool obd2_send_command(const char* cmd)
{
    if (write(g_obd2_fd,cmd,strlen(cmd)))
        return true;
    else
        return false;
}

bool obd2_command(const char* cmd, uint64_t& timestamp)
{
    char* answer;
    size_t answer_length;
    if (obd2_send_command(cmd)){
        answer=NULL;
        if(obd2_read(answer,answer_length,timestamp)!=true){
            return false;
        }else{
            delete answer;
        }
    }else{
        return false;
    }
    return true;
}

bool obd2_init(char* obd2_device, unsigned int baudrate)
{
    bool retval = false;

    g_obd2_fd = obd2_open_device(obd2_device, baudrate);
    if (g_obd2_fd >= 0)
    {
      retval = true;
    }

    return retval;
}

bool obd2_reset(uint64_t& timestamp)
{
    char* answer;
    size_t answer_length;
    if (obd2_send_command(ELM_RESET_ALL)){
        answer=NULL;
        if(obd2_read(answer,answer_length,timestamp)!=true){
            return false;
        }else{
            delete answer;
        }
    }else{
        return false;
    }
    return true;
}

bool obd2_config(uint64_t& timestamp)
{
    char* answer;
    size_t answer_length;
    if (obd2_send_command(ELM_ECHO_OFF)){
        answer=NULL;
        if(obd2_read(answer,answer_length,timestamp)!=true){
            return false;
        }else{
            delete answer;
        }
    }else{
        return false;
    }
    if (obd2_send_command(OBD_GET_PID_LIST)){
        answer=NULL;
        if(obd2_read(answer,answer_length,timestamp)!=true){
            return false;
        }else{
            delete answer;
        }
    }else{
        return false;
    }
    return true;
}

bool obd2_read_engine_rpm(uint16_t& rpm,uint64_t& timestamp)
{
    //`010C` Engine RPM: returns 2 bytes (A,B): RPM [1/min] = ((A*256)+B)/4
    char* answer;
    char header[OBD_HEADER_LENGTH+1];
    char value[OBD_RPM_MESSAGE_DATA_LENGTH*2+1];
    size_t answer_length;
    if (obd2_send_command(OBD_RPM_PID)){
        answer=NULL;
        if(obd2_read(answer,answer_length,timestamp)!=true){
            return false;
        }
    }else{
        return false;
    }
    if(answer_length!=OBD_RPM_MESSAGE_LENGTH){
        delete answer;
        return false;
    }else{
        strncpy(header,answer,OBD_HEADER_LENGTH);
        header[OBD_HEADER_LENGTH]=EOS;
        if(strcmp(header,OBD_RPM_MESSAGE_HEADER)!=0){
            delete answer;
            return false;
        }else{
            value[0]=answer[OBD_HEADER_LENGTH+1];
            value[1]=answer[OBD_HEADER_LENGTH+2];
            value[2]=answer[OBD_HEADER_LENGTH+4];
            value[3]=answer[OBD_HEADER_LENGTH+5];
            value[4]=EOS;
            rpm=atoi(value)/4;
            delete answer;
        }
    }
    return true;
}

bool obd2_read_fuel_level(uint8_t& level,uint64_t& timestamp)
{
    //`012F` Fuel Tank Level Input: returns 1 byte: level in %
    char* answer;
    char header[OBD_HEADER_LENGTH+1];
    char value[OBD_FUEL_LEVEL_MESSAGE_DATA_LENGTH*2+1];
    size_t answer_length;
    if (obd2_send_command(OBD_FUEL_LEVEL_PID)){
        answer=NULL;
        if(obd2_read(answer,answer_length,timestamp)!=true){
            return false;
        }
    }else{
        return false;
    }
    if(answer_length!=OBD_FUEL_LEVEL_MESSAGE_LENGTH){
        delete answer;
        return false;
    }else{
        strncpy(header,answer,OBD_HEADER_LENGTH);
        header[OBD_HEADER_LENGTH]=EOS;
        if(strcmp(header,OBD_FUEL_LEVEL_MESSAGE_HEADER)!=0){
            delete answer;
            return false;
        }else{
            value[0]=answer[OBD_HEADER_LENGTH+1];
            value[1]=answer[OBD_HEADER_LENGTH+2];
            value[3]=EOS;
            level=atoi(value);
            delete answer;
        }
    }
    return true;
}

bool obd2_config_can_reader(uint64_t& timestamp)
{
    char filterBuffer[ELM_SET_CAN_ID_FILTER_LENGTH];
    char maskBuffer[ELM_SET_CAN_ID_MASK_LENGTH];
    char protocolBuffer[ELM_SET_PROTOCOL_LENGTH];

    sprintf(filterBuffer,ELM_SET_CAN_ID_FILTER " %s" CR_LF,CAN_MESSAGE_FILTER);
    sprintf(maskBuffer,ELM_SET_CAN_ID_MASK " %s" CR_LF,CAN_MESSAGE_MASK);
    sprintf(protocolBuffer,ELM_SET_PROTOCOL " %d" CR_LF,CAN_PROTOCOL_11_BIT_ID_500KBITS);

    if(!obd2_command(ELM_GET_ID,timestamp))
        return false;
    if(!obd2_command(ELM_LINEFEEDS_ON,timestamp))
        return false;
    if(!obd2_command(ELM_HEADER_ON,timestamp))
        return false;
    if(!obd2_command(ELM_PRINTING_SPACES_OFF,timestamp))
        return false;
    if(!obd2_command(ELM_ALLOW_LONG_MESSAGES,timestamp))
        return false;
    if(!obd2_command(protocolBuffer,timestamp))
        return false;
    if(!obd2_command(ELM_DISPLAY_DLC_ON,timestamp))
        return false;
    if(!obd2_command(ELM_CAN_FORMAT_OFF,timestamp))
        return false;
    if(!obd2_command(maskBuffer,timestamp))
        return false;
    if(!obd2_command(filterBuffer,timestamp))
        return false;
    if(!obd2_send_command(ELM_MONITOR_ALL))
        return false;
    return true;
}

can_message_id_t can_read(char*& data,uint64_t& timestamp)
{
    bool isRead=false;
    bool isBufferOverflow=false;
    can_message_id_t ret=NO_MESSAGE;
    char buf=EOS;
    ssize_t read_result;
    size_t buf_length=0;
    useconds_t timeout=0;
    char* tmp = new char[BUFFER_MAX_LENGTH];
    do{
        read_result=read(g_obd2_fd,&buf,1);
        if(read_result==(-1))
            isRead=false;
        else{
            if(read_result>0)
            {
                timeout=0; //data received so reset the time out
                if(buf_length>BUFFER_MAX_LENGTH)
                {
                    printf("%s\n","buffer overflow");
                    isBufferOverflow=true;
                    delete tmp; //free the buffer
                    break;
                }else{
                    if(buf==LF){
                        isRead=true;
                        *(tmp+buf_length)=EOS;
                        timestamp=get_timestamp();
                        // analyze content now
                        if (strncmp(tmp,CAN_MESSAGE_ENGINE_SPEED_ID_AND_DATA_SIZE,CAN_ID_AND_DATA_SIZE_LENGTH)==0)
                        {
                            data=tmp; //copy the pointer, so it'll be freed into the caller
                            ret=MESSAGE_ENGINE_SPEED;
                        }else{
                            if (strncmp(tmp,CAN_MESSAGE_FUEL_LEVEL_ID_AND_DATA_SIZE,CAN_ID_AND_DATA_SIZE_LENGTH)==0)
                            {
                                data=tmp; //copy the pointer, so it'll be freed into the caller
                                ret=MESSAGE_FUEL_LEVEL;
                            }else{
                                if (strncmp(tmp,CAN_MESSAGE_WHEEL_TICK_ID_AND_DATA_SIZE,CAN_ID_AND_DATA_SIZE_LENGTH)==0)
                                {
                                    data=tmp; //copy the pointer, so it'll be freed into the caller
                                    ret=MESSAGE_WHEEL_TICK;
                                }else{
                                    delete tmp; //free the buffer
                                }
                            }
                        }
                    }else{
                        *(tmp+buf_length)=buf; //push back char
                    }
                    buf_length++;
                }
            }
        }
        usleep(ELM_READ_LOOP);
        timeout+=ELM_READ_LOOP;
    }while((isRead==false)&&(timeout<ELM_READ_TIMEOUT)&&(isBufferOverflow==false));
    return ret;
}

