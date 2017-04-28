#!/usr/bin/env python
# -*- coding: utf-8 -*-

# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file generate-style-sheet.py
#
# \brief This file is a script to generate the style sheet of the navigation hmi.
#
# \author Philippe Colliot <philippe.colliot@mpsa.com>
# \version 1.0
#
# Thanks to Michel Ardan, Saul Goode for hints I found into their code :-)
#
# This Source Code Form is subject to the terms of the
# Mozilla Public License (MPL), v. 2.0.
# If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# For further information see http://www.genivi.org/.
#
# List of changes:
# 17-7-2014, philippe colliot, fix rgba bug for migration to Qt 5
# 22-8-2014, philippe colliot, clean up obsolete banner
# <date>, <name>, <description of change>
#
# @licence end@


import os, glob
import xml.dom
import xml.dom.minidom
import string
from gimpfu import *
from gimpenums import *

image_path = "../images/"

def format_color(color) :
	return "Qt.rgba(%.2f, %.2f, %.2f, %.2f)" % (color[0]/255.0,color[1]/255.0,color[2]/255.0,color[3]/255.0)

def get_js_header():
	header = ['/* This file is generated */','.pragma library','Qt.include("style-constants.js");','']
	return header

def generate_style_image_layer(layer):
	layer_name=layer.name
	return_list = []
	# format name for the object (replace - with _ ), dash is prohibited in qml
	object_name = string.replace(layer_name, '-', '_')
	str = 'var '+object_name+'=new Object;'
	return_list.append(str)
	str = object_name+'[SOURCE]='+'"'+image_path+layer_name+'.png'+'"'+';'
	return_list.append(str) 
	str = object_name+'[X]='+"%d"%layer.offsets[0]+';'
	return_list.append(str) 
	y_coordinate = layer.offsets[1]
	str = object_name+'[Y]='+"%d"%y_coordinate+';'
	return_list.append(str) 
	str = object_name+'[WIDTH]='+"%d"%layer.width+';'
	return_list.append(str) 
	str = object_name+'[HEIGHT]='+"%d"%layer.height+';'
	return_list.append(str) 
	str = ''
	return_list.append(str)
	return return_list

def generate_style_text_layer(layer):
	object_name=layer.name
	return_list = []
	# format name for the object (replace - with _ ), dash is prohibited in qml
	object_name = string.replace(object_name, '-', '_')
	str = 'var '+object_name+'=new Object;'
	return_list.append(str)
	str = object_name+'[X]='+"%d"%layer.offsets[0]+';'
	return_list.append(str) 
	y_coordinate = layer.offsets[1]
	str = object_name+'[Y]='+"%d"%y_coordinate+';'
	return_list.append(str) 
	str = object_name+'[WIDTH]='+"%d"%layer.width+';'
	return_list.append(str) 
	str = object_name+'[HEIGHT]='+"%d"%layer.height+';'
	return_list.append(str) 
	text_color = pdb.gimp_text_layer_get_color(layer)
	str = object_name+'[TEXTCOLOR]='+format_color(text_color)+';'
	return_list.append(str) 
	str = object_name+'[STYLECOLOR]='+format_color(text_color)+';'
	return_list.append(str) 
	pixel_size = pdb.gimp_text_layer_get_font_size(layer)[0]
	str = object_name+'[PIXELSIZE]='+"%d"%pixel_size+';'
	return_list.append(str) 
	str = ''
	return_list.append(str)
	return return_list
    
def generate_style_sheet(image, drawable, select_visible_layers, target_directory, generate_xml_log) :
	# transmit error messages to gimp console
	gimp.pdb.gimp_message_set_handler( ERROR_CONSOLE )
	sc_js_data = []
	layers = image.layers
	sc_name = target_directory+os.sep+'style-sheets'+os.sep+image.name;
	sc_name = string.replace(sc_name, '.xcf', '')

	if (generate_xml_log):
		#configure the XML document
		sc_xml_name = sc_name+'-css.xml'
		doc = xml.dom.minidom.Document()
		url = ""
		rootelt = doc.createElementNS(url, "layoutBuilder")
		doc.appendChild(rootelt)
    
	#configure the JS document
	sc_js_name = sc_name+'-css.js'
	sc_js_data.extend(get_js_header())
   
	#scan the layers
	for l in layers:
		if (select_visible_layers):
			if (l.visible):
				if pdb.gimp_item_is_text_layer(l):
					#generate data for the text object
					sc_js_data.extend(generate_style_text_layer(l))
				else:
					#generate data for the image object
					sc_js_data.extend(generate_style_image_layer(l))
					#generate and save the image file
					ly_name = target_directory+os.sep+'images'+os.sep+ l.name + ".png"
					gimp.pdb.gimp_file_save(image, l, ly_name, ly_name)   
		else:
			if pdb.gimp_item_is_text_layer(l):
				#generate data for the text object
				sc_js_data.extend(generate_style_text_layer(l))
			else:
				#generate data for the image object
				sc_js_data.extend(generate_style_image_layer(l))
				#generate the image file
				ly_name = target_directory+os.sep + l.name + ".png"
				gimp.pdb.gimp_file_save(image, l, ly_name, ly_name)   
		if (generate_xml_log):
			if (select_visible_layers):
				if (l.visible):
					# populate the xml file (it's a log file)
					xmlnode = doc.createElementNS(url, "layer")
					xmlnode.setAttributeNS(url, "x", "%d"%l.offsets[0])
					xmlnode.setAttributeNS(url, "y", "%d"%l.offsets[1])
					xmlnode.setAttributeNS(url, "width", "%d"%l.width)
					xmlnode.setAttributeNS(url, "height", "%d"%l.height)
					xmltext = doc.createTextNode(l.name);
					xmlnode.appendChild(xmltext)
					rootelt.appendChild(xmlnode)
			else:
				 # populate the xml file (it's a log file)
				xmlnode = doc.createElementNS(url, "layer")
				xmlnode.setAttributeNS(url, "x", "%d"%l.offsets[0])
				xmlnode.setAttributeNS(url, "y", "%d"%l.offsets[1])
				xmlnode.setAttributeNS(url, "width", "%d"%l.width)
				xmlnode.setAttributeNS(url, "height", "%d"%l.height)
				xmltext = doc.createTextNode(l.name);
				xmlnode.appendChild(xmltext)
				rootelt.appendChild(xmlnode)       
 
	gimp.pdb.gimp_message( "Saving images to %s"%(target_directory+os.sep+'images'+os.sep) );

	if (generate_xml_log):
		#save the xml file
		gimp.pdb.gimp_message( "Saving log to %s"%(sc_xml_name) );
		file_object = open(sc_xml_name, "w")
		file_object.write(doc.toprettyxml());
		file_object.close()

	#save the JS file
	gimp.pdb.gimp_message( "Saving style sheet to %s"%(sc_js_name) );
	file_object = open(sc_js_name, "w")
	for item in sc_js_data:
		file_object.write("%s\n" %item)
	file_object.close()

register(
    "generate-style-sheet",
    "Generation of style sheet",
    "Export images and content properties from layers",
    "Philippe COLLIOT",
    "PSA Peugeot Citroën",
    "2014",
    "<Image>/Genivi/Generate style sheet",
    "*",
    [
      (PF_TOGGLE, "select_visible_layers_toggle", "Save only visible layers", True),
      (PF_DIRNAME, "target_directory_name", "Target directory (must be qml/Core)", os.getcwd()),
      (PF_TOGGLE, "generate_xml_log_toggle", "Generate xml log file", False),
    ],
    [],
    generate_style_sheet )

main()
