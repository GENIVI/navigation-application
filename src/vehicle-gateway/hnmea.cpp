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


#include "hnmea.h"
#include "string.h"
#include "stdlib.h"
#include "math.h"

//some example/test strings
char test_gprmc[] = "$GPRMC,112911.000,A,4856.3328,N,01146.8259,E,35.75,108.51,050807,,,A*57";
char test_gpgga[] = "$GPGGA,112911.000,4856.3328,N,01146.8259,E,1,06,2.0,353.1,M,47.5,M,,0000*50";
char test_gpgsa[] = "$GPGSA,A,3,27,28,10,29,08,26,,,,,,,3.2,2.0,2.5*3F";
char test_gpgs1[] = "$GPGSV,3,1,12,27,17,075,20,19,07,027,,21,05,296,,18,11,325,*77";
char test_gpgs2[] = "$GPGSV,3,2,12,28,62,095,44,10,32,199,30,29,79,302,40,08,40,067,43*71";
char test_gpgs3[] = "$GPGSV,3,3,12,09,08,259,29,26,65,304,45,24,02,263,,17,08,134,28*7E";



void HNMEA_Init_GNS_DATA(GNS_DATA* gns_data)
{
    gns_data->valid         = 0;
    gns_data->valid_new     = 0;
    gns_data->valid_ext     = 0;
    gns_data->valid_ext_new = 0;    
    gns_data->lat           = 999.99;
    gns_data->lon           = 999.99;
    gns_data->alt           = -1000.0;
    gns_data->geoid         = -1000.0;
    gns_data->date_yyyy     = -1;
    gns_data->date_mm       = -1;
    gns_data->date_dd       = -1;
    gns_data->time_hh       = -1;
    gns_data->time_mm       = -1;
    gns_data->time_ss       = -1;
    gns_data->time_ms       = -1;
    gns_data->course        = -999.99;
    gns_data->speed         = -999.99;
    gns_data->hdop          = -999.99;
    gns_data->vdop          = -999.99;
    gns_data->pdop          = -999.99;
    gns_data->usat          = -99;
    gns_data->fix2d         = -1;
    gns_data->fix3d         = -1;
    gns_data->hacc          = 999.9;
    gns_data->vacc          = 999.9;
    gns_data->usat_gps      = -99;
    gns_data->usat_glo      = -99;    
}


//Test if the NMEA Checkum is valid. 
//If no checkum is available, it is considered as valid
//The optional checksum field consists of a "*" and two hex digits
//  representing the exclusive OR of all characters between, but not
//  including, the "$" and "*".
int HNMEA_Checksum_Valid(char* line)
{
    int ret = 0;
    char calc_checksum = 0;
    char nmea_checksum = 0;
    int i = 1; 
    int len = strlen(line);

    if ( (len > 1) || line[0] == '$')
    {
        //calculate checksum
        while ( (i < len-1) && (line[i] != '*') )
        {
            calc_checksum = calc_checksum ^ line[i];
            i++;
        }
        if ( (len >= i+3) && (line[i] == '*') )
        {
            //optionally, also strtoul() could be used for checksum reading
            char str [2];
            str[1] = 0;
            
            str[0] = line[i+1];
            int c1 = strcspn("_0123456789ABCDEF", str);

            str[0] = line[i+2];
            int c2 = strcspn("_0123456789ABCDEF", str);

            if ( (c1 > 0) && (c2 > 0) )
            {
                nmea_checksum = (c1-1)*16+(c2-1);
                if (nmea_checksum == calc_checksum)
                {
                    ret = 1;
                }
            }
        }
        else //no checksum considered as valid
        {
            ret = 1;
        }
    }
    return ret;
}

