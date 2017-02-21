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
    property real w: (keyboard.width*Genivi.kbdRowRatio)/(Genivi.kbdRows*(1+Genivi.kbdRowRatio)-1);
    property real h: (keyboard.height*Genivi.kbdLineRatio)/(Genivi.kbdLines*(1+Genivi.kbdLineRatio)-1);
    property real wspc: w/Genivi.kbdRowRatio;
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

	function takeFocus(dir) {
		if (dir > 0) {
			key1.forceActiveFocus();
		} else {
			key32.forceActiveFocus();
		}
	}

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

	function shift(what) {
		shiftlevel=what;
		secondLayout="";
		var layouts={
            'ABC':['A','B','C','D','E','F','G','H',
			       'I','J','K','L','M','N','O','P',
			       'Q','R','S','T','U','V','W','X',
                   'Y','Z','␣','','abc','123','ÄÖÜ','←',
				],
			'abc':['a','b','c','d','e','f','g','h',
			       'i','j','k','l','m','n','o','p',
			       'q','r','s','t','u','v','w','x',
			       'y','z','␣','','ABC','123','äöü','←',
				],
			'ÄÖÜ':['Ä','Ö','Ü','ß','','','','',
			       '','','','','','','','',
			       '','','','','','','','',
			       '','','','','ABC','123','äöü','←',
				],
			'äöü':['ä','ö','ü','ß','','','','',
			       '','','','','','','','',
			       '','','','','','','','',
			       '','','','','abc','123','ÄÖÜ','←',
				],
			'123':['0','1','2','3','4','5','6','7',
			       '8','9','-','.',',','','','',
			       '','','','','','','','',
			       '','','','','','ABC','abc','←',
				],
		};
		var l=layouts[what];
		set(key1,l[0]);
		set(key2,l[1]);
		set(key3,l[2]);
		set(key4,l[3]);
		set(key5,l[4]);
		set(key6,l[5]);
		set(key7,l[6]);
		set(key8,l[7]);
		set(key9,l[8]);
		set(key10,l[9]);
		set(key11,l[10]);
		set(key12,l[11]);
		set(key13,l[12]);
		set(key14,l[13]);
		set(key15,l[14]);
		set(key16,l[15]);
		set(key17,l[16]);
		set(key18,l[17]);
		set(key19,l[18]);
		set(key20,l[19]);
		set(key21,l[20]);
		set(key22,l[21]);
		set(key23,l[22]);
		set(key24,l[23]);
		set(key25,l[24]);
		set(key26,l[25]);
		set(key27,l[26]);
		set(key28,l[27]);
		set(key29,l[28]);
		set(key30,l[29]);
		set(key31,l[30]);
		set(key32,l[31]);
	}

	Component.onCompleted: {
               if (destination.text.length && secondLayout) {
                       shift(secondLayout);
               } else {
                       shift(firstLayout);
		}
	}

	Column {
		spacing:keyboard.hspc
		Row {
			spacing:keyboard.wspc
			KButton { id:key1; next:key2; prev:keyboard.prev }
			KButton { id:key2; next:key3; prev:key1 }
			KButton { id:key3; next:key4; prev:key2 }
			KButton { id:key4; next:key5; prev:key3 }
			KButton { id:key5; next:key6; prev:key4 }
			KButton { id:key6; next:key7; prev:key5 }
			KButton { id:key7; next:key8; prev:key6 }
			KButton { id:key8; next:key9; prev:key7 }
		}
		Row {
			spacing:keyboard.wspc
			KButton { id:key9; next:key10; prev:key8 }
			KButton { id:key10; next:key11; prev:key9 }
			KButton { id:key11; next:key12; prev:key10 }
			KButton { id:key12; next:key13; prev:key11 }
			KButton { id:key13; next:key14; prev:key12 }
			KButton { id:key14; next:key15; prev:key13 }
			KButton { id:key15; next:key16; prev:key14 }
			KButton { id:key16; next:key17; prev:key15 }
		}
		Row {
			spacing:keyboard.wspc
			KButton { id:key17; next:key18; prev:key16 }
			KButton { id:key18; next:key19; prev:key17 }
			KButton { id:key19; next:key20; prev:key18 }
			KButton { id:key20; next:key21; prev:key19 }
			KButton { id:key21; next:key22; prev:key20 }
			KButton { id:key22; next:key23; prev:key21 }
			KButton { id:key23; next:key24; prev:key22 }
			KButton { id:key24; next:key25; prev:key23 }
		}
		Row {
			spacing:keyboard.wspc
			KButton { id:key25; next:key26; prev:key24 }
			KButton { id:key26; next:key27; prev:key25 }
			KButton { id:key27; next:key28; prev:key26 }
			KButton { id:key28; next:key29; prev:key27 }
			KButton { id:key29; next:key30; prev:key28 }
			KButton { id:key30; next:key31; prev:key29 }
			KButton { id:key31; next:key32; prev:key30 }
			KButton { id:key32; next:keyboard.next; prev:key31 }
		}
	}
}
