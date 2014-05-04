#include "genivilogreplayerplugin.h"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <boost/assert.hpp>

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

void *updatePropertiesThread(gpointer data)
{
    GeniviLogReplayerPlugin* src = (GeniviLogReplayerPlugin*)data;
    src->updateProperties();
}

GeniviLogReplayerPlugin::GeniviLogReplayerPlugin(AbstractRoutingEngine* re, map<string, string> config)
	:AbstractSource(re, config)
{
    // properties managed by this plugin
    mSupported.push_back(VehicleProperty::EngineSpeed);
    mSupported.push_back(VehicleProperty::FuelLevel);
    mSupported.push_back(VehicleProperty::FuelConsumption);
    mSupported.push_back(VehicleProperty::Odometer);

    // Declare which properties are supported by this plug-in
    re->setSupported(mSupported, this);

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
    return "326011dd-65cd-4be6-a75e-3e8d46a05510";
}


void GeniviLogReplayerPlugin::getPropertyAsync(AsyncPropertyReply *reply)
{
#ifdef  DLT
    LOG_DEBUG(gContext,"GeniviLogReplayer: getPropertyAsync %s", reply->property);
#else
    DebugOut(0)<<"GeniviLogReplayer: getPropertyAsync "<<reply->property<<endl;
#endif

    PropertyList s = mSupported;
	if(ListPlusPlus<VehicleProperty::Property>(&s).contains(reply->property))
	{
        // retrieve the value
		replyQueue.push_back(reply);
	}
    else  // your property request is not supported
	{
		reply->value = NULL;
		reply->success = false;
		reply->completed(reply);
	}
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
        mRequests.remove(property);
}

int GeniviLogReplayerPlugin::supportedOperations()
{
    // only Get is supported (receiver), no implementation of Set
	return Get;
}

// new values are receive through a socket from the logreplayer
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
            VehicleProperty::EngineSpeedType enginespeed(msgValue);
            routingEngine->updateProperty(&enginespeed, uuid());
#ifdef  DLT
            LOG_DEBUG(gContext,"GeniviLogReplayer: GVVEHENGSPEED - Message ID, value: %s , %d", msgId,msgValue);
#else
            DebugOut(0)<<"GVVEHENGSPEED - Message ID, value: "<<msgId<<","<<msgValue<<endl;
#endif

        }
        else if(!strcmp(msgId, "GVVEHFUELLEVEL"))
        {
            VehicleProperty::FuelLevelType fuellevel(msgValue);
            routingEngine->updateProperty(&fuellevel, uuid());
            DebugOut(0)<<"GVVEHFUELLEVEL - Message ID, value: "<<msgId<<","<<msgValue<<endl;
        }
        else if (!strcmp(msgId, "GVVEHFUELCONS"))
        {
            VehicleProperty::FuelConsumptionType fuelcons(msgValue);
            routingEngine->updateProperty(&fuelcons, uuid());
            DebugOut(0)<<"GVVEHFUELCONS - Message ID, value: "<<msgId<<","<<msgValue<<endl;
        }
        else if (!strcmp(msgId, "GVVEHTOTALODO"))
        {
            VehicleProperty::OdometerType odometer(msgValue);
            routingEngine->updateProperty(&odometer, uuid());
            DebugOut(0)<<"GVVEHTOTALODO - Message ID, value: "<<msgId<<","<<msgValue<<endl;
        }
    } // while(1)

    // close the socket
    close(s);
}

