<?xml version="1.0" encoding="UTF-8"?>
<!--
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file javascript.xsl
*
* \brief This file is part of the FSA HMI.
*
* \author * Author: Martin Schaller <martin.schaller@it-schaller.de>
*
* \version 1.0
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
* 
* <date>, <name>, <description of change>
*
* @licence end@
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="1.0">
	<xsl:output method="text" encoding="iso-8859-15"/>
	<xsl:template match="constants">
		<xsl:variable name="constants" select="translate(@name,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
/* This is an automatically generated file, do not edit */

<xsl:for-each select="id">
var <xsl:value-of select="$constants"/>_<xsl:value-of select="translate(@name,'-','_')"/> = <xsl:value-of select="@value"/>;</xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
