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
#include <string.h>
#include <time.h>
#include <inttypes.h>

#include <obd2.h>

/* baudrate settings are defined in <asm/termbits.h>, which is
included by <termios.h> */

#define OBD_PID_FUEL_TANK 0x012F
#define OBD_PID_RPM 0x010C
#define OBD_PID_VEH_SPEED 0x010D

#define ELM_RESET_ALL "AT Z\r\n"
#define ELM_GET_ID "AT I\r\n"
#define ELM_PROMPT '>'
#define ELM_READ_LOOP 5000 //5 ms
#define ELM_READ_TIMEOUT 1000000 //100 ms

#define CR '\r'
#define EOS '\0'
#define SPACE ' '
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
   newtio.c_cc[VMIN]     = 1;     /* blocking read until 1 character arrives */
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

bool obd2_read_answer(char*& ans,size_t* length)
{ //ans is allocated dynamically
    bool isRead=false;
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
                    break;
                }else{
                    if(buf==ELM_PROMPT){
                        isRead=true;
                        *(tmp+buf_length)=buf;
                        ans = tmp;
                        *length=buf_length;
                    }
                    else{
                        if(buf==CR)
                            buf=SPACE;
                        *(tmp+buf_length)=buf;
                    }
                    buf_length++;
                }
            }
        }
        usleep(ELM_READ_LOOP);
        timeout+=ELM_READ_LOOP;
    }while((isRead==false)&&(timeout<ELM_READ_TIMEOUT));

    return isRead;
}

bool obd2_send_command(const char* cmd)
{
    if (write(g_obd2_fd,cmd,sizeof(cmd)-1))
        return true;
    else
        return false;
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



