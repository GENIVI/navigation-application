/**************************************************************************
* @licence app begin@
*
* SPDX-License-Identifier: MPL-2.0
*
* \ingroup SensorsService
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

#include "sns-init.h"
#include "acceleration.h"
#include "gyroscope.h"
#include "inclination.h"
#include "odometer.h"
#include "reverse-gear.h"
#include "slip-angle.h"
#include "steering-angle.h"
#include "vehicle-data.h"
#include "vehicle-speed.h"
#include "vehicle-state.h"
#include "wheel.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <time.h>
#include <errno.h>
#include <pthread.h>
#include <assert.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <memory.h>

#include "globals.h"
#include "log.h"

#define STRINGIFY2( x) #x
#define STRINGIFY(x) STRINGIFY2(x)

#define BUFLEN 256
#define MSGIDLEN 20
#define PORT 9931

#define MAX_BUF_MSG 16

DLT_DECLARE_CONTEXT(gContext);

//Listener thread
static pthread_t listenerThread;
//Listener thread loop control variale
static volatile bool isRunning = false;
//Socket file descriptor used by listener thread. 
//Global so we can shutdown() it to release listener thread immediately from waiting 
static int s = 0;
//Note: we do not mutex-protect the above globals because for this proof-of-concept 
//implementation we expect that the client does not ake overlapping calls.
//For a real-world fool-proof implementation you would have to add more checks.


static void *listenForMessages( void *ptr );

bool snsInit()
{
    isRunning = true;

    if(pthread_create( &listenerThread, NULL, listenForMessages, NULL) != 0)
    {
        isRunning = false;
        return false;
    }

    return true;
}

bool snsDestroy()
{
    isRunning = false;

    //shut down the socket
    shutdown(s,2);

    if(listenerThread)
    {
        pthread_join( listenerThread, NULL);
    }

    return true;
}

void snsGetVersion(int *major, int *minor, int *micro)
{
    if(major)
    {
        *major = GENIVI_SNS_API_MAJOR;
    }

    if(minor)
    {
        *minor = GENIVI_SNS_API_MINOR;
    }

    if(micro)
    {
        *micro = GENIVI_SNS_API_MICRO;
    }
}

bool snsAccelerationInit()
{
    return iAccelerationInit();
}

bool snsAccelerationDestroy()
{
    return iAccelerationDestroy();
}

bool snsGyroscopeInit()
{
    return iGyroscopeInit();
}

bool snsGyroscopeDestroy()
{
    return iGyroscopeDestroy();
}

bool snsVehicleSpeedInit()
{
    return iVehicleSpeedInit();
}

bool snsVehicleSpeedDestroy()
{
    return iVehicleSpeedDestroy();
}

bool snsWheelInit()
{
    return iWheelInit();
}

bool snsWheelDestroy()
{
    return iWheelDestroy();
}

bool snsVehicleDataInit()
{
    return iVehicleDataInit();
}

bool snsVehicleDataDestroy()
{
    return iVehicleDataDestroy();
}

bool processGVSNSWHE(const char* data)
{
    //parse data like: 15259,0,$GVSNSWHE,15200,35,45,0,0,0,0,0,0,0X0001,100,0X03
    
    //storage for buffered data
    static TWheelData buf_whtk[MAX_BUF_MSG];
    static uint16_t buf_size = 0;
    static uint16_t last_countdown = 0;    

    uint64_t timestamp;
    uint16_t countdown;
    TWheelData whtk = { 0 };
    int n = 0;

    if(!data)
    {
        LOG_ERROR_MSG(gContext,"wrong parameter!");
        return false;
    }

    //First try to read in new format with measurementInterval
    n = sscanf(data, "%llu,%hu,$GVSNSWHE,%llu,%f,%f,%f,%f,%f,%f,%f,%f,%x,%u,%x", 
        &timestamp, &countdown, &whtk.timestamp
        ,&whtk.data[0], &whtk.data[1]
        ,&whtk.data[2], &whtk.data[3]
        ,&whtk.data[4], &whtk.data[5]
        ,&whtk.data[6], &whtk.data[7]
        ,&whtk.statusBits
        ,&whtk.measurementInterval
        ,&whtk.validityBits
        );

    if (n != 14) //14 fields to parse
    {
        //Else try to read in old format without measurementInterval
        n = sscanf(data, "%llu,%hu,$GVSNSWHE,%llu,%f,%f,%f,%f,%f,%f,%f,%f,%x,%x", 
            &timestamp, &countdown, &whtk.timestamp
            ,&whtk.data[0], &whtk.data[1]
            ,&whtk.data[2], &whtk.data[3]
            ,&whtk.data[4], &whtk.data[5]
            ,&whtk.data[6], &whtk.data[7]
            ,&whtk.statusBits
            ,&whtk.validityBits
            );

        if (n != 13) //13 fields to parse
        {
            LOG_ERROR_MSG(gContext,"replayer: processGVSNSWHE failed!");
            return false;
        }
    }

    //buffered data handling
    if (countdown < MAX_BUF_MSG) //enough space in buffer?
    {
        if (buf_size == 0) //a new sequence starts
        {
            buf_size = countdown+1;
            last_countdown = countdown;
            buf_whtk[buf_size-countdown-1] = whtk;
        }
        else if ((last_countdown-countdown) == 1) //sequence continued
        {
            last_countdown = countdown;
            buf_whtk[buf_size-countdown-1] = whtk;
        }
        else //sequence interrupted: clear buffer
        {
            buf_size = 0;
            last_countdown = 0;
        }
    }
    else //clear buffer
    {
        buf_size = 0;
        last_countdown = 0;
    }

    if((countdown == 0) && (buf_size >0) )
    {
        updateWheelData(buf_whtk, buf_size);
        buf_size = 0;
        last_countdown = 0;        
    }

    return true;
}

static bool processGVSNSGYR(const char* data)
{
    //parse data like: 061074000,0$GVSNSGYR,061074000,-38.75,0,0,0,0X01
    
    //storage for buffered data
    static TGyroscopeData buf_gyro[MAX_BUF_MSG];
    static uint16_t buf_size = 0;
    static uint16_t last_countdown = 0;    

    uint64_t timestamp;
    uint16_t countdown;
    TGyroscopeData gyro = { 0 };
    int n = 0;

    if(!data )
    {
        LOG_ERROR_MSG(gContext,"wrong parameter!");
        return false;
    }

    //First try to read in new format with measurementInterval
    n = sscanf(data, "%llu,%hu,$GVSNSGYR,%llu,%f,%f,%f,%f,%u,%x"
        ,&timestamp, &countdown, &gyro.timestamp
        ,&gyro.yawRate
        ,&gyro.pitchRate
        ,&gyro.rollRate
        ,&gyro.temperature
        ,&gyro.measurementInterval        
        ,&gyro.validityBits
        );
    if (n != 9) //9 fields to parse
    {
        //Else try to read in old format without measurementInterval
        n = sscanf(data, "%llu,%hu,$GVSNSGYR,%llu,%f,%f,%f,%f,%x"
            ,&timestamp, &countdown, &gyro.timestamp
            ,&gyro.yawRate
            ,&gyro.pitchRate
            ,&gyro.rollRate
            ,&gyro.temperature
            ,&gyro.validityBits
            );
        
        if (n != 8) //8 fields to parse
        {
                LOG_ERROR_MSG(gContext,"replayer: processGVSNSGYR failed!");
                return false;
        }
    }

    //buffered data handling
    if (countdown < MAX_BUF_MSG) //enough space in buffer?
    {
        if (buf_size == 0) //a new sequence starts
        {
            buf_size = countdown+1;
            last_countdown = countdown;
            buf_gyro[buf_size-countdown-1] = gyro;
        }
        else if ((last_countdown-countdown) == 1) //sequence continued
        {
            last_countdown = countdown;
            buf_gyro[buf_size-countdown-1] = gyro;
        }
        else //sequence interrupted: clear buffer
        {
            buf_size = 0;
            last_countdown = 0;
        }
    }
    else //clear buffer
    {
        buf_size = 0;
        last_countdown = 0;
    }

    if((countdown == 0) && (buf_size >0) )
    {
        updateGyroscopeData(buf_gyro,buf_size);
        buf_size = 0;
        last_countdown = 0;        
    }

    return true;
}



static bool processGVSNSVSP(const char* data)
{
    //parse data like: 061074000,0$GVSNSVSP,061074000,0.51,0X01
    
    //storage for buffered data
    static TVehicleSpeedData buf_vehsp[MAX_BUF_MSG];
    static uint16_t buf_size = 0;
    static uint16_t last_countdown = 0;    

    uint64_t timestamp;
    uint16_t countdown;
    TVehicleSpeedData vehsp = { 0 };
    int n = 0;

    if(!data)
    {
        LOG_ERROR_MSG(gContext,"wrong parameter!");
        return false;
    }

    //First try to read in new format with measurementInterval
    n = sscanf(data, "%llu,%hu,$GVSNSVSP,%llu,%f,%u,%x"
        ,&timestamp
        ,&countdown
        ,&vehsp.timestamp
        ,&vehsp.vehicleSpeed
        ,&vehsp.measurementInterval
        ,&vehsp.validityBits
        );    

    if (n != 6) //6 fields to parse
    {
        //Else try to read in old format without measurementInterval
    n = sscanf(data, "%llu,%hu,$GVSNSVSP,%llu,%f,%x"
        ,&timestamp
        ,&countdown
        ,&vehsp.timestamp
        ,&vehsp.vehicleSpeed
        ,&vehsp.validityBits
        );    

        if (n != 5) //5 fields to parse
        {
            LOG_ERROR_MSG(gContext,"replayer: processGVSNSVSP failed!");
            return false;
        }
    }

    //buffered data handling
    if (countdown < MAX_BUF_MSG) //enough space in buffer?
    {
        if (buf_size == 0) //a new sequence starts
        {
            buf_size = countdown+1;
            last_countdown = countdown;
            buf_vehsp[buf_size-countdown-1] = vehsp;
        }
        else if ((last_countdown-countdown) == 1) //sequence continued
        {
            last_countdown = countdown;
            buf_vehsp[buf_size-countdown-1] = vehsp;
        }
        else //sequence interrupted: clear buffer
        {
            buf_size = 0;
            last_countdown = 0;
        }
    }
    else //clear buffer
    {
        buf_size = 0;
        last_countdown = 0;
    }

    if((countdown == 0) && (buf_size >0) )
    {
        updateVehicleSpeedData(buf_vehsp,buf_size);
        buf_size = 0;
        last_countdown = 0;        
    }

    return true;
}

static void *listenForMessages( void *ptr )
{  
    struct sockaddr_in si_me;
    struct sockaddr_in si_other;
    socklen_t slen = sizeof(si_other);
    ssize_t readBytes = 0;
    char buf[BUFLEN+1]; //add space fer terminating \0
    char msgId[MSGIDLEN+1]; //add space fer terminating \0
    int port = PORT;

    DLT_REGISTER_APP("SNSS", "SENSOSRS-SERVICE");
    DLT_REGISTER_CONTEXT(gContext,"SSRV", "Global Context");

    LOG_INFO(gContext,"SensorsService listening on port %d...",port);

    if((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1)
    {
        LOG_ERROR_MSG(gContext,"socket() failed!");
        exit(EXIT_FAILURE);
    }

    memset((char *) &si_me, 0, sizeof(si_me));
    si_me.sin_family = AF_INET;

    si_me.sin_port = htons(port);
    si_me.sin_addr.s_addr = htonl(INADDR_ANY);
    if(bind(s, (struct sockaddr *)&si_me, sizeof(si_me)) == -1)
    {
        LOG_ERROR_MSG(gContext,"socket() failed!");
        exit(EXIT_FAILURE);
    }

    while(isRunning == true)
    {
        //use select to introduce a timeout - alloy shutdown even when no data are received
        fd_set readfs;    /* file descriptor set */
        int    maxfd;     /* maximum file desciptor used */        
        int res;
        struct timeval Timeout;
        /* set timeout value within input loop */
        Timeout.tv_usec = 0;  /* milliseconds */
        Timeout.tv_sec  = 1;  /* seconds */
        FD_SET(s, &readfs);
        maxfd = s+1;
        /* block until input becomes available */
        res = select(maxfd, &readfs, NULL, NULL, &Timeout);

        if (res > 0)
        {
            
            readBytes = recvfrom(s, buf, BUFLEN, 0, (struct sockaddr *)&si_other, &slen);

            if(readBytes < 0)
            {
                LOG_ERROR_MSG(gContext,"recvfrom() failed!");
                exit(EXIT_FAILURE);
            }
            
            buf[readBytes] = '\0';

            sscanf(buf, "%*[^'$']$%" STRINGIFY(MSGIDLEN) "[^',']", msgId);
    
            LOG_DEBUG(gContext,"Data:%s", buf);

            if(strcmp("GVSNSGYR", msgId) == 0)
            {
                processGVSNSGYR(buf);
            }
            else if(strcmp("GVSNSWHE", msgId) == 0)
            {
                processGVSNSWHE(buf);
            }
            else if(strcmp("GVSNSVSP", msgId) == 0)
            {
                processGVSNSVSP(buf);
            }
        }
    }

    close(s);

    return EXIT_SUCCESS;
}




