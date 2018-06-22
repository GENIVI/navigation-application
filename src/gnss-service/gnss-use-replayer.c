/**************************************************************************
* @licence app begin@
*
* SPDX-License-Identifier: MPL-2.0
*
* \ingroup GNSSService
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

#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <time.h>
#include <errno.h>
#include <pthread.h>
#include <assert.h>
#include <math.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <memory.h>

#include "globals.h"
#include "gnss-init.h"
#include "log.h"

#define STRINGIFY2( x) #x
#define STRINGIFY(x) STRINGIFY2(x)

#define BUFLEN 256
#define MSGIDLEN 20
#define PORT 9930

#define MAX_BUF_MSG 16

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

DLT_DECLARE_CONTEXT(gContext);

bool gnssInit()
{
    iGnssInit();
    
    isRunning = true;
    
    if(pthread_create(&listenerThread, NULL, listenForMessages, NULL) != 0)
    {
        isRunning = false;
    	return false;
    }

    return true;
}

bool gnssDestroy()
{
    isRunning = false;
    
    //shut down the socket
    shutdown(s,2);

    if(listenerThread)
    {
        pthread_join(listenerThread, NULL);
    }

    iGnssDestroy();

    return true;
}

void gnssGetVersion(int *major, int *minor, int *micro)
{
    if(major)
    {
        *major = GENIVI_GNSS_API_MAJOR;
    }

    if (minor)
    {
        *minor = GENIVI_GNSS_API_MINOR;
    }

    if (micro)
    {
        *micro = GENIVI_GNSS_API_MICRO;
    }
}

bool gnssSetGNSSSystems(uint32_t activate_systems)
{
    return false; //satellite system configuration request not supported for replay
}


static bool processGVGNSPOS(const char* data)
{
    //parse data like: 555854,0,$GVGNSPOS,555804,49.0437988,12.1011773, 337.8, 383.8,13.3,9999.0,195.85,2.3,1.4,1.9,06,9999,9999, 2.6, 2.5,9999.0,9999.0,9999.0,3,0X00000001,0X00000001,0X00000001,0X003C67DF

    //storage for buffered data
    static TGNSSPosition buf_pos[MAX_BUF_MSG];
    static uint16_t buf_size = 0;
    static uint16_t last_countdown = 0;

    uint64_t timestamp;
    uint16_t countdown;
    TGNSSPosition pos = { 0 };
    int n = 0;

    if(!data)
    {
        LOG_ERROR_MSG(gContext,"wrong parameter!");
        return false;
    }

    n = sscanf(data, 
        "%"SCNu64",%"SCNu16",$GVGNSPOS,%"SCNu64",%lf,%lf,%f,%f,%f,%f,%f,%f,%f,%f,%"SCNu16",%"SCNu16",%"SCNu16",%f,%f,%f,%f,%f,%u,%x,%x,%x,%"SCNu16",%x",
        &timestamp,
        &countdown,
        &pos.timestamp,
        &pos.latitude,
        &pos.longitude,
        &pos.altitudeMSL,
        &pos.altitudeEll,
        &pos.hSpeed,
        &pos.vSpeed,
        &pos.heading,
        &pos.pdop,
        &pos.hdop,
        &pos.vdop,
        &pos.usedSatellites,
        &pos.trackedSatellites,
        &pos.visibleSatellites,
        &pos.sigmaHPosition,
        &pos.sigmaAltitude,
        &pos.sigmaHSpeed,
        &pos.sigmaVSpeed,
        &pos.sigmaHeading,
        &pos.fixStatus,
        &pos.fixTypeBits,
        &pos.activatedSystems,
        &pos.usedSystems,
        &pos.correctionAge,        
        &pos.validityBits
        );

    //buffered data handling
    if (countdown < MAX_BUF_MSG) //enough space in buffer?
    {
        if (buf_size == 0) //a new sequence starts
        {
            buf_size = countdown+1;
            last_countdown = countdown;
            buf_pos[buf_size-countdown-1] = pos;
        }
        else if ((last_countdown-countdown) == 1) //sequence continued
        {
            last_countdown = countdown;
            buf_pos[buf_size-countdown-1] = pos;
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
        updateGNSSPosition(buf_pos,buf_size);
        buf_size = 0;
        last_countdown = 0;
    }

    return true;
}

static bool processGVGNSTIM(const char* data)
{
    //parse data like: 555854,0,$GVGNSTIM,555804,2016,01,23,20,49,00,000,00,0,0X00000003

    //storage for buffered data
    static TGNSSTime buf_tim[MAX_BUF_MSG];
    static uint16_t buf_size = 0;
    static uint16_t last_countdown = 0;

    uint64_t timestamp;
    uint16_t countdown;
    TGNSSTime tim = { 0 };
    int n = 0;

    if(!data)
    {
        LOG_ERROR_MSG(gContext,"wrong parameter!");
        return false;
    }

    n = sscanf(data, 
        "%"SCNu64",%"SCNu16",$GVGNSTIM,%"SCNu64",%04"SCNu16",%02"SCNu8",%02"SCNu8",%02"SCNu8",%02"SCNu8",%02"SCNu8",%03"SCNu16",%u,%02"SCNi8",0X%08X",
        &timestamp,
        &countdown,
        &tim.timestamp,
        &tim.year,
        &tim.month,
        &tim.day,
        &tim.hour,
        &tim.minute,
        &tim.second,
        &tim.ms,
        &tim.scale,
        &tim.leapSeconds,
        &tim.validityBits
        );

    if (n != 13) //13 fields to parse
    {
        LOG_ERROR_MSG(gContext,"replayer: processGVGNSPOS failed!");
        return false;
    }

    //buffered data handling
    if (countdown < MAX_BUF_MSG) //enough space in buffer?
    {
        if (buf_size == 0) //a new sequence starts
        {
            buf_size = countdown+1;
            last_countdown = countdown;
            buf_tim[buf_size-countdown-1] = tim;
        }
        else if ((last_countdown-countdown) == 1) //sequence continued
        {
            last_countdown = countdown;
            buf_tim[buf_size-countdown-1] = tim;
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
        updateGNSSTime(buf_tim, buf_size);
        buf_size = 0;
        last_countdown = 0;
    }

    return true;
}



//backward compatible processing of GVGNSAC to the new TGNSSPosition
static bool processGVGNSAC(const char* data)
{
    //parse data like: 047434000,0$GVGNSAC,047434000,0,1.0,0,07,0,0,0,0,0,2,0X00000001,0X60A

    //storage for buffered data
    static TGNSSPosition buf_acc[MAX_BUF_MSG];
    static uint16_t buf_size = 0;
    static uint16_t last_countdown = 0;

    uint64_t timestamp;
    uint16_t countdown;
    TGNSSPosition pos = { 0 };
    uint16_t fixStatus;
    float sigmaLatitude;
    float sigmaLongitude;
    uint32_t GVGNSAC_validityBits;
    int n = 0;

    if(!data)
    {
        LOG_ERROR_MSG(gContext,"wrong parameter!");
        return false;
    }

    n = sscanf(data, "%llu,%hu$GVGNSAC,%llu,%f,%f,%f,%hu,%hu,%hu,%f,%f,%f,%hu,%x,%x",
         &timestamp, &countdown, &pos.timestamp,
         &pos.pdop, &pos.hdop, &pos.vdop,
         &pos.usedSatellites, &pos.trackedSatellites, &pos.visibleSatellites,
         &sigmaLatitude, &sigmaLongitude, &pos.sigmaAltitude,
         &fixStatus, &pos.fixTypeBits, &GVGNSAC_validityBits);

    if (n != 15) //15 fields to parse
    {
        LOG_ERROR_MSG(gContext,"replayer: processGVGNSAC failed!");
        return false;
    }

    //fix status: order in enum has changed
    if (fixStatus == 0) { pos.fixStatus = GNSS_FIX_STATUS_NO; }
    if (fixStatus == 1) { pos.fixStatus = GNSS_FIX_STATUS_2D; }
    if (fixStatus == 2) { pos.fixStatus = GNSS_FIX_STATUS_3D; }
    if (fixStatus == 3) { pos.fixStatus = GNSS_FIX_STATUS_TIME; }
    //calculate sigmaHPosition from sigmaLatitude, sigmaLongitude*sigmaLongitude);
    pos.sigmaHPosition = sqrt(sigmaLatitude*sigmaLatitude);
    //map the old validity bits to the new validity bits
    pos.validityBits = 0;
    if (GVGNSAC_validityBits&0x00000001) { pos.validityBits |= GNSS_POSITION_PDOP_VALID; }
    if (GVGNSAC_validityBits&0x00000002) { pos.validityBits |= GNSS_POSITION_HDOP_VALID; }
    if (GVGNSAC_validityBits&0x00000004) { pos.validityBits |= GNSS_POSITION_VDOP_VALID; }
    if (GVGNSAC_validityBits&0x00000008) { pos.validityBits |= GNSS_POSITION_USAT_VALID; }
    if (GVGNSAC_validityBits&0x00000010) { pos.validityBits |= GNSS_POSITION_TSAT_VALID; }
    if (GVGNSAC_validityBits&0x00000020) { pos.validityBits |= GNSS_POSITION_VSAT_VALID; }
    if (GVGNSAC_validityBits&0x00000040) { pos.validityBits |= GNSS_POSITION_SHPOS_VALID; }
    if (GVGNSAC_validityBits&0x00000100) { pos.validityBits |= GNSS_POSITION_SALT_VALID; }
    if (GVGNSAC_validityBits&0x00000200) { pos.validityBits |= GNSS_POSITION_STAT_VALID; }
    if (GVGNSAC_validityBits&0x00000400) { pos.validityBits |= GNSS_POSITION_TYPE_VALID; }


    //global Position: update the changed fields, retain the existing fields from other callbacks
    TGNSSPosition upd_pos;
    if (gnssGetPosition(&upd_pos))
    {
        upd_pos.timestamp = pos.timestamp;
        upd_pos.pdop = pos.pdop;
        upd_pos.hdop = pos.hdop;
        upd_pos.vdop = pos.vdop;
        upd_pos.usedSatellites = pos.usedSatellites;
        upd_pos.trackedSatellites = pos.trackedSatellites;
        upd_pos.visibleSatellites = pos.visibleSatellites;
        upd_pos.sigmaHPosition = pos.sigmaHPosition;
        upd_pos.sigmaAltitude = pos.sigmaAltitude;
        upd_pos.fixStatus = pos.fixStatus;
        upd_pos.fixTypeBits = pos.fixTypeBits;
        upd_pos.validityBits |= pos.validityBits;
        pos = upd_pos;
    }

    //buffered data handling
    if (countdown < MAX_BUF_MSG) //enough space in buffer?
    {
        if (buf_size == 0) //a new sequence starts
        {
            buf_size = countdown+1;
            last_countdown = countdown;
            buf_acc[buf_size-countdown-1] = pos;
        }
        else if ((last_countdown-countdown) == 1) //sequence continued
        {
            last_countdown = countdown;
            buf_acc[buf_size-countdown-1] = pos;
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
        updateGNSSPosition(buf_acc,buf_size);
        buf_size = 0;
        last_countdown = 0;
    }

    return true;
}

//backward compatible processing of GVGNSP to the new TGNSSPosition
static bool processGVGNSP(const char* data)
{
    //parse data like: 061064000,0$GVGNSP,061064000,49.02657,12.06527,336.70000,0X07

    //storage for buffered data
    static TGNSSPosition buf_pos[MAX_BUF_MSG];
    static uint16_t buf_size = 0;
    static uint16_t last_countdown = 0;

    uint64_t timestamp;
    uint16_t countdown;
    TGNSSPosition pos = { 0 };
    uint32_t GVGNSP_validityBits;
    int n = 0;

    if(!data)
    {
        LOG_ERROR_MSG(gContext,"wrong parameter!");
        return false;
    }

    n = sscanf(data, "%llu,%hu$GVGNSP,%llu,%lf,%lf,%f,%x", &timestamp, &countdown, &pos.timestamp, &pos.latitude, &pos.longitude, &pos.altitudeMSL, &GVGNSP_validityBits);

    if (n != 7) //7 fields to parse
    {
        LOG_ERROR_MSG(gContext,"replayer: processGVGNSP failed!");
        return false;
    }

    //map the old validity bits to the new validity bits
    pos.validityBits = 0;
    if (GVGNSP_validityBits&0x00000001) { pos.validityBits |= GNSS_POSITION_LATITUDE_VALID; }
    if (GVGNSP_validityBits&0x00000002) { pos.validityBits |= GNSS_POSITION_LONGITUDE_VALID; }
    if (GVGNSP_validityBits&0x00000004) { pos.validityBits |= GNSS_POSITION_ALTITUDEMSL_VALID; }

    //buffered data handling
    if (countdown < MAX_BUF_MSG) //enough space in buffer?
    {
        if (buf_size == 0) //a new sequence starts
        {
            buf_size = countdown+1;
            last_countdown = countdown;
            buf_pos[buf_size-countdown-1] = pos;
        }
        else if ((last_countdown-countdown) == 1) //sequence continued
        {
            last_countdown = countdown;
            buf_pos[buf_size-countdown-1] = pos;
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
        updateGNSSPosition(buf_pos,buf_size);
        buf_size = 0;
        last_countdown = 0;
    }

    return true;
}

//backward compatible processing of GVGNSC to the new TGNSSPosition
static bool processGVGNSC(const char* data)
{
    //parse data like: 061064000,0$GVGNSC,061064000,0.00,0,131.90000,0X05

    //storage for buffered data
    static TGNSSPosition buf_course[MAX_BUF_MSG];
    static uint16_t buf_size = 0;
    static uint16_t last_countdown = 0;

    uint64_t timestamp;
    uint16_t countdown;
    TGNSSPosition pos = { 0 };
    uint32_t GVGNSC_validityBits;
    int n = 0;

    if(!data)
    {
        LOG_ERROR_MSG(gContext,"wrong parameter!");
        return false;
    }

    n = sscanf(data, "%llu,%hu$GVGNSC,%llu,%f,%f,%f,%x", &timestamp, &countdown, &pos.timestamp, &pos.hSpeed, &pos.vSpeed, &pos.heading, &GVGNSC_validityBits);

    if (n != 7) //7 fields to parse
    {
        LOG_ERROR_MSG(gContext,"replayer: processGVGNSC failed!");
        return false;
    }

    //map the old validity bits to the new validity bits
    pos.validityBits = 0;
    if (GVGNSC_validityBits&0x00000001) { pos.validityBits |= GNSS_POSITION_HSPEED_VALID; }
    if (GVGNSC_validityBits&0x00000002) { pos.validityBits |= GNSS_POSITION_VSPEED_VALID; }
    if (GVGNSC_validityBits&0x00000004) { pos.validityBits |= GNSS_POSITION_HEADING_VALID; }


    //global Position: update the changed fields, retain the existing fields from other callbacks
    TGNSSPosition upd_pos;
    if (gnssGetPosition(&upd_pos))
    {    
        upd_pos.timestamp = pos.timestamp;
        upd_pos.hSpeed = pos.hSpeed;
        upd_pos.vSpeed = pos.vSpeed;
        upd_pos.heading = pos.heading;
        upd_pos.validityBits |= pos.validityBits;
        pos = upd_pos;        
    }

    //buffered data handling
    if (countdown < MAX_BUF_MSG) //enough space in buffer?
    {
        if (buf_size == 0) //a new sequence starts
        {
            buf_size = countdown+1;
            last_countdown = countdown;
            buf_course[buf_size-countdown-1] = pos;
        }
        else if ((last_countdown-countdown) == 1) //sequence continued
        {
            last_countdown = countdown;
            buf_course[buf_size-countdown-1] = pos;
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
        updateGNSSPosition(buf_course,buf_size);
        buf_size = 0;
        last_countdown = 0;
    }

    return true;
}

static bool processGVGNSSAT(const char* data)
{
    //parse data like: 061064000,05$GVGNSSAT,061064000,1,18,314.0,22.0,39,0X00,0X1F

    //storage for buffered data
    static TGNSSSatelliteDetail buf_sat[MAX_BUF_MSG];
    static uint16_t buf_size = 0;
    static uint16_t last_countdown = 0;    

    uint64_t timestamp;
    uint16_t countdown;
    TGNSSSatelliteDetail sat = { 0 };
    uint16_t system = 0;
    int n = 0;

    if(!data)
    {
        LOG_ERROR_MSG(gContext,"wrong parameter!");
        return false;
    }

    n = sscanf(data, "%llu,%hu,$GVGNSSAT,%llu,%hu,%hu,%hu,%hu,%hu,%x,%hu,%x",
        &timestamp, &countdown,
        &sat.timestamp, &system, &sat.satelliteId,
        &sat.azimuth, &sat.elevation, &sat.CNo,
        &sat.statusBits, &sat.posResidual, &sat.validityBits);

    if (n != 11) //11 fields to parse
    {
        //try old version without posResidual and without comma befroe $
        n = sscanf(data, "%llu,%hu$GVGNSSAT,%llu,%hu,%hu,%hu,%hu,%hu,%x,%x", &timestamp, &countdown, &sat.timestamp,&system,&sat.satelliteId,&sat.azimuth,&sat.elevation,&sat.CNo,&sat.statusBits,&sat.validityBits);
        sat.validityBits &= ~GNSS_SATELLITE_RESIDUAL_VALID; //just to be safe
        
        if (n != 10) //10 fields to parse
        {
            LOG_ERROR_MSG(gContext,"replayer: processGVGNSSAT failed!");
            return false;
        }
    }

    //map integer to enum
    sat.system = system;
    //LOG_DEBUG(gContext,"Decoded: %llu,%hu$GVGNSSAT,%llu,%d,%hu,%hu,%hu,%hu,0X%X,0X%X ", timestamp, countdown, sat.timestamp, sat.system, sat.satelliteId, sat.azimuth, sat.elevation, sat.CNo, sat.statusBits, sat.validityBits);


    //buffered data handling
    if (countdown < MAX_BUF_MSG) //enough space in buffer?
    {
        if (buf_size == 0) //a new sequence starts
        {
            buf_size = countdown+1;
            last_countdown = countdown;
            buf_sat[buf_size-countdown-1] = sat;         
        }
        else if ((last_countdown-countdown) == 1) //sequence continued
        {
            last_countdown = countdown;
            buf_sat[buf_size-countdown-1] = sat;                     
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
        updateGNSSSatelliteDetail(buf_sat,buf_size);
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

    DLT_REGISTER_APP("GNSS", "GNSS-SERVICE");
    DLT_REGISTER_CONTEXT(gContext,"GSRV", "Global Context");

    LOG_DEBUG(gContext,"GNSSService listening on port %d...",port);

    if((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1)
    {
        LOG_ERROR_MSG(gContext,"socket() failed!");
        exit(EXIT_FAILURE);
    }

    memset((char *) &si_me, 0, sizeof(si_me));
    si_me.sin_family = AF_INET;

    si_me.sin_port = htons(port);
    si_me.sin_addr.s_addr = htonl(INADDR_ANY);
    if(bind(s, (struct sockaddr *)&si_me, (socklen_t)sizeof(si_me)) == -1)
    {
         LOG_ERROR_MSG(gContext,"bind() failed!");
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
                    
            readBytes = recvfrom(s, buf, BUFLEN, 0, (struct sockaddr *)&si_other, (socklen_t *)&slen);
    
            if(readBytes < 0)
            {
                LOG_ERROR_MSG(gContext,"recvfrom() failed!");
                exit(EXIT_FAILURE);
            }
            buf[readBytes] = '\0';

            sscanf(buf, "%*[^'$']$%" STRINGIFY(MSGIDLEN) "[^',']", msgId);

            LOG_DEBUG(gContext,"Data:%s", buf);

            if(strcmp("GVGNSPOS", msgId) == 0)
            {
                 processGVGNSPOS(buf);
            }
            else if(strcmp("GVGNSTIM", msgId) == 0)
            {
                 processGVGNSTIM(buf);
            }
            else if(strcmp("GVGNSSAT", msgId) == 0)
            {
                 processGVGNSSAT(buf);
            }
            //handling of old logs for backward compatibility 
            else if(strcmp("GVGNSP", msgId) == 0)
            {
                 processGVGNSP(buf);
            }
            else if(strcmp("GVGNSC", msgId) == 0)
            {
                 processGVGNSC(buf);
            }
            else if(strcmp("GVGNSAC", msgId) == 0)
            {
                 processGVGNSAC(buf);
            }            
        }

    }

    close(s);

    return EXIT_SUCCESS;
}

