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

#ifndef INCLUDE_OBD2
#define INCLUDE_OBD2

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stdint.h>
#include <math.h>
#include <sys/types.h>
#include <can.h>

bool obd2_init(char* obd2_device, unsigned int baudrate);

bool obd2_reset(uint64_t &timestamp);

bool obd2_config(uint64_t& timestamp);

bool obd2_read_engine_rpm(uint16_t& rpm, uint64_t &timestamp);

bool obd2_read_fuel_level(uint8_t& level,uint64_t& timestamp);

bool obd2_config_can_reader(uint64_t& timestamp);

can_message_id_t can_read(char*& data, uint64_t &timestamp);

#ifdef __cplusplus
}
#endif

#endif
