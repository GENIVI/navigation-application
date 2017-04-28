/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2014 DENSO CORPORATION
*
* \file lm_control.h
*
* \brief This file is part of the FSA HMI.
*
* \author Tanibata, Nobuhiko <NOBUHIKO_TANIBATA@denso.co.jp>
*
* \version 1.0
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
*
* <date>, <name>, <description of change>
*
* @licence end@
*/
#ifndef LM_CONTROL_H
#define LM_CONTROL_H

#include <stdio.h>
#include <QObject>

#define DEBUG_LEVEL 2

#define LOG_INFO(...) { \
	if (0 < DEBUG_LEVEL) { \
		printf("[INFO] " __VA_ARGS__); \
		fflush(stdout); \
	} \
}

#define LOG_WARNING(...) { \
	if (1 < DEBUG_LEVEL) { \
		printf("[WARNING] " __VA_ARGS__); \
		fflush(stdout); \
	} \
}

#define LOG_ERROR(...) { \
	if (1 < DEBUG_LEVEL) { \
		printf("[ERROR] " __VA_ARGS__); \
		fflush(stdout); \
	} \
}

class lm_control : QObject
{
	Q_OBJECT

	public:
		lm_control(QObject *parent = 0);
		~lm_control();

		Q_INVOKABLE void surface_set_visibility(int surfaceid, int visibility);
		Q_INVOKABLE void surface_set_source_rectangle(
			int surfaceid, int x, int y, int width, int height);
		Q_INVOKABLE void surface_set_destination_rectangle(
			int surfaceid, int x, int y, int width, int height);
		Q_INVOKABLE void surface_remove(int surfaceid);
		Q_INVOKABLE void commit_changes();
};

#endif // LM_CONTROL_H
