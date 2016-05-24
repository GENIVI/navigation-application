# How to generate a new style sheet

## Synopsis
The HMI of FSA is generated from the Gimp files, by using a python script. It allows to quickly relook the HMI.

## Important notice
Please don't change the layer names of the xcf files, the qml content is based on it
Gimp version tested: 2.8

## To load the script in python:
exit Gimp
sudo cp generate-style-sheet.py /usr/lib/gimp/2.0/plug-ins
sudo chmod +x /usr/lib/gimp/2.0/plug-ins/generate-style-sheet.py

## To create the style sheets
Without the batch (from Gimp):
To generate a style sheet and the images:
launch Gimp
Genivi/Generate style sheet
Choose the target (must be qml/Core)
Press OK

With the batch (Gimp not launched):
Use ./prepare.sh
Usage: prepare -i input_directory
       prepare -c clean images and style sheets





