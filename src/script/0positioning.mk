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
# \author Philippe Colliot <philippe.colliot@mpsa.com>
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
# 4/6/2014, Philippe Colliot, complete src-clean option
#
# @licence end@
positioning_BIN=$(BIN_DIR)/positioning

gnss-service_BIN=$(positioning_BIN)/gnss-service
sensors-service_BIN=$(positioning_BIN)/sensors-service
enhanced-position-service_BIN=$(positioning_BIN)/enhanced-position-service

positioning_URL=http://git.projects.genivi.org/lbs/positioning.git
positioning_VERSION=09698f63ea27a24c533b4c015155ee9ebd7a3026
positioning_SRC=$(SRC_DIR)/positioning_$(positioning_VERSION)
positioning_API=$(positioning_SRC)/enhanced-position-service/api

ALL+=positioning

SRC_CLEAN+=clean-positioning_SRC

help::
	@echo "positioning: Build positioning"

clean-positioning_SRC::
	rm -rf $(SRC_DIR)/positioning_*

positioning: $(positioning_BIN)/enhanced-position-service

$(positioning_BIN)/enhanced-position-service: $(positioning_BIN)/Makefile
	cd $(gnss-service_BIN) && make
	cd $(sensors-service_BIN) && make
	cd $(enhanced-position-service_BIN) && make


$(positioning_BIN)/Makefile: $(positioning_SRC)/enhanced-position-service/CMakeLists.txt
	mkdir -p $(positioning_BIN) $(gnss-service_BIN) $(sensors-service_BIN) $(enhanced-position-service_BIN)
	cd $(gnss-service_BIN) && cmake $(positioning_SRC)/gnss-service
	cd $(sensors-service_BIN) && cmake $(positioning_SRC)/sensors-service
	cd $(enhanced-position-service_BIN) && cmake -DWITH_GPSD=OFF -DWITH_DLT=OFF -DWITH_REPLAYER=ON -DWITH_TESTS=OFF $(positioning_SRC)/enhanced-position-service

$(positioning_SRC)/enhanced-position-service/CMakeLists.txt:
	cd $(positioning_SRC)/.. && git clone $(positioning_URL) $(positioning_SRC)
	cd $(positioning_SRC) && git checkout $(positioning_VERSION)
