
#ifndef GENIVILOGREPLAYERPLUGIN_H
#define GENIVILOGREPLAYERPLUGIN_H

#include <abstractsource.h>
#include <string>

using namespace std;

class GeniviLogReplayerPlugin: public AbstractSource
{

public:

	GeniviLogReplayerPlugin(AbstractRoutingEngine* re, map<string, string> config);
	~GeniviLogReplayerPlugin();
	const string uuid();
	void getPropertyAsync(AsyncPropertyReply *reply);
	void getRangePropertyAsync(AsyncRangePropertyReply *reply);
	AsyncPropertyReply * setProperty(AsyncSetPropertyRequest request);
	void subscribeToPropertyChanges(VehicleProperty::Property property);
	void unsubscribeToPropertyChanges(VehicleProperty::Property property);
	int supportedOperations();	
	void supportedChanged(PropertyList) {}

    void propertyChanged(VehicleProperty::Property property, AbstractPropertyType* value, string uuid) {}
    int updateProperties();


private:	
	std::string device;
	std::list<AsyncPropertyReply*> replyQueue;
    PropertyList mRequests;
    PropertyList mSupported;

    // listening loop management and thread
    GThread *thread;
    bool statusRunning = false;
};

#endif // GENIVILOGREPLAYERPLUGIN_H
