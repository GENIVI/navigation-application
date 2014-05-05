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
positioning_BIN=$(BIN_DIR)/positioning
gnss-service_BIN=$(BIN_DIR)/gnss-service
sensors-service_BIN=$(BIN_DIR)/sensors-service
positioning_URL=http://git.projects.genivi.org/lbs/positioning.git
positioning_VERSION=HEAD
positioning_SRC=$(SRC_DIR)/positioning_$(positioning_VERSION)
positioning_API=$(positioning_SRC)/enhanced-position-service/api

ALL+=positioning

help::
	@echo "positioning: Build positioning"


positioning: $(positioning_BIN)/enhanced-position-service/src/server/position-daemon

$(positioning_BIN)/Makefile: $(positioning_SRC)/enhanced-position-service/CMakeLists.txt
	mkdir -p $(positioning_BIN) $(gnss-service_BIN) $(sensors-service_BIN)
	cd $(gnss-service_BIN) && cmake $(positioning_SRC)/gnss-service
	cd $(sensors-service_BIN) && cmake $(positioning_SRC)/sensors-service
	cd $(positioning_BIN) && cmake -DWITH_GPSD=OFF -DWITH_DLT=OFF -DWITH_REPLAYER=ON -DWITH_TESTS=OFF $(positioning_SRC)/enhanced-position-service


$(positioning_BIN)/enhanced-position-service/src/server/position-daemon: $(positioning_BIN)/Makefile
	cd $(gnss-service_BIN) && make
	cd $(sensors-service_BIN) && make
	cd $(positioning_BIN) && make

$(positioning_SRC)/enhanced-position-service/CMakeLists.txt:
	cd $(positioning_SRC)/.. && git clone $(positioning_URL) $(positioning_SRC)
	cd $(positioning_SRC) && git checkout $(positioning_VERSION)
