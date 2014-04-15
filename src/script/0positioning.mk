# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file 0positioning.mk
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
positioning_SRC=$(SRC_DIR)/positioning
positioning_API=$(positioning_SRC)/EnhancedPositionService/api
positioning_BIN=$(BIN_DIR)/positioning
positioning_URL=https://git.genivi.org/srv/git/positioning
positioning_VERSION=daaf1b10766b04f5b1b6fa7fb7fc465bc48debb2

ALL+=positioning

help::
	@echo "positioning: Build positioning"


positioning: $(positioning_BIN)/EnhancedPositionService/src/server/position-daemon

$(positioning_BIN)/Makefile: $(positioning_SRC)/CMakeLists.txt
	mkdir -p $(positioning_BIN)
	cd $(positioning_BIN) && cmake -DWITH_GPSD=OFF -DWITH_DLT=OFF -DWITH_REPLAYER=ON -DWITH_TESTS=OFF $(positioning_SRC)

$(positioning_BIN)/EnhancedPositionService/src/server/position-daemon: $(positioning_BIN)/Makefile
	cd $(positioning_BIN) && make

$(positioning_SRC)/CMakeLists.txt:
	cd $(positioning_SRC)/.. && git clone $(positioning_URL)
	cd $(positioning_SRC) && git checkout $(positioning_VERSION)
