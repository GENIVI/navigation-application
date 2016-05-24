# HTML based interface to test the FSA

## Synopsis
This folder contains the HTML version of the test panel

##Tested targets
Desktop: Tested under Ubuntu 16.04 LTS 64 bits

## Prerequisites
nodejs version is v4.2.6

Some additional modules are required for nodejs:
npm install http url fs path socket.io gcontext python-shell enum

## How to build
To build the c++ add-on in C++ and install the module localy for nodejs:
cd ./node-cpp-lbs-modules 
make
cd ..
npm install node-cpp-lbs-modules/node-cpp-lbs-modules-0.1.0.tgz

## How to test
Run the server:

nodejs server.js

In your browser open the file ./index.html