void HNMEA_Parse_RMC(char* line, GNS_DATA* gns_data)
{
    enum { MAX_FIELD_LEN = 128};
    char field[MAX_FIELD_LEN];
    int i = 0;      // field index
    int l = 0;      // line character index
    int f = 0;      // field character index
    int stop = 0;   // stop flag
    int len = strlen(line);

    gns_data->valid_new = 0;
    gns_data->valid_ext_new = 0;

    //outer loop - stop at line end
    while ( (l < len ) && (stop == 0) )
    {
        //inner loop - stop at line and and field separator
        while ( (f < MAX_FIELD_LEN) && (l< len) && (line[l] != ',') && (line[l] != '*') )
        {
            field[f] = line[l];
            l++;
            f++;
        }
        field[f] = '\0'; // add string terminator

        switch (i)
        {
            case 0: //$GPRMC or $GNRMC
            {
                //cross-check for sentence name
                if ((strncmp (field, "$GPRMC", 6) != 0) && (strncmp (field, "$GNRMC", 6) != 0))
                {
                    // force termination of loop
                    stop = 1;
                }
                break;
            }
            case 1: //time hhmmss.sss
            {
                //length check
                if (strlen (field) >=6)
                {
                    gns_data->time_ss = atoi(field+4);
                    gns_data->time_ms = (atof(field+4)-gns_data->time_ss)*1000;
                    field[4] = '\0';
                    gns_data->time_mm = atoi(field+2);
                    field[2] = '\0';
                    gns_data->time_hh = atoi(field);
                    gns_data->valid_new |= GNS_DATA_TIME;
                }
                break;
            }
            case 2: //status - A = OK, V = warning
            {
                //length check
                if (strlen (field) >=1)
                {
                    if (field[0] == 'A')
                    {
                        gns_data->fix2d = 1;
                    }
                    else
                    {
                        gns_data->fix2d = 0;
                    }
                    gns_data->valid_new |= GNS_DATA_FIX2D;
                }
                break;
            }
            case 3: //latitude - absolute value
            {
                //check for minimum length + evaluate only if status ok
                if ( ((gns_data->valid_new & GNS_DATA_FIX2D)!=0) && (gns_data->fix2d) && (strlen (field) >=2) )
                {
                    double fraction = 0.0;
                    if (strlen (field) >=3)
                    {
                        fraction = atof(field+2)/60.0;
                    }
                    field[2]=0;
                    gns_data->lat = atoi(field) + fraction;
                    gns_data->valid_new |= GNS_DATA_LAT;
                }
                break;
            }
            case 4: //latitude - sign
            {
                //length check
                if (strlen (field) >=1)
                {
                    if ((field[0] == 'S') || (field[0] == 's'))
                    {
                        gns_data->lat = - gns_data->lat;
                    }
                }
                break;
            }
            case 5: //longitude - absolute value
            {
                //check for minimum length + evaluate only if status ok
                if ( ((gns_data->valid_new & GNS_DATA_FIX2D)!=0) && (gns_data->fix2d) && (strlen (field) >=3) )
                {
                    double fraction = 0.0;
                    if (strlen (field) >=4)
                    {
                        fraction = atof(field+3)/60.0;
                    }
                    field[3]=0;
                    gns_data->lon = atoi(field) + fraction;
                    gns_data->valid_new |= GNS_DATA_LON;
                }
                break;
            }
            case 6: //longitude - sign
            {
                //length check
                if (strlen (field) >=1)
                {
                    if ((field[0] == 'W') || (field[0] == 'w'))
                    {
                        gns_data->lon = - gns_data->lon;
                    }
                }
                break;
            }
            case 7: //speed - knots
            {
                //length check + evaluate only if status ok
                if (((gns_data->valid_new & GNS_DATA_FIX2D)!=0) && (gns_data->fix2d) && (strlen (field) >=1) )
                {
                    gns_data->speed = atof(field)*1.852/3.6;
                    gns_data->valid_new |= GNS_DATA_SPEED;
                }
                break;
            }
            case 8: //course - degrees
            {
                //length check + evaluate only if status ok
                if (((gns_data->valid_new & GNS_DATA_FIX2D)!=0) && (gns_data->fix2d) && (strlen (field) >=1) )
                {
                    gns_data->course = atof(field);
                    gns_data->valid_new |= GNS_DATA_COURSE;
                }
                break;
            }
            case 9: //date yymmdd
            {
                //length check
                if (strlen (field) >=6)
                {
                    gns_data->date_yyyy = 2000 + atoi(field+4);
                    field[4] = '\0';
                    gns_data->date_mm = atoi(field+2);
                    field[2] = '\0';
                    gns_data->date_dd = atoi(field);
                    gns_data->valid_new |= GNS_DATA_DATE;
                }
                stop = 1; //ignore all other fields
                break;
            }
            default:
            {
                stop = 1;
                break;
            }
        }

        //one more field?
        if ( line[l] == ',' )
        {
            //skip separator
            l++;
            //reset 
            f = 0;
            //increment field index
            i++;
        }
        else 
        {
            // force termination of loop
            stop = 1;
        }
    }

    //update validity mask with new data
    gns_data->valid |= gns_data->valid_new;
    gns_data->valid_ext |= gns_data->valid_ext_new;
}

