/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file Keyboard.qml
*
* \brief This file is part of the navigation hmi.
*
* \author Martin Schaller <martin.schaller@it-schaller.de>
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
import QtQuick 2.1 
import "genivi.js" as Genivi;

Item {
	id: keyboard;
    property real w: (keyboard.width*Genivi.kbdColumnRatio)/(Genivi.kbdColumns*(1+Genivi.kbdColumnRatio)-1);
    property real h: (keyboard.height*Genivi.kbdLineRatio)/(Genivi.kbdLines*(1+Genivi.kbdLineRatio)-1);
    property real wspc: w/Genivi.kbdColumnRatio;
    property real hspc: h/Genivi.kbdLineRatio;
    property Item destination;
	property Item layout;
	property string firstLayout;
	property string secondLayout: null;
	property Item next;
	property Item prev;
	property string activekeys;
	property bool activekeys_enabled;
	property string shiftlevel;
	signal keypress(string what);
    property var buttonList:[];

	function keytext(what)
	{
		if (what == '␣') {
			return ' ';
		}
		if (what == '←') {
			return '\b';
		}
		return what;
	}

	function append(what) {
		what=keytext(what);
		if (what.length > 1) {
			shift(what);
			return;
		}
		if (secondLayout && !destination.text.length) {
			shift(secondLayout);
		}
		keypress(what);
		if (what == '\b') {
			backspace();
		} else {
			destination.text+=what;
		}
	}

	function backspace() {
		if (destination.text.length) {
			destination.text=destination.text.slice(0,-1);
			if (secondLayout && !destination.text.length) {
				shift(firstLayout);
			}
		}
	}

	function set(id,text)
	{
		id.text=text;
		var stext=keytext(text.toLowerCase());
		var disabled=true;
		if (text.length) {
			if (!activekeys_enabled || text.length > 1 || activekeys.indexOf(stext) != -1) 
				disabled=false;
			if (stext == '\b' && !destination.text.length)
				disabled=true;
		}
		id.disabled=disabled;
	}

	function setactivekeys(keys,enabled)
	{
		activekeys=keys.toLowerCase();
		activekeys_enabled=enabled;
		shift(shiftlevel);
	}

    function activateAllKeys()
    {
        var keys;
        keys='\b'+'␣'+"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        if(Genivi.g_language ==="eng"){
        }else{
            if(Genivi.g_language==="fra"){
            }else{
                if(Genivi.g_language==="jpn"){
                    keys+="あかさたなはまやらわいきしちにひみりをうくすつぬふむゆるんえけせてねへめれ”おこそとのほもよろ°";
                }else{
                    if(Genivi.g_language==="deu"){
                    }
                }
            }
        }
        setactivekeys(keys,true);
    }

	function shift(what) {
		shiftlevel=what;
		secondLayout="";
        var l=Genivi.keyboardLayout[what];
        for(var i=0;i<buttonList.length;i++){
            set(buttonList[i],l[i])
        }
	}

	Column {
        id:keyboardFrame
		spacing:keyboard.hspc
        Component.onCompleted: {
            var index=0;
            for(var i=0;i<Genivi.kbdLines;i++){
                var row=Qt.createQmlObject('import QtQuick 2.1 ; Row {}',keyboardFrame,'dynamic');
                row.spacing=keyboard.wspc;
                for(var j=0;j<Genivi.kbdColumns;j++){
                    buttonList[index] =Qt.createQmlObject('import QtQuick 2.1 ; KButton {}',row,'dynamic');
                    index++;
                }
            }
        }
	}

    Component.onCompleted: {
        if (destination.text.length && secondLayout) {
               shift(secondLayout);
        } else {
               shift(firstLayout);
        }
    }
}
