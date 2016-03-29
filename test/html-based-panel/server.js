/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2016, PCA Peugeot Citroen
*
* \file main.cpp
*
* \brief This file is part of the Navigation Web API proof of concept.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \version 0.1
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
// Requirement of external JS files
var resource = require('./js/resource.js');

// Requirements of nodejs modules
var http = require('http');
var url = require('url');
var fs = require('fs');
var path = require('path');
var gcontext = require('gcontext');

// Requirements of LBS add-on modules
var positioningEnhancedPositionWrapper = require(resource.generatedNodejsModulePath+'/PositioningEnhancedPositionWrapper');
var fuelStopAdvisorWrapper = require(resource.generatedNodejsModulePath+'/FuelStopAdvisorWrapper');

// Create instances
var i_positioningEnhancedPositionWrapper = new positioningEnhancedPositionWrapper.PositioningEnhancedPositionWrapper();
var i_fuelStopAdvisorWrapper = new fuelStopAdvisorWrapper.FuelStopAdvisorWrapper();

// Create and init server
var port = 8080;
var hostname = '127.0.0.1';
var server = http.createServer(function(req, res) {
	var page = url.parse(req.url).pathname;
	var full_path = path.join(process.cwd(),page);
	// Check if page exists (for the moment only index.html)
	fs.exists(full_path,function(exists){
        if(!exists){
            res.writeHeader(404, {"Content-Type": "text/plain"}); 
            res.write("404 Not Found\n"); 
            res.end();
        }
        else{
			fs.readFile(full_path, "binary", function(err, file) { 
				 if(err) { 
				     res.writeHeader(500, {"Content-Type": "text/plain"}); 
				     res.write(err + "\n"); 
				     res.end(); 
				
				 } 
				 else{
				    res.writeHeader(200); 
				    res.write(file, "binary"); 
				    res.end();
				}
			});
		}
	});
});

// Launch server
server.listen(port); 

// Load socket.io and connect it to the server
var io = require('socket.io').listen(server);

// Manage socket for the namespace /simulation
var socket_simulation = io.of('/simulation');
// signals
function positionUpdate(changedValues) {
    console.log('positionUpdate: ' + changedValues);
    socket_simulation.emit('positioning_signal', {signal: 'positionUpdate', data: changedValues});
}
var setPositionUpdateListener = i_positioningEnhancedPositionWrapper.setPositionUpdateListener(positionUpdate);
function tripDataUpdated(changedValues) {
    console.log('tripDataUpdated: ' + changedValues);
    socket_simulation.emit('demonstrator_signal', {signal: 'tripDataUpdated', data: changedValues});
}
var setTripDataUpdatedListener = i_fuelStopAdvisorWrapper.setTripDataUpdatedListener(tripDataUpdated);
function fuelStopAdvisorWarning(changedValues) {
    console.log('fuelStopAdvisorWarning: ' + changedValues);
    socket_simulation.emit('demonstrator_signal', {signal: 'fuelStopAdvisorWarning', data: changedValues});
}
var setFuelStopAdvisorWarningListener = i_fuelStopAdvisorWrapper.setFuelStopAdvisorWarningListener(fuelStopAdvisorWarning);
function tripDataResetted(changedValues) {
    console.log('tripDataResetted: ' + changedValues);
    socket_simulation.emit('demonstrator_signal', {signal: 'tripDataResetted', data: changedValues});
}
var setTripDataResettedListener = i_fuelStopAdvisorWrapper.setTripDataResettedListener(tripDataResetted);

// Start the gmainloop (to be done after the initialisation of listeners !
gcontext.init();

// connection
socket_simulation.on('connection', function (client) {
    console.log('Client connected');
    client.on('positioning_request', function (message) {
        switch(message.interface) {
        case "PositioningEnhancedPosition":
            console.log('Message received: Interface-->' + message.interface +' Method-->', message.method +' Parameters-->' + message.parameters);
            if (message.method in i_positioningEnhancedPositionWrapper && typeof i_positioningEnhancedPositionWrapper[message.method] === "function") {
                var data = i_positioningEnhancedPositionWrapper[message.method](message.parameters);
                if(data) {
                    client.emit('positioning_answer', {request: message.method, answer: data});
                }
            }
            else {
                console.log("Could not find " + message.method + " function");
                client.emit('feedback', "Could not find " + message.method + " function");
            }
            break;
        default:
            console.log("Could not find " + message.interface);
            client.emit('feedback', "Could not find " + message.interface);
        }
    });
    client.on('demonstrator_request', function (message) {
        switch(message.interface) {
        case "FuelStopAdvisor":
            console.log('Message received: Interface-->' + message.interface +' Method-->', message.method +' Parameters-->' + message.parameters);
            if (message.method in i_fuelStopAdvisorWrapper && typeof i_fuelStopAdvisorWrapper[message.method] === "function") {
                var data = i_fuelStopAdvisorWrapper[message.method](message.parameters);
                if(data) {
                    console.log('data' + data);
                    client.emit('demonstrator_answer', {request: message.method, answer: data});
                }
            }
            else {
                console.log("Could not find " + message.method + " function");
                client.emit('feedback', "Could not find " + message.method + " function");
            }
            break;
        default:
            console.log("Could not find " + message.interface);
            client.emit('feedback', "Could not find " + message.interface);
        }
    });
});

// Timer
setInterval(function(){
//console.log('tick');
}, 1000);

// Log info
console.log('Server listening at: %s', server.address().port);

