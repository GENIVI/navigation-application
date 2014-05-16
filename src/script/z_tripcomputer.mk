# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file tripcomputer.mk
#
# \brief This file is part of the Build System.
#
# \author Martin Schaller <martin.schaller@it-schaller.de>
#
# \version 1.0
#
# This Source Code Form is subject to the terms of the
# Mozilla Public License (MPL), v. 2.0.
# If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# For further information see http://www.genivi.org/.
#
# List of changes:
# 
# <date>, <name>, <description of change>
#
# @licence end@
tripcomputer_SRC=$(SRC_DIR)/tripcomputer
tripcomputer_BIN=$(BIN_DIR)/tripcomputer

ALL+=tripcomputer
CONSTANTS_SRC+=$(tripcomputer_SRC)/constants.xml

help::
	@echo "tripcomputer: Build tripcomputer"

$(tripcomputer_BIN)/Makefile: $(tripcomputer_SRC)/CMakeLists.txt navigation-service-checkout
	mkdir -p $(tripcomputer_BIN)
	cd $(tripcomputer_BIN) && cmake $(tripcomputer_SRC)

$(tripcomputer_BIN)/tripcomputer: $(tripcomputer_BIN)/Makefile
	$(MAKE) -C $(tripcomputer_BIN)
	
tripcomputer: $(tripcomputer_BIN)/tripcomputer
