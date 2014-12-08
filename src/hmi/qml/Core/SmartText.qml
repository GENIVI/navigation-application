/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file SmartText.qml
*
* \brief This file is part of the navigation hmi.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \version
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 2.0

Text {
    style: Text.Sunken;
    wrapMode: Text.WordWrap
    elide: Text.ElideRight
    smooth: true
    clip: true
//    scale: paintedWidth > width ? (width / paintedWidth) : 1
}
