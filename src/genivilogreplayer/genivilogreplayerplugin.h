
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
    PropertyList supported();
    int supportedOperations();
    void supportedChanged(const PropertyList &) {}
    PropertyInfo getPropertyInfo(const VehicleProperty::Property & property)
    {
        if(propertyInfoMap.find(property) != propertyInfoMap.end())
            return propertyInfoMap[property];

        return PropertyInfo::invalid();
    }
    int updateProperties();

private:	
    void addPropertySupport(VehicleProperty::Property property, Zone::Type zone);
    std::map<Zone::Type, bool> acStatus;
    std::map<VehicleProperty::Property, PropertyInfo> propertyInfoMap;

    std::string device;
	std::list<AsyncPropertyReply*> replyQueue;
    PropertyList mRequests;
    PropertyList mSupported;

    // listening loop management and thread
    GThread *thread;
    bool statusRunning = false;
};

#endif // GENIVILOGREPLAYERPLUGIN_H
