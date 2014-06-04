# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file hmi.mk
#
# \brief This file is part of the Build System.
#
# \author Martin Schaller <martin.schaller@it-schaller.de>
#
# \version 1.1
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
# 04/06/2014, Philippe Colliot, Migration to Qt5.2
#
# @licence end@
TESTHMI_SRC=$(SRC_DIR)/hmi/qml
TESTHMI_BIN=$(BIN_DIR)/hmi/qml
TESTHMI_DEPS=qt4-qmlviewer libqt5dbus5 libqt5core5a libqt5gui5 qtscript5-dev 

DEPS += $(TESTHMI_DEPS)
testhmi: $(TESTHMI_BIN)/Makefile $(TESTHMI_BIN)/constants.js
	$(MAKE) -C $(TESTHMI_BIN)

$(TESTHMI_BIN)/Makefile: $(TESTHMI_SRC)/all.pro $(TESTHMI_SRC)/dbus.pro $(TESTHMI_SRC)/wheelarea.pro
	mkdir -p $(TESTHMI_BIN)
	cd $(TESTHMI_BIN) && $(QMAKE) $(TESTHMI_SRC)/all.pro

ALL += testhmi

$(TESTHMI_BIN)/constants.js: $(TESTHMI_SRC)/javascript.xsl $(CONSTANTS_SRC)
	for i in $(CONSTANTS_SRC); do xsltproc $(TESTHMI_SRC)/javascript.xsl $$i || exit ; done >$(TESTHMI_BIN)/constants.js

help::
	@echo "testhmi: Build testhmi"
