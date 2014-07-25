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
# 16/06/2014, Philippe Colliot, Migration to Qt5.2
# 16/07/2014, Philippe Colliot, hmi into an application launcher
# 25/07/2014, Philippe Colliot, update dependencies list
#
# @licence end@
HMI_SRC=$(SRC_DIR)/hmi/qml/hmi-launcher
HMI_BIN=$(BIN_DIR)/hmi/qml
HMI_DEPS=qtdeclarative5-quicklayouts-plugin qtdeclarative5-dialogs-plugin qtdeclarative5-controls-plugin qtdeclarative5-qtquick2-plugin qtdeclarative5-window-plugin libqt5declarative5

DEPS += $(HMI_DEPS)
hmi: $(HMI_BIN)/Makefile $(HMI_BIN)/constants.js
	$(MAKE) -C $(HMI_BIN)

$(HMI_BIN)/Makefile: $(HMI_SRC)/hmi-launcher.pro
	mkdir -p $(HMI_BIN)
	cd $(HMI_BIN) && $(QMAKE) $(HMI_SRC)/hmi-launcher.pro

ALL += hmi

$(HMI_BIN)/constants.js: $(HMI_SRC)/javascript.xsl $(CONSTANTS_SRC)
	for i in $(CONSTANTS_SRC); do xsltproc $(HMI_SRC)/javascript.xsl $$i || exit ; done >$(HMI_BIN)/constants.js

help::
	@echo "hmi: Build hmi"
