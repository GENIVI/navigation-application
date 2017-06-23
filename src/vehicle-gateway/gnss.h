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

#ifndef INCLUDE_GNSS
#define INCLUDE_GNSS
#include <semaphore.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

//shared data management
#define MAX_GNSS_BUFFER_SIZE 255
extern pthread_mutex_t mutex_gnss;
extern bool gnssDataReady;
extern char gnssBuffer[];
extern uint64_t gnssTimestamp;
bool gnss_init(const char* gnss_device, unsigned int baudrate);
bool gnss_destroy();

#ifdef __cplusplus
}
#endif

#endif
