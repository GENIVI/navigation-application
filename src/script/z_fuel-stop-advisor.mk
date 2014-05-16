# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file fuel-stop-advisor.mk
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
fuel-stop-advisor_SRC=$(SRC_DIR)/fuel-stop-advisor
fuel-stop-advisor_BIN=$(BIN_DIR)/fuel-stop-advisor

ALL+=fuel-stop-advisor
CONSTANTS_SRC+=$(fuel-stop-advisor_SRC)/constants.xml

help::
	@echo "fuel-stop-advisor: Build fuel-stop-advisor"

$(fuel-stop-advisor_BIN)/Makefile: $(fuel-stop-advisor_SRC)/CMakeLists.txt navigation-service-checkout
	mkdir -p $(fuel-stop-advisor_BIN)
	cd $(fuel-stop-advisor_BIN) && cmake -Dgenivi-navigationcore-routing_API=$(navigation-service_API)/navigation-core/genivi-navigationcore-routing.xml -Dgenivi-navigationcore-constants_API=$(navigation-service_API)/navigation-core/genivi-navigationcore-constants.xml $(fuel-stop-advisor_SRC)

$(fuel-stop-advisor_BIN)/fuel-stop-advisor: $(fuel-stop-advisor_BIN)/Makefile
	$(MAKE) -C $(fuel-stop-advisor_BIN)
	
fuel-stop-advisor: $(fuel-stop-advisor_BIN)/fuel-stop-advisor
