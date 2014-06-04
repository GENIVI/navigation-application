# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file layer_management.mk
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
# layer_management_URL=https://git.genivi.org/srv/git/layer_management
# layer_management_VERSION=ec56d1114fa3ad8d28a8415e85b4c0093dea12f4

LAYER_MANAGEMENT=0
ifneq ($(LAYER_MANAGEMENT),0)
layer_management_URL=http://git.projects.genivi.org/layer_management.git
layer_management_VERSION=d3927a6ae5e6c9230d55b6ba4195d434586521c1
layer_management_SRC=$(SRC_DIR)/layer_management_$(layer_management_VERSION)
layer_management_BIN=$(BIN_DIR)/layer_management
layer_management_INST=$(layer_management_BIN)/inst/usr/local

ALL+=layer_management
SRC_CLEAN+=clean-layer_management_SRC

help::
	@echo "layer_management: Build layer_management"

clean-layer_management_SRC::
	rm -rf $(layer_management_SRC)


$(layer_management_SRC)/CMakeLists.txt:
	cd $(layer_management_SRC)/.. && git clone $(layer_management_URL) $(layer_management_SRC)
	cd $(layer_management_SRC) && git checkout $(layer_management_VERSION)

layer_management-checkout: $(layer_management_SRC)/CMakeLists.txt

$(layer_management_SRC)/.patched: $(layer_management_SRC)/CMakeLists.txt
	# patch -d $(layer_management_SRC) -p1 -s <$(PATCH_DIR)/layer_management_cast_fix.patch
	touch $(layer_management_SRC)/.patched

layer_management-patch: $(layer_management_SRC)/.patched

$(layer_management_BIN)/Makefile: $(layer_management_SRC)/CMakeLists.txt $(layer_management_SRC)/.patched
	mkdir -p $(layer_management_BIN)
	cd $(layer_management_BIN) && cmake -DWITH_DESKTOP=ON -DWITH_X11_GLES=OFF -DWITH_INPUT_EVENTS=ON -DWITH_FORCE_COPY=ON -DWITH_EGL_EXAMPLE=OFF $(layer_management_SRC)

layer_management-configure: $(layer_management_BIN)/Makefile

$(layer_management_BIN)/inst: $(layer_management_BIN)/Makefile
	cd $(layer_management_BIN) && make && make DESTDIR=inst install

layer_management: $(layer_management_BIN)/inst
endif
