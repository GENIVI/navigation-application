Preliminary code for testing the implementation of a set of navigation Web API based on GENIVI API 
Technology used: nodejs

To get a given version of nodejs (e.g. 0.12):
curl -sL https://deb.nodesource.com/setup_0.12 | sudo -E bash
sudo apt-get install -y nodejs
NB: not supported by my trusty :-(

For the time being, version is v0.10.25:
sudo apt-get install nodejs npm
npm install -g node-gyp

To build the c++ add-on in C++ and install the module localy for nodejs:
cd ./node-cpp-lbs-modules 
npm build .
npm pack
cd ..
npm install node-cpp-lbs-modules/node-cpp-lbs-modules-0.1.0.tgz

To test:
Intall additional modules for nodejs:
npm install http url fs path socket.io

Run the server:

nodejs server.js

In your browser open the file ./index.html

Annex:
To debug the C++ add-on:
cd ./node-cpp-lbs-modules 
node-gyp configure --debug
node-gyp build --debug
npm pack
cd ..
npm install node-cpp-lbs-modules/node-cpp-lbs-modules-0.1.0.tgz
To see where the issue is in the js file:
nodejs debug server.js
To debug the c++ addon:
gdb --args /usr/bin/nodejs server.js
