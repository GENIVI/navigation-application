# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file log-replayer.mk
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
log-replayer_SRC=$(SRC_DIR)/log-replayer
log-replayer_BIN=$(BIN_DIR)/log-replayer

ALL+=log-replayer

help::
	@echo "log-replayer: Build log-replayer"

$(log-replayer_BIN)/Makefile: $(log-replayer_SRC)/CMakeLists.txt
	mkdir -p $(log-replayer_BIN)
	cd $(log-replayer_BIN) && cmake $(log-replayer_SRC)

$(log-replayer_BIN)/log-replayer: $(log-replayer_BIN)/Makefile
	$(MAKE) -C $(log-replayer_BIN)
	
log-replayer: $(log-replayer_BIN)/log-replayer
