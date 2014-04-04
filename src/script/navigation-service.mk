# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file navigation-service.mk
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
navigation-service_URL="http://git.projects.genivi.org/lbs/navigation-service.git"
navigation-service_VERSION=HEAD
navigation-service_SRC=$(SRC_DIR)/navigation-service-$(navigation-service_VERSION)
navigation-service_API=$(navigation-service_SRC)/api
navigation-service_BIN=$(BIN_DIR)/navigation-service
navigation-service_DEPS=libsqlite3-dev libglibmm-2.4-dev sqlite3 xsltproc libdbus-c++-dev libdbus-1-dev

poi-service_SRC=$(navigation-service_SRC)/src/poi-service
poi-service_API=$(navigation-service_API)/poi-service
poi-service_BIN=$(BIN_DIR)/poi-service

poi-common_BIN=$(BIN_DIR)/poi-common

DEPS+=$(navigation-service_DEPS)

ALL+=poi-service navit-plugins
CONSTANTS_SRC+=$(navigation-service_SRC)/api/mapviewer/genivi-mapviewer-constants.xml
CONSTANTS_SRC+=$(navigation-service_SRC)/api/navigationcore/genivi-navigationcore-constants.xml
CONSTANTS_SRC+=$(navigation-service_SRC)/api/poi-service/genivi-poiservice-constants.xml
CONSTANTS_SRC+=$(navigation-service_SRC)/src/positioning/EnhancedPositionService/api/genivi-positioning-constants.xml

src-clean::
	rm -rf $(navigation-service_SRC) $(navigation-service_SRC)

help::
	@echo "poi-service: Build poi-service"
	@echo "navit-plugins: Build navit-plugins"

$(poi-service_SRC)/poi-server/poi-server.pro:
	cd $(navigation-service_SRC)/.. && git clone $(navigation-service_URL) $(navigation-service_SRC)
	cd $(navigation-service_SRC) && git checkout $(navigation-service_VERSION)

navigation-service-checkout: $(poi-service_SRC)/poi-server/poi-server.pro

$(poi-service_BIN)/Makefile: $(poi-service_SRC)/poi-server/poi-server.pro
	mkdir -p $(poi-service_BIN)
	cd $(poi-service_BIN) && $(QMAKE) $(poi-service_SRC)/poi-server/poi-server.pro

$(poi-common_BIN)/genivi-poiservice-constants.h: $(navigation-service_API)/poi-service/genivi-poiservice-constants.xml
	mkdir -p $(poi-common_BIN)
	$(poi-service_SRC)/script/generate-api.sh $(navigation-service_API) $(poi-common_BIN)

poi-service-configure: $(poi-service_BIN)/Makefile $(poi-common_BIN)/genivi-poiservice-constants.h

$(poi-service_BIN)/poi-server: $(poi-service_BIN)/Makefile $(poi-common_BIN)/genivi-poiservice-constants.h
	$(MAKE) -C $(poi-service_BIN)

$(poi-service_BIN)/empty.db:
	sqlite3 $(poi-service_BIN)/empty.db "create table empty (int int)"

poi-service: $(poi-service_BIN)/poi-server $(poi-service_BIN)/empty.db

navit-plugins mapviewer navigationcore deps::
	$(MAKE) BIN_DIR=$(BIN_DIR) poi-service_API=$(poi-service_API) layer_management_INST=$(layer_management_INST) -C $(navigation-service_SRC)/src/navigation/script $@