void HNMEA_Parse_GGA(char* line, GNS_DATA* gns_data)
{
    enum { MAX_FIELD_LEN = 128};
    char field[MAX_FIELD_LEN];
    int i = 0;      // field index
    int l = 0;      // line character index
    int f = 0;      // field character index
    int stop = 0;   // stop flag
    int len = strlen(line);

    //intermediate storage for lat, lon until Position Fix Indicator is evaluated
    double lat = 0.0;
    double lon = 0.0;
    //intermediate storage for alt, geoid until units are correct
    double alt = 0.0;
    double geoid = 0.0;

    gns_data->valid_new = 0;
    gns_data->valid_ext_new = 0;

    //outer loop - stop at line end
    while ( (l < len ) && (stop == 0) )
    {
        //inner loop - stop at line and and field separator
        while ( (f < MAX_FIELD_LEN) && (l< len) && (line[l] != ',') && (line[l] != '*') )
        {
            field[f] = line[l];
            l++;
            f++;
        }
        field[f] = '\0'; // add string terminator

        switch (i)
        {
            case 0: //$GPGGA or $GNGGA
            {
                //cross-check for sentence name
                if ((strncmp (field, "$GPGGA", 6) != 0) && (strncmp (field, "$GNGGA", 6) != 0))
                {
                    // force termination of loop
                    stop = 1;
                }
                break;
            }
            case 1: //time hhmmss.sss
            {
                //length check
                if (strlen (field) >=6)
                {
                    gns_data->time_ss = atoi(field+4);
                    gns_data->time_ms = (atof(field+4)-gns_data->time_ss)*1000;
                    field[4] = '\0';
                    gns_data->time_mm = atoi(field+2);
                    field[2] = '\0';
                    gns_data->time_hh = atoi(field);
                    gns_data->valid_new |= GNS_DATA_TIME;
                }
                break;
            }
            case 2: //latitude - absolute value
            {
                //check for minimum length
                if (strlen (field) >=2)
                {
                    double fraction = 0.0;
                    if (strlen (field) >=3)
                    {
                        fraction = atof(field+2)/60.0;
                    }
                    field[2]=0;
                    lat = atoi(field) + fraction;
                    gns_data->valid_new |= GNS_DATA_LAT;
                }
                break;
            }
            case 3: //latitude - sign
            {
                //length check
                if (strlen (field) >=1)
                {
                    if ((field[0] == 'S') || (field[0] == 's'))
                    {
                        lat = - lat;
                    }
                }
                break;
            }
            case 4: //longitude - absolute value
            {
                //check for minimum length
                if (strlen (field) >=3)
                {
                    double fraction = 0.0;
                    if (strlen (field) >=4)
                    {
                        fraction = atof(field+3)/60.0;
                    }
                    field[3]=0;
                    lon = atoi(field) + fraction;
                    gns_data->valid_new |= GNS_DATA_LON;
                }
                break;
            }
            case 5: //longitude - sign
            {
                //length check
                if (strlen (field) >=1)
                {
                    if ((field[0] == 'W') || (field[0] == 'w'))
                    {
                        lon = - lon;
                    }
                }
                break;
            }
            case 6: //position fix indicator
            {
                //length check
                if (strlen (field) >=1)
                {
                    if ( (field[0] == '1') || (field[0] == '2') || (field[0] == '6') )
                    {
                        gns_data->fix2d = 1;
                        gns_data->lat = lat;
                        gns_data->lon = lon;
                    }
                    else
                    {
                        gns_data->fix2d = 0;
                        gns_data->valid_new &= ~(GNS_DATA_LAT | GNS_DATA_LON);
                    }
                    gns_data->valid_new |= GNS_DATA_FIX2D;
                }
                break;
            }
            case 7: //number of used satellites
            {
                //length check
                if (strlen (field) >=1)
                {
                    gns_data->usat = atoi(field);
                    gns_data->valid_new |= GNS_DATA_USAT;
                }
                break;
            }
            case 8: //hdop
            {
                //length check
                if (strlen (field) >=1)
                {
                    gns_data->hdop = atof(field);
                    gns_data->valid_new |= GNS_DATA_HDOP;
                }
                break;
            }
            case 9: //altitude
            {
                //length check
                if (strlen (field) >=1)
                {
                    alt = atof(field);
                    gns_data->valid_new |= GNS_DATA_ALT;
                }
                break;
            }
            case 10: //altitude unit
            {
                //length check
                if (strlen (field) >=1)
                {
                    if ( (field[0] == 'M') && (gns_data->fix2d) )
                    {
                        gns_data->alt = alt;
                    }
                    else
                    {
                        gns_data->valid_new &= ~(GNS_DATA_ALT);
                    }
                }
                break;
            }
            case 11: //geoid separation
            {
                //length check
                if (strlen (field) >=1)
                {
                    geoid = atof(field);
                    gns_data->valid_new |= GNS_DATA_GEOID;
                }
                break;
            }
            case 12: //geoid separation unit
            {
                //length check
                if (strlen (field) >=1)
                {
                    if (field[0] == 'M') 
                    {
                        gns_data->geoid = geoid;
                    }
                    else
                    {
                        gns_data->valid_new &= ~(GNS_DATA_GEOID);
                    }
                }
                stop = 1; //ignore all other fields
                break;
            }
            default:
            {
                stop = 1;
                break;
            }
        }

        //one more field?
        if ( line[l] == ',' )
        {
            //skip separator
            l++;
            //reset 
            f = 0;
            //increment field index
            i++;
        }
        else 
        {
            // force termination of loop
            stop = 1;
        }
    }

    //update validity mask with valid_new data
    gns_data->valid |= gns_data->valid_new;
    gns_data->valid_ext |= gns_data->valid_ext_new;

}

