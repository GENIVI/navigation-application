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
* and comes from the positioning project <https://github.com/GENIVI/positioning>
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

//#include <sys/timeb.h>

#include <gnss.h>
#include <hnmea.h>
#include <common.h>

const char* ACTIVATE_GST = "$PUBX,40,GST,0,0,0,1,0,0*5A\r\n";
const char* ACTIVATE_GRS = "$PUBX,40,GRS,0,0,0,1,0,0*5C\r\n";

static int g_gnss_fd = -1;
static struct termios g_oldtio;
static char* g_gnss_device;
static unsigned int g_baudrate;

pthread_t g_thread_gnss;
pthread_mutex_t mutex_gnss;
char gnssBuffer[MAX_GNSS_BUFFER_SIZE];
uint64_t gnssTimestamp;
bool gnssDataReady;

/** Flag to terminate NMEA reader thread */
volatile int g_gnss_loop=1;

/** Maximum number of retries to re-open GNSS_DEVICE when select() returns an error */
#define OPEN_RETRY_MAX 15
/** Delay between retries in seconds */
#define OPEN_RETRY_DELAY 2

int gnss_open_device(char* gnss_device, unsigned int baudrate)
{
  int fd;
  struct termios newtio;

    /*
      Open modem device for reading and writing and not as controlling tty
      because we don't want to get killed if linenoise sends CTRL-C.
    */
    fd = open(gnss_device, O_RDWR | O_NOCTTY );
    if (fd <0) {perror(gnss_device); return (-1); }

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
    newtio.c_lflag = ICANON;
 
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

void* loop_gnss_device(void* dev)
{
    int* p_fd = (int*)dev;
    int fd = *p_fd;
    fd_set readfs;    /* file descriptor set */
    int    maxfd;     /* maximum file descriptor used */
    int linecount=0;
    char buf[MAX_GNSS_BUFFER_SIZE];
    //read failure - used to trigger restart
    bool read_failure = false;
    //trigger message
    NMEA_RESULT trigger = NMEA_RMC;
    //gnss data as returned by NMEA parser
    GNS_DATA gns_data;
    HNMEA_Init_GNS_DATA(&gns_data);

    /* loop until we have a terminating condition */
    //LOG_DEBUG(gContext, "entering NMEA reading loop %d\n", fd);
    while (g_gnss_loop)
    {     
        int res;
        struct timeval timeout;
        /* set timeout value within input loop */
        timeout.tv_usec = 0;  /* milliseconds */
        timeout.tv_sec  = 2;  /* seconds */
        FD_SET(fd, &readfs);
        maxfd = fd+1;

        /* block until input becomes available */
        res = select(maxfd, &readfs, NULL, NULL, &timeout);
        if (res==-1)
        {
            read_failure = true;
        }
        else if (res==0)
        {
            //LOG_DEBUG_MSG(gContext, "TIMEOUT\n");
        } 
        else if (FD_ISSET(fd, &readfs))
        {
            res = read(fd,buf,MAX_GNSS_BUFFER_SIZE);
            if (res == 0)
            {
                read_failure = true;
            }
            buf[res]=0;             /* set end of string, so we can printf */
            linecount++;
            //LOG_DEBUG(gContext, "%d:%s", linecount, buf);
            NMEA_RESULT nmea_res = HNMEA_Parse(buf, &gns_data);

            //most receivers sent GPRMC as last, but u-blox send as first: use other trigger
            //determine most suitable trigger on actually received messages
            if (nmea_res == NMEA_RMC)  //highest precedence
            {
                pthread_mutex_lock(&mutex_gnss);       /* down semaphore */
                strncpy(gnssBuffer,buf,res);
                gnssTimestamp=get_timestamp();
                gnssDataReady=true;
                pthread_mutex_unlock(&mutex_gnss);       /* up semaphore */
            }
        }
        if(read_failure)
        {
            //Error - try to restart device connection
            close(fd);
            fd = -1;
            int device_open_retries = 0;
            while ((device_open_retries < OPEN_RETRY_MAX) && (fd < 0))
            {
                device_open_retries++;
                sleep(OPEN_RETRY_DELAY);
                fd = gnss_open_device(g_gnss_device, g_baudrate);
            }
            if (fd >=0)
            {
                read_failure = false;
            }
            else
            {
                //reopen failed: terminate thread
                g_gnss_loop = 0;
            }
        }
    }
    close(fd);
    return NULL;
}

bool gnss_send_command(const char* cmd)
{
    if (write(g_gnss_fd,cmd,sizeof(cmd)-1))
        return true;
    else
        return false;
}

bool gnss_init(const char* gnss_device, unsigned int baudrate)
{
    bool retval = false;
    g_gnss_device = (char*)gnss_device;
    g_baudrate = baudrate;
    g_gnss_fd = gnss_open_device((char*)gnss_device, baudrate);
    if (g_gnss_fd >= 0)
    {
        if(gnss_send_command(ACTIVATE_GST))
            if(gnss_send_command(ACTIVATE_GRS)){
                pthread_create(&g_thread_gnss, NULL, loop_gnss_device, &g_gnss_fd);
                retval = true;
            }
    }

    return retval;
}

bool gnss_destroy()
{
    g_gnss_loop = 0;
    pthread_join(g_thread_gnss, NULL);

    return true;
}
