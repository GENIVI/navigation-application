/**************************************************************************
* @licence app begin@
*
* SPDX-License-Identifier: MPL-2.0
*
* \brief Simple NMEA Parser for GPS data
*        Original version: \see http://sourceforge.net/projects/get201/
* 
* \author Helmut Schmidt <https://github.com/huirad>
*
* \copyright Copyright (C) 2009, Helmut Schmidt
* 
* \license
* This Source Code Form is subject to the terms of the
* Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
* this file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
* @licence end@
**************************************************************************/



#ifndef _HNMEA_H
#define _HNMEA_H


//enum for NMEA parser result
typedef enum {
    NMEA_INIT,          //initial value - will never be returned by the parser
    NMEA_UKNOWN,        //unknown content
    NMEA_BAD_CHKSUM,    //BAD NMEA Checksum
    NMEA_RMC,           //GxRMC Sentence
    NMEA_GGA,           //GxGGA Sentence
    NMEA_GSA,           //GxGSA Sentence
    NMEA_GSV,           //GxGSV Sentence
    NMEA_GST            //GxGST Sentence
} NMEA_RESULT;

//bitmaps for GNSS data
typedef enum {
    GNS_DATA_LAT    = 0x0001,  //latitude
    GNS_DATA_LON    = 0x0002,  //longitude
    GNS_DATA_ALT    = 0x0004,  //altitude
    GNS_DATA_GEOID  = 0x0008,  //geoid separation
    GNS_DATA_DATE   = 0x0010,  //date
    GNS_DATA_TIME   = 0x0020,  //time
    GNS_DATA_COURSE = 0x0040,  //course (heading)
    GNS_DATA_SPEED  = 0x0080,  //speed
    GNS_DATA_HDOP   = 0x0100,  //HDOP
    GNS_DATA_VDOP   = 0x0200,  //VDOP
    GNS_DATA_PDOP   = 0x0400,  //PDOP
    GNS_DATA_USAT   = 0x0800,  //number of used satellites
    GNS_DATA_FIX2D  = 0x1000,  //at least 2D Fix
    GNS_DATA_FIX3D  = 0x2000,  //3D Fix (GPS_DATA_FIX2D will be set also)
    GNS_DATA_HACC   = 0x4000,  //horizontal accuracy
    GNS_DATA_VACC   = 0x8000   //vertical accuracy
} GNS_DATA_TYPE;

typedef enum {
    GNS_DATA_USAT_GPS   = 0x0001,  //number of used GPS satellites
    GNS_DATA_USAT_GLO   = 0x0002   //number of used GLONASS satellites    
} GNS_DATA_EXT_TYPE;    

typedef struct {
    int valid;      //bitmask of GNS_DATA_TYPE for cumulative valid fields
    int valid_new;  //bitmask of GNS_DATA_TYPE for new valid fields
    int valid_ext;  //bitmask of GNS_DATA_EXT_TYPE for cumulative valid fields
    int valid_ext_new;  //bitmask of GNS_DATA_EXT_TYPE for new valid fields    
    double lat;     //latitude in degrees - negative values are south of equator
    double lon;     //longitude in degrees - negative values are west of Greenwich
    double alt;     //altitude in meter above sea level
    double geoid;   //geoid separation in meter
    int date_yyyy;  //date::year since B.C.
    int date_mm;    //date::month - january = 1
    int date_dd;    //date::day - day of month 
    int time_hh;    //time::hour
    int time_mm;    //time::minute
    int time_ss;    //time::second
    int time_ms;    //time::millisecond
    double course;  //course (heading) in degrees compass-like
    double speed;   //speed im m/s
    float hdop;     //hdop
    float vdop;     //vdop
    float pdop;     //pdop
    int usat;       //number of satellites
    int fix2d;      //GPS status: at least 2D Fix
    int fix3d;      //GPS status: 3D Fix - fix2d will be set also 
    float hacc;     //horizontal accuracy in m
    float vacc;     //vertical accuracy in m
    int usat_gps;   //number of GPS satellites
    int usat_glo;   //number of GLONASS satellites    
} GNS_DATA;

void HNMEA_Init_GNS_DATA(GNS_DATA* gns_data);

NMEA_RESULT HNMEA_Parse(char* line, GNS_DATA* gns_data);

#endif //_HNMEA_H