void HNMEA_Parse_GSA(char* line, GNS_DATA* gns_data)
{
    enum { MAX_FIELD_LEN = 128};
    char field[MAX_FIELD_LEN];
    int i = 0;      // field index
    int l = 0;      // line character index
    int f = 0;      // field character index
    int stop = 0;   // stop flag
    int len = strlen(line);

    int usat = 0; //counter for used satellites
    //NMEA 4.1: GSA has additional field systemId after VDOP
    //1=GPS 2=GLONASS 3=Galileo 4=BeiDou 
    int systemId = 0;

    gns_data->valid_new = 0;
    gns_data->valid_ext_new = 0;

    //outer loop - stop at line end
    while ( (l < len ) && (stop == 0) )
    {
        //inner loop - stop at line and and field separator
        while ( (f < MAX_FIELD_LEN) && (l< len) && (line[l] != ',') && (line[l] != '*') )
        {
            field[f] = line[l];
            l++;
            f++;
        }
        field[f] = '\0'; // add string terminator

        switch (i)
        {
            case 0: //$GPGSA or $GNGSA
            {
                //cross-check for sentence name
                if ((strncmp (field, "$GPGSA", 6) != 0) && (strncmp (field, "$GNGSA", 6) != 0))
                {
                    // force termination of loop
                    stop = 1;
                }
                break;
            }
            case 1: //selection mode - ignore
            {
                break;
            }
            case 2: //fix status 1- no fix, 2 - 2d fix, 3 - 3d fix
            {
                //length check
                if (strlen (field) >=1)
                {
                    if (field[0] == '2')
                    {
                        gns_data->fix2d = 1;
                        gns_data->fix3d = 0;
                    }
                    else if (field[0] == '3')
                    {
                        gns_data->fix2d = 1;
                        gns_data->fix3d = 1;
                    }
                    else
                    {
                        gns_data->fix2d = 0;
                        gns_data->fix3d = 0;
                    }
                    gns_data->valid_new |= GNS_DATA_FIX2D;
                    gns_data->valid_new |= GNS_DATA_FIX3D;
                }
                break;
            }
            case 3: //sat id 1-12
            case 4:
            case 5:
            case 6:
            case 7:
            case 8:
            case 9:
            case 10:
            case 11:
            case 12:
            case 13:
            case 14:
            {
                if (strlen (field) >=1)
                {
                    usat++;
                }
                break;
            }
            case 15: //PDOP
            {
                //length check
                if (strlen (field) >=1)
                {
                    gns_data->pdop = atof(field);
                    gns_data->valid_new |= GNS_DATA_PDOP;
                }
                break;
            }
            case 16: //HDOP
            {
                //length check
                if (strlen (field) >=1)
                {
                    gns_data->hdop = atof(field);
                    gns_data->valid_new |= GNS_DATA_HDOP;
                }
                break;
            }
            case 17: //VDOP
            {
                //length check
                if (strlen (field) >=1)
                {
                    gns_data->vdop = atof(field);
                    gns_data->valid_new |= GNS_DATA_VDOP;
                }
                break;
            }
            case 18: //NMEA 4.1 systemId
            {
                //length check
                if (strlen (field) >=1)
                {
                    systemId = atoi(field);
                }
                stop = 1; //ignore all other fields
                break;
            }            
            default:
            {
                stop = 1;
                break;
            }
        }

        //one more field?
        if ( line[l] == ',' )
        {
            //skip separator
            l++;
            //reset 
            f = 0;
            //increment field index
            i++;
        }
        else 
        {
            // force termination of loop
            stop = 1;
        }
    }

    if (usat > 0)
    {
        if (systemId == 0) //unspecified
        {
            gns_data->usat = usat;
            gns_data->valid_new |= GNS_DATA_USAT;
        }
        else if (systemId == 1) //GPS
        {
            gns_data->usat_gps = usat;
            gns_data->valid_ext_new |= GNS_DATA_USAT_GPS;
        }
        else if (systemId == 2) //GLONASS
        {
            gns_data->usat_glo = usat;
            gns_data->valid_ext_new |= GNS_DATA_USAT_GLO;
        }
    }

    //update validity mask with new data
    gns_data->valid |= gns_data->valid_new;
    gns_data->valid_ext |= gns_data->valid_ext_new;
}

