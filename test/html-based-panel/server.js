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
var python_shell = require('python-shell');
var Enum = require('enum');

// Configuration of the python script for simulating log replayer data
var python_script_enum = new Enum({'START': 1, 'INITIALIZATION': 2, 'HIGH_TANK_LEVEL': 3, 'LOW_TANK_LEVEL': 4});
var python_script_options = {
  mode: 'text',
  pythonPath: '/usr/bin/python3',
  pythonOptions: ['-u'],
  scriptPath: '../script',
  args: [python_script_enum.get('START').key]
};

// Requirements of LBS add-on modules
var positioningEnhancedPositionWrapper = require(resource.generatedNodejsModulePath+'/PositioningEnhancedPositionWrapper');
var fuelStopAdvisorWrapper = require(resource.generatedNodejsModulePath+'/FuelStopAdvisorWrapper');
var navigationCoreWrapper = require(resource.generatedNodejsModulePath+'/NavigationCoreWrapper');

// Create instances
var i_positioningEnhancedPositionWrapper = new positioningEnhancedPositionWrapper.PositioningEnhancedPositionWrapper();
var i_fuelStopAdvisorWrapper = new fuelStopAdvisorWrapper.FuelStopAdvisorWrapper();
var i_navigationCoreWrapper = new navigationCoreWrapper.NavigationCoreWrapper();

var poll = 0;
// Scan arguments if exists
if (process.argv[2] === 'poll'){
    poll = 1;
    console.log('Polling activated, no signal used');
    if (process.argv[3] === 'silent'){
        // Silentize console
        console.log('Silent mode now');
        console.log = function() {
        }
    }
} else {
    if (process.argv[2] === 'silent'){
        // Silentize console
        console.log('Silent mode now');
        console.log = function() {
        }
    }
}


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

// Manage sockets
var socket_simulation_get = io.of('/simulation_get');
var socket_simulation_signal = io.of('/simulation_signal');
var socket_simulation_warning = io.of('/simulation_warning');

// signals
function guidanceStatusChanged(changedValues) {
    console.log('guidanceStatusChanged: ' + changedValues);
    if(!poll) { socket_simulation_signal.emit('navigationcore_signal', {signal: 'guidanceStatusChanged', data: changedValues});}
}
var setGuidanceStatusChangedListener = i_navigationCoreWrapper.setGuidanceStatusChangedListener(guidanceStatusChanged);
function positionUpdate(changedValues) {
    console.log('positionUpdate: ' + changedValues);
    if(!poll) { socket_simulation_signal.emit('positioning_signal', {signal: 'positionUpdate', data: changedValues});}
}
var setPositionUpdateListener = i_positioningEnhancedPositionWrapper.setPositionUpdateListener(positionUpdate);
function tripDataUpdated(changedValues) {
    console.log('tripDataUpdated: ' + changedValues);
    if(!poll) { socket_simulation_signal.emit('demonstrator_signal', {signal: 'tripDataUpdated', data: changedValues});}
}
var setTripDataUpdatedListener = i_fuelStopAdvisorWrapper.setTripDataUpdatedListener(tripDataUpdated);
function fuelStopAdvisorWarning(changedValues) {
    console.log('fuelStopAdvisorWarning: ' + changedValues);
    if(!poll) { socket_simulation_signal.emit('demonstrator_signal', {signal: 'fuelStopAdvisorWarning', data: changedValues});}
}
var setFuelStopAdvisorWarningListener = i_fuelStopAdvisorWrapper.setFuelStopAdvisorWarningListener(fuelStopAdvisorWarning);
function tripDataResetted(changedValues) {
    console.log('tripDataResetted: ' + changedValues);
    if(!poll) { socket_simulation_signal.emit('demonstrator_signal', {signal: 'tripDataResetted', data: changedValues});}
}
var setTripDataResettedListener = i_fuelStopAdvisorWrapper.setTripDataResettedListener(tripDataResetted);

// Start the gmainloop (to be done after the initialisation of listeners !
gcontext.init();

// connection
socket_simulation_get.on('connection', function (client) {
    console.log('Socket simulation started');
    client.on('navigationcore_request', function (message) {
        switch(message.interface) {
        case "NavigationCoreGuidance":
            console.log('Message received: Interface-->' + message.interface +' Method-->', message.method +' Parameters-->' + message.parameters);
            if (message.method in i_navigationCoreWrapper && typeof i_navigationCoreWrapper[message.method] === "function") {
                var data = i_navigationCoreWrapper[message.method](message.parameters);
                if(data) {
                    client.emit('navigationcore_answer', {request: message.method, answer: data});
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
                socket_simulation_warning.emit('feedback', "Could not find " + message.method + " function");
            }
            break;
        default:
            console.log("Could not find " + message.interface);
            socket_simulation_warning.emit('feedback', "Could not find " + message.interface);
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
                socket_simulation_warning.emit('feedback', "Could not find " + message.method + " function");
            }
            break;
        default:
            console.log("Could not find " + message.interface);
            socket_simulation_warning.emit('feedback', "Could not find " + message.interface);
        }
    });
    client.on('panel_request', function (message) {
        switch(message.request) {
        case "LogReplayerScenario":
            console.log('Message received: Request-->', message.request +' Parameters-->' + message.parameters);
            python_script_options.args = [message.parameters];
            break;
        default:
            console.log("Could not find " + message.interface);
            socket_simulation_warning.emit('feedback', "Could not find " + message.interface);
        }
    });
});

// Timer
setInterval(function(){
    python_shell.run('simulation-launch.py', python_script_options, function (err, results) {
        if (err) throw err;
//        console.log('results: %j', results);
        });
    if(poll) {
        socket_simulation_signal.emit('positioning_signal', {signal: 'positionUpdate', data: 0});
        socket_simulation_signal.emit('demonstrator_signal', {signal: 'tripDataUpdated', data: 0});
       socket_simulation_signal.emit('navigationcore_signal', {signal: 'guidanceStatusChanged', data: 0});
    }
}, 1000);

// Log info
console.log('Server listening at: %s', server.address().port);

