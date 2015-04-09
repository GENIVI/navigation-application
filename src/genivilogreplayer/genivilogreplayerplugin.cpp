#include "genivilogreplayerplugin.h"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <boost/assert.hpp>
#include <boost/lexical_cast.hpp>

#include <listplusplus.h>

using namespace std;

#ifndef DLT
#include "debugout.h"
#else
#include "log.h"
DLT_DECLARE_CONTEXT(gContext);
#endif

#define BUFLEN 256
#define PORT 9932

const char* id = "326011dd-65cd-4be6-a75e-3e8d46a05510";

void *updatePropertiesThread(gpointer data)
{
    GeniviLogReplayerPlugin* src = (GeniviLogReplayerPlugin*)data;
    src->updateProperties();
}


GeniviLogReplayerPlugin::GeniviLogReplayerPlugin(AbstractRoutingEngine* re, map<string, string> config)
	:AbstractSource(re, config)
{
    // properties managed by this plugin
    addPropertySupport(VehicleProperty::EngineSpeed, Zone::None);
    addPropertySupport(VehicleProperty::FuelLevel, Zone::None);
    addPropertySupport(VehicleProperty::FuelConsumption, Zone::None);
    addPropertySupport(VehicleProperty::Odometer, Zone::None);

    // Main loop to receive data
    statusRunning = true;
    thread = g_thread_create((GThreadFunc)updatePropertiesThread, this, FALSE, NULL);
}

GeniviLogReplayerPlugin::~GeniviLogReplayerPlugin()
{
    // stop the main loop and wait for the end of thread
    statusRunning = false;
    g_thread_join(thread);
}

extern "C" AbstractSource * create(AbstractRoutingEngine* routingengine, map<string, string> config)
{
	return new GeniviLogReplayerPlugin(routingengine, config);
}


const string GeniviLogReplayerPlugin::uuid()
{
    return id;
}


void GeniviLogReplayerPlugin::getPropertyAsync(AsyncPropertyReply *reply)
{
#ifdef  DLT
    LOG_DEBUG(gContext,"GeniviLogReplayer: getPropertyAsync %s", reply->property);
#else
    DebugOut(0)<<"GeniviLogReplayer: getPropertyAsync "<<reply->property<<endl;
#endif

    if(contains(mSupported,reply->property))
    {
       // retrieve the value
        if(reply->property == VehicleProperty::EngineSpeed)
        {
            reply->value = &enginespeed;
        }
        else if(reply->property == VehicleProperty::FuelLevel)
        {
            reply->value = &fuellevel;
        }
        else if(reply->property == VehicleProperty::FuelConsumption)
        {
            reply->value = &fuelcons;
        }
        else if(reply->property == VehicleProperty::Odometer)
        {
            reply->value = &odometer;
        }
        reply->success = true;
    }
    else  // your property request is not supported
	{
		reply->value = NULL;
		reply->success = false;
        reply->error = AsyncPropertyReply::InvalidOperation;
	}
    reply->completed(reply);
}

void GeniviLogReplayerPlugin::getRangePropertyAsync(AsyncRangePropertyReply *reply)
{
	throw std::runtime_error("GeniviLogReplayerPlugin does not support this operation.  We should never hit this method.");
}

AsyncPropertyReply *GeniviLogReplayerPlugin::setProperty(AsyncSetPropertyRequest request )
{
    throw std::runtime_error("GeniviLogReplayerPlugin does not support this operation (only a receiver).");
}

void GeniviLogReplayerPlugin::subscribeToPropertyChanges(VehicleProperty::Property property)
{
#ifdef  DLT
    LOG_DEBUG(gContext,"GeniviLogReplayer: subscribeToPropertyChanges %s", property);
#else
    DebugOut(0)<<"GeniviLogReplayer: getPropertyAsync "<<property<<endl;
#endif

    mRequests.push_back(property);
}

void GeniviLogReplayerPlugin::unsubscribeToPropertyChanges(VehicleProperty::Property property)
{
#ifdef  DLT
    LOG_DEBUG(gContext,"GeniviLogReplayer: unsubscribeToPropertyChanges %s", property);
#else
    DebugOut(0)<<"GeniviLogReplayer: unsubscribeToPropertyChanges "<<property<<endl;
#endif

    if(contains(mRequests,property))
        removeOne(&mRequests, property);
}

PropertyList GeniviLogReplayerPlugin::supported()
{
    return mSupported;
}

int GeniviLogReplayerPlugin::supportedOperations()
{
    // only Get is supported (receiver), no implementation of Set
	return Get;
}

// new values are received through a socket from the logreplayer
// data is updated when received
int GeniviLogReplayerPlugin::updateProperties()
{
    struct sockaddr_in si_me, si_other;
    int s;
    socklen_t slen = sizeof(si_other);
    char buf[BUFLEN];

    if((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1)
    {
        return EXIT_FAILURE;
    }

    memset((char *) &si_me, 0, sizeof(si_me));
    si_me.sin_family = AF_INET;

    si_me.sin_port = htons(PORT);
    si_me.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(s,  (struct sockaddr *) &si_me, sizeof(si_me))==-1)
    {
        return EXIT_FAILURE;
    }

    // loop to listen the socket
    while(statusRunning == true)
    {


        // wait until a new data is received
        if(recvfrom(s, buf, BUFLEN, 0, (struct sockaddr *) &si_other, &slen)==-1)
        {
            return EXIT_FAILURE;
        }

        // retrieve the message ID and its value in the received message
        char    msgId[20];
        float     msgValue = 0.0;
        sscanf(buf, "%*[^'$']$%[^',']", msgId);
        sscanf(buf, "%*[^','],%*[^','],%f", &msgValue);
        DebugOut(0)<<"Message received: "<<buf;

        // update AMB property accordingly to the message
        if(!strcmp(msgId, "GVVEHENGSPEED"))
        {
            enginespeed.setValue(msgValue);
            routingEngine->updateProperty(&enginespeed, uuid());
#ifdef  DLT
            LOG_DEBUG(gContext,"GeniviLogReplayer: GVVEHENGSPEED - Message ID, value: %s , %d", msgId,msgValue);
#else
            DebugOut(0)<<"GVVEHENGSPEED - Message ID, value: "<<msgId<<","<<msgValue<<endl;
#endif

        }
        else if(!strcmp(msgId, "GVVEHFUELLEVEL"))
        {
            fuellevel.setValue(msgValue);
            routingEngine->updateProperty(&fuellevel, uuid());
            DebugOut(0)<<"GVVEHFUELLEVEL - Message ID, value: "<<msgId<<","<<msgValue<<endl;
        }
        else if (!strcmp(msgId, "GVVEHFUELCONS"))
        {
            fuelcons.setValue(msgValue);
            routingEngine->updateProperty(&fuelcons, uuid());
            DebugOut(0)<<"GVVEHFUELCONS - Message ID, value: "<<msgId<<","<<msgValue<<endl;
        }
        else if (!strcmp(msgId, "GVVEHTOTALODO"))
        {
            odometer.setValue(msgValue);
            routingEngine->updateProperty(&odometer, uuid());
            DebugOut(0)<<"GVVEHTOTALODO - Message ID, value: "<<msgId<<","<<msgValue<<endl;
        }
    } // while(1)

    // close the socket
    close(s);
}

void GeniviLogReplayerPlugin::addPropertySupport(VehicleProperty::Property property, Zone::Type zone)
{
    mSupported.push_back(property);

    Zone::ZoneList zones;

    zones.push_back(zone);

    PropertyInfo info(0, zones);

    propertyInfoMap[property] = info;
}