void HNMEA_Parse_GST(char* line, GNS_DATA* gns_data)
{
    enum { MAX_FIELD_LEN = 128};
    char field[MAX_FIELD_LEN];
    int i = 0;      // field index
    int l = 0;      // line character index
    int f = 0;      // field character index
    int stop = 0;   // stop flag
    int len = strlen(line);

    
    float lat_std = 0.0;
    int lat_std_valid = 0;
    float lon_std = 0.0;
    float alt_std = 0.0;
    
    gns_data->valid_new = 0;
    gns_data->valid_ext_new = 0;

    //outer loop - stop at line end
    while ( (l < len ) && (stop == 0) )
    {
        //inner loop - stop at line and and field separator
        while ( (f < MAX_FIELD_LEN) && (l< len) && (line[l] != ',') && (line[l] != '*') )
        {
            field[f] = line[l];
            l++;
            f++;
        }
        field[f] = '\0'; // add string terminator

        switch (i)
        {
            case 0: //$GPGST
            {
                //cross-check for sentence name
                if ((strncmp (field, "$GPGST", 6) != 0) && (strncmp (field, "$GNGST", 6) != 0))
                {
                    // force termination of loop
                    stop = 1;
                }
                break;
            }
            case 1: //time hhmmss.sss
            {
                //length check
                if (strlen (field) >=6)
                {
                    gns_data->time_ss = atoi(field+4);
                    gns_data->time_ms = (atof(field+4)-gns_data->time_ss)*1000;
                    field[4] = '\0';
                    gns_data->time_mm = atoi(field+2);
                    field[2] = '\0';
                    gns_data->time_hh = atoi(field);
                    gns_data->valid_new |= GNS_DATA_TIME;
                }
                break;
            }
            case 2: // RMS value of the standard deviation of the ranges
            {
                //ignore
                break;
            }
            case 3: //Standard deviation of semi-major axis,
            {
                //ignore
                break;
            }
            case 4: //Standard deviation of semi-minor axis
            {
                //ignore
                break;
            }
            case 5: //Orientation of semi-major axis
            {
                //ignore
                break;
            }
            case 6: //Standard deviation of latitude, error in meters
            {
                //length check
                if (strlen (field) >=1)
                {
                    lat_std = atof(field);
                    lat_std_valid = 1;
                }
                break;
            }
            case 7: //Standard deviation of longitude, error in meters
            {
                //length check
                if ((strlen (field) >=1) && (lat_std_valid))
                {
                    lon_std = atof(field);
                    gns_data->hacc = sqrt(lat_std*lat_std + lon_std*lon_std);
                    gns_data->valid_new |= GNS_DATA_HACC;
                }
                break;
            }
            case 8: //Standard deviation of altitude, error in meters
            {
                //length check
                if (strlen (field) >=1)
                {
                    alt_std = atof(field);
                    gns_data->vacc = alt_std;
                    gns_data->valid_new |= GNS_DATA_VACC;
                }
                break;
            }
            default:
            {
                stop = 1;
                break;
            }
        }

        //one more field?
        if ( line[l] == ',' )
        {
            //skip separator
            l++;
            //reset 
            f = 0;
            //increment field index
            i++;
        }
        else 
        {
            // force termination of loop
            stop = 1;
        }
    }

    //update validity mask with new data
    gns_data->valid |= gns_data->valid_new;
    gns_data->valid_ext |= gns_data->valid_ext_new;
}

