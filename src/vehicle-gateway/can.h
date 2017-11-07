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

#ifndef INCLUDE_CAN
#define INCLUDE_CAN

#define CAN_MESSAGE_FILTER 0x123
#define CAN_MESSAGE_MASK 0x7FF
#define CAN_MESSAGE_MAX_DATA_LENGTH 8
//index is the index in the data frame, format is the length (ex: engine speed is 1758, index is 4 and format is 4
//Engine speed frame: 20881758330040FFFF22
// => 0x1758*0.125 = 5976*0.125 = 747 RPM
#define CAN_MESSAGE_ENGINE_SPEED_ID_AND_DATA_SIZE "2088"
#define CAN_MESSAGE_ENGINE_SPEED_INDEX 4
#define CAN_MESSAGE_ENGINE_SPEED_FORMAT 4
//Fuel level frame: 61267321013C0000
// => 0x3C*0.5 = 60*0.5 = 30l
#define CAN_MESSAGE_FUEL_LEVEL_ID_AND_DATA_SIZE "6126"
#define CAN_MESSAGE_FUEL_LEVEL_INDEX 10
#define CAN_MESSAGE_FUEL_LEVEL_FORMAT 2
//Wheel ticks frame: 50D700091508EC8E90
//rear left 0915 rear right 08EC  filter 7FFF error bit 15
#define CAN_MESSAGE_WHEEL_TICK_ID_AND_DATA_SIZE "50D7"
#define CAN_MESSAGE_RL_WHEEL_TICK_INDEX 6
#define CAN_MESSAGE_RR_WHEEL_TICK_INDEX 10
#define CAN_MESSAGE_WHEEL_TICK_FORMAT 4

#define CAN_ID_AND_DATA_SIZE_LENGTH 4

typedef enum {
    MESSAGE_ENGINE_SPEED,
    MESSAGE_WHEEL_TICK,
    MESSAGE_FUEL_LEVEL,
    MESSAGE_VEHICLE_SPEED,
    NO_MESSAGE
} can_message_id_t;

#endif
