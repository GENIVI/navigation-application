# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file automotive-message-broker.mk
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
automotive-message-broker_URL="https://github.com/otcshare/automotive-message-broker.git"
automotive-message-broker_VERSION=ac3fe53327a13afc571efe079a31a0472ea285a3
automotive-message-broker_SRC=$(SRC_DIR)/automotive-message-broker_$(automotive-message-broker_VERSION)
automotive-message-broker_BIN=$(BIN_DIR)/automotive-message-broker
automotive-message-broker_DEPS+=cmake libboost-dev libjson0-dev libtool uuid-dev

DEPS+=$(automotive-message-broker_DEPS)
ALL+=automotive-message-broker

help::
	@echo "automotive-message-broker: Build automotive-message-broker"

src-clean::
	rm -rf $(automotive-message-broker_SRC)


$(automotive-message-broker_SRC)/CMakeLists.txt:
	cd $(automotive-message-broker_SRC)/.. && git clone $(automotive-message-broker_URL) $(automotive-message-broker_SRC)
	cd $(automotive-message-broker_SRC) && git checkout $(automotive-message-broker_VERSION)

automotive-message-broker-checkout: $(automotive-message-broker_SRC)/CMakeLists.txt

$(automotive-message-broker_SRC)/.patched: $(automotive-message-broker_SRC)/CMakeLists.txt
	patch -d $(automotive-message-broker_SRC) -p1 -s <$(PATCH_DIR)/amb_allow_sessionbus.patch
	touch $(automotive-message-broker_SRC)/.patched

automotive-message-broker-patch: $(automotive-message-broker_SRC)/.patched

$(automotive-message-broker_BIN)/Makefile: $(automotive-message-broker_SRC)/.patched
	mkdir -p $(automotive-message-broker_BIN)
	cd $(automotive-message-broker_BIN) && cmake $(automotive-message-broker_SRC)

automotive-message-broker-configure: $(automotive-message-broker_BIN)/Makefile

$(automotive-message-broker_BIN)/ambd/ambd: $(automotive-message-broker_BIN)/Makefile
	make -C $(automotive-message-broker_BIN)

automotive-message-broker: $(automotive-message-broker_BIN)/ambd/ambd