NMEA_RESULT HNMEA_Parse(char* line, GNS_DATA* gns_data)
{
    NMEA_RESULT ret = NMEA_UKNOWN;
    if ((strncmp (line, "$GPRMC", 6) == 0) || (strncmp (line, "$GNRMC", 6) == 0))
    {
        if (HNMEA_Checksum_Valid(line))
        {
            HNMEA_Parse_RMC(line, gns_data);
            ret = NMEA_RMC;
        }
        else
        {
            ret = NMEA_BAD_CHKSUM;
        }
    }
    else if ((strncmp (line, "$GPGGA", 6) == 0) || (strncmp (line, "$GNGGA", 6) == 0))
    {
        if (HNMEA_Checksum_Valid(line))
        {
            HNMEA_Parse_GGA(line, gns_data);
            ret = NMEA_GGA;
        }
        else
        {
            ret = NMEA_BAD_CHKSUM;
        }
    }
    else if ((strncmp (line, "$GPGSA", 6) == 0) || (strncmp (line, "$GNGSA", 6) == 0))
    {
        if (HNMEA_Checksum_Valid(line))
        {
            HNMEA_Parse_GSA(line, gns_data);
            ret = NMEA_GSA;
        }
        else
        {
            ret = NMEA_BAD_CHKSUM;
        }
    }
    else if ((strncmp (line, "$GPGST", 6) == 0) || (strncmp (line, "$GNGST", 6) == 0))
    {
        if (HNMEA_Checksum_Valid(line))
        {
            HNMEA_Parse_GST(line, gns_data);
            ret = NMEA_GST;
        }
        else
        {
            ret = NMEA_BAD_CHKSUM;
        }
    }
    return ret;
}

