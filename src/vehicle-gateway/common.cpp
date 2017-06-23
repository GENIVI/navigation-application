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

#include <common.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

uint64_t get_timestamp()
{
  struct timespec time_value;
  if (clock_gettime(CLOCK_MONOTONIC, &time_value) != -1)
  {
    return (time_value.tv_sec*1000 + time_value.tv_nsec/1000000);
  }
  else
  {
    return 0xFFFFFFFFFFFFFFFF;
  }
}

