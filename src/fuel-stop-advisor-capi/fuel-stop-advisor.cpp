#include <dbus-c++/glib-integration.h>
#include <glib.h>
#include <stdio.h>
#include <unistd.h>

#include "amb_proxy.h"
#include "ctripcomputer.h"
#include <boost/variant/get.hpp>

#include <CommonAPI/CommonAPI.hpp>
#include <FuelStopAdvisorStubDefault.hpp>
#include <NavigationTypes.hpp>
#include <NavigationCoreTypes.hpp>
#include <RoutingProxy.hpp>


static GMainLoop *loop;

#define dbgprintf(...) printf(__VA_ARGS__);

#if (!DEBUG_ENABLED)
#undef dbgprintf
#define dbgprintf(...) ;
#endif

using namespace v4::org::genivi::navigation::navigationcore;
using namespace v4::org::genivi::navigation;
using namespace v4::org::genivi;
using namespace v1::org::genivi::demonstrator;

/* vehicle parameter */
static double fuel_consumption_l_100km=6.3;

static double fuel_consumption_speed[]={
	6.0, /* 0-9 km/h */
	6.0, /* 10-19 km/h */
	6.0, /* 20-29 km/h */
	6.0, /* 30-39 km/h */
	4.5, /* 40-49 km/h */
	4.5, /* 50-59 km/h */
	4.5, /* 60-69 km/h */
	5.5, /* 70-79 km/h */
	5.5, /* 80-89 km/h */
	7.0, /* 90-99 km/h */
	7.0, /* 100-109 km/h */
	7.0, /* 110-119 km/h */
	7.0, /* 120-129 km/h */
};


static DBus::Variant
variant_uint16(uint16_t i)
{
	DBus::Variant variant;
	DBus::MessageIter iter=variant.writer();
	iter << i;
	return variant;
}

static DBus::Variant
variant_uint32(uint32_t i)
{
	DBus::Variant variant;
	DBus::MessageIter iter=variant.writer();
	iter << i;
	return variant;
}


class Properties
: public ::DBus::InterfaceProxy,
  public ::DBus::ObjectProxy
{
	public:

	Properties(::DBus::Connection &connection, ::DBus::Path path)
        : ::DBus::InterfaceProxy("org.freedesktop.DBus.Properties"),
        ::DBus::ObjectProxy(connection, path,"org.automotive.message.broker")
	{
	}
	::DBus::Variant Get(const std::string &iface, const std::string &property)
	{
		::DBus::CallMessage call;
		::DBus::MessageIter wi = call.writer();
		
		wi << iface;
		wi << property;
		call.member("Get");
		::DBus::Message ret = invoke_method (call);
		::DBus::MessageIter ri = ret.reader();
		::DBus::Variant argout;
		ri >> argout;
		return argout;
	}
};


class AutomotiveMessageBroker
: public org::automotive::Manager_proxy,
  public DBus::ObjectProxy
{
	public:

	AutomotiveMessageBroker(DBus::Connection &connection)
        : DBus::ObjectProxy(connection, "/","org.automotive.message.broker")
	{
	}
};

static std::shared_ptr < CommonAPI::Runtime > runtime;

class RoutingClientProxy
{
    public:

    std::shared_ptr<RoutingProxyDefault> myServiceRouting;

    RoutingClientProxy(const std::string & domain, const std::string & instance)
    {
        myServiceRouting = runtime->buildProxy<RoutingProxy>(domain, instance);
// not working correctly (blocked) so removed for the moment
//        while (!myServiceRouting->isAvailable()) {
//            usleep(10);
//        }
    }

    void setListeners()
    {
        myServiceRouting->getRouteCalculationFailedEvent().subscribe([&](const NavigationTypes::Handle& routeHandle, const Routing::CalculationError& errorCode, const Routing::UnfullfilledRoutePreference& unfullfilledPreferences) {
            routeCalculationFailed(routeHandle,errorCode,unfullfilledPreferences);});
        myServiceRouting->getRouteCalculationSuccessfulEvent().subscribe([&](const NavigationTypes::Handle& routeHandle, const Routing::UnfullfilledRoutePreference& unfullfilledPreferences) {
            routeCalculationSuccessful(routeHandle,unfullfilledPreferences);});
    }

    void routeCalculationFailed(const NavigationTypes::Handle& routeHandle, const Routing::CalculationError& errorCode, const Routing::UnfullfilledRoutePreference& unfullfilledPreferences)
    {
    }

    void routeCalculationSuccessful(const NavigationTypes::Handle& RouteHandle, const Routing::UnfullfilledRoutePreference& unfullfilledPreferences)
    {
    }

};

static DBus::Glib::BusDispatcher amb_dispatcher;
static DBus::Connection *amb_conn;

class FuelStopAdvisorServerStub
: public FuelStopAdvisorStubDefault
{
public:
    FuelStopAdvisorServerStub()
    {
        version_t version;

        //connect to amb and create two handlers for fuel and odometer
		amb=new AutomotiveMessageBroker(*amb_conn);

        //init the routing client
        const std::string domain = "local";
        const std::string instanceRouting = "Routing";
        mp_routingClientProxy = new RoutingClientProxy(domain,instanceRouting);
        mp_routingClientProxy->setListeners();

		fuel = amb->FindObject("Fuel");
		odometer = amb->FindObject("Odometer");

		fuel_properties=new Properties(*amb_conn,fuel[0]);
		odometer_properties=new Properties(*amb_conn,odometer[0]);

        // create an instance of basic trip computer and initialize it
        mp_tripComputer = new CTripComputer();

        mp_tripComputer->Initialize(CTripComputer::INSTANT_FUEL_CONSUMPTION_START_VALUE);

        version = mp_tripComputer->GetVersion();  //Get the version of the basic trip computer

        m_version.setVersionMajor(version.major);
        m_version.setVersionMinor(version.minor);
        m_version.setVersionMicro(version.micro);
        m_version.setDate(version.date);


        tripComputerInput_t tripComputerInput;

        tripComputerInput.fuelLevel = 0;
        tripComputerInput.time = 0;
        tripComputerInput.distance = 0;
        tripComputerInput.fuelConsumption = 0;

        mp_tripComputer->RefreshTripComputerInput(tripComputerInput);

        for (uint8_t i; i<mp_tripComputer->GetSupportedTripNumbers();i++)
        {
            mp_tripComputer->ResetTrip(i);
        }

        // init fsa settings
		advisorMode=false;
		distanceThreshold=0;
        destinationCantBeReached=false;
		routeHandle=0;
        initFlag=true;
        }

    /**
     * description: getVersion = This method returns the API version implemented by the server
     *   application
     */
    void getVersion(const std::shared_ptr<CommonAPI::ClientId> _client, getVersionReply_t _reply) {
        _reply(m_version);
    }

    /**
     * description: setUnits = This method sets the calculation unit for a given value
     */
    void setUnits(const std::shared_ptr<CommonAPI::ClientId> _client, FuelStopAdvisor::Units _unit, setUnitsReply_t _reply) {
        FuelStopAdvisor::Units::const_iterator iter;
        tupleInt32_t data;
        for(iter=_unit.begin();iter!=_unit.end();++iter)
        {
            data[(iter->first)]=(iter->second);
        }
        mp_tripComputer->SetUnits(data); //Set units of the basic trip computer
        _reply();
    }

    /**
     * description: getInstantData = This method returns a given set of global (not related to a
     *   trip number) trip computer data (e.g. odometer, fuel level, tank distance... )
     */
    void getInstantData(const std::shared_ptr<CommonAPI::ClientId> _client, getInstantDataReply_t _reply) {
        FuelStopAdvisor::InstantData _data;
        tupleVariantTripComputer_t tripComputerData;
        tupleVariantTripComputer_t::iterator iter;
        variantTripComputer_t value;
        uint16_t level;
        double remaining;

        tripComputerData= mp_tripComputer->GetInstantData();

        for(iter = tripComputerData.begin(); iter != tripComputerData.end(); iter++)
        {
            value = iter->second;
            if (iter->first == CTripComputer::TRIPCOMPUTER_INSTANT_FUEL_CONSUMPTION_PER_DISTANCE)
            {
                _data[FuelStopAdvisor::InstantDataAttribute::INSTANT_FUEL_CONSUMPTION_PER_DISTANCE]= boost::get<uint16_t>(iter->second);
            }
            else
            {
                if (iter->first == CTripComputer::TRIPCOMPUTER_TANK_DISTANCE)
                { //tank distance is valid, so it means that fuel level is valid too
                    _data[FuelStopAdvisor::InstantDataAttribute::TANK_DISTANCE]=boost::get<uint16_t>(iter->second);
                    _data[FuelStopAdvisor::InstantDataAttribute::FUEL_LEVEL]=fuelLevel;
                    if (this->routeHandle != 0)
                    { // a route is valid so it makes sense to calculate enhanced tank distance
                        _data[FuelStopAdvisor::InstantDataAttribute::ENHANCED_TANK_DISTANCE]=(uint16_t)(enhancedDistance(fuelLevel,remaining)+0.5);
                    }
                }
            }
        }

        _reply(_data);
    }

    /**
     * description: getTripData = This method returns the data of a given trip number
     */
    void getTripData(const std::shared_ptr<CommonAPI::ClientId> _client, FuelStopAdvisor::TripNumber _number, getTripDataReply_t _reply) {
        FuelStopAdvisor::TripData _data;
        tupleVariantTripComputer_t tripComputerData;
        tupleVariantTripComputer_t::iterator iter;
        variantTripComputer_t value;

        if (_number >= mp_tripComputer->GetSupportedTripNumbers())
            throw DBus::ErrorInvalidArgs("Invalid trip number");

        tripComputerData= mp_tripComputer->GetTripData(_number);
        for(iter = tripComputerData.begin(); iter != tripComputerData.end(); iter++)
        {
            value = iter->second;
            if (iter->first == CTripComputer::TRIPCOMPUTER_AVERAGE_FUEL_CONSUMPTION_PER_DISTANCE)
            {
                _data[FuelStopAdvisor::TripDataAttribute::AVERAGE_FUEL_CONSUMPTION_PER_DISTANCE]=boost::get<uint16_t>(iter->second);
            }
            else
            {
                if (iter->first == CTripComputer::TRIPCOMPUTER_AVERAGE_SPEED)
                {
                    _data[FuelStopAdvisor::TripDataAttribute::AVERAGE_SPEED]=boost::get<uint16_t>(iter->second);
                }
                else
                {
                    if (iter->first == CTripComputer::TRIPCOMPUTER_DISTANCE)
                    {
                        _data[FuelStopAdvisor::TripDataAttribute::DISTANCE]=boost::get<uint16_t>(iter->second);
                    }
                }
            }
        }
        _reply(_data);

    }

    /**
     * description: getSupportedTripNumbers = This method returns the number of supported trips
     */
    void getSupportedTripNumbers(const std::shared_ptr<CommonAPI::ClientId> _client, getSupportedTripNumbersReply_t _reply) {
        _reply(mp_tripComputer->GetSupportedTripNumbers());
    }

    /**
     * description: setFuelAdvisorSettings = This method configures the fuel stop advisor settings
     */
    void setFuelAdvisorSettings(const std::shared_ptr<CommonAPI::ClientId> _client, bool _advisorMode, uint8_t _distanceThreshold, setFuelAdvisorSettingsReply_t _reply) {
        dbgprintf("SetFuelAdvisorSettings(%d,%d)\n",advisorMode, distanceThreshold);
        advisorMode=_advisorMode;
        distanceThreshold=_distanceThreshold;
        updateEnhancedDistance();
        _reply();
    }

    /**
     * description: resetTripData = This method resets the data of a given trip
     */
    void resetTripData(const std::shared_ptr<CommonAPI::ClientId> _client, uint8_t _number, resetTripDataReply_t _reply) {
        if (_number >= mp_tripComputer->GetSupportedTripNumbers())
           throw DBus::ErrorInvalidArgs("Invalid trip number");
        mp_tripComputer->ResetTrip(_number);
        fireTripDataResettedEvent(_number);
       _reply();
    }

    /**
     * description: getFuelAdvisorSettings = This method gets the fuel stop advisor settings
     */
    void getFuelAdvisorSettings(const std::shared_ptr<CommonAPI::ClientId> _client, getFuelAdvisorSettingsReply_t _reply) {
        bool _advisorMode;
        uint8_t _distanceThreshold;
        bool _destinationCantBeReached;
        _advisorMode=advisorMode;
        _distanceThreshold=distanceThreshold;
        _destinationCantBeReached=destinationCantBeReached;
        _reply(_advisorMode,_distanceThreshold,_destinationCantBeReached);
    }

    /**
     * description: setRouteHandle = This method configures the route handle for the enhanced tank
     *   distance
     */
    void setRouteHandle(const std::shared_ptr<CommonAPI::ClientId> _client, uint32_t _routeHandle, setRouteHandleReply_t _reply) {
        dbgprintf("SetRouteHandle %d\n",_routeHandle);
        routeHandle=_routeHandle;
        updateEnhancedDistance();
        _reply();
    }

    /**
     * description: releaseRouteHandle = This method release the route handle for the enhanced tank
     *   distance
     */
    void releaseRouteHandle(const std::shared_ptr<CommonAPI::ClientId> _client, uint32_t _routeHandle, releaseRouteHandleReply_t _reply) {
        dbgprintf("ResetRouteHandle %d\n",_routeHandle);
        routeHandle=0;
        updateEnhancedDistance();
        _reply();
    }


	double fuelConsumptionAtSpeed(uint16_t seg_speed)
	{
		if (seg_speed > 129)
			seg_speed=129;
		return fuel_consumption_speed[seg_speed/10];
	}

	double enhancedDistance(double level, double &remaining)
	{
		double distance=0;
        dbgprintf("routeHandle %d\n",routeHandle);
        if (routeHandle) {
            std::vector< Routing::RouteSegment > RouteShape;
            std::vector< Routing::RouteSegmentType > valuesToReturn;
			uint32_t totalNumberOfSegments;
            valuesToReturn.push_back(Routing::RouteSegmentType::DISTANCE);
            valuesToReturn.push_back(Routing::RouteSegmentType::SPEED);
            CommonAPI::CallStatus _internalCallStatus;
            mp_routingClientProxy->myServiceRouting->getRouteSegments(routeHandle, 1, valuesToReturn, 0xffffffff, 0,_internalCallStatus, totalNumberOfSegments, RouteShape);
            for (size_t i=0 ; i < RouteShape.size(); i++) {
				double seg_distance;
				uint16_t seg_speed;

                seg_distance=RouteShape[i][Routing::RouteSegmentType::DISTANCE].get<double>();
                seg_speed=RouteShape[i][Routing::RouteSegmentType::SPEED].get<uint16_t>();
				if (seg_distance && seg_speed) {
					double fuel_consumption=fuelConsumptionAtSpeed(seg_speed)*seg_distance/100000;
					if (fuel_consumption > level && level > 0) {
						seg_distance=seg_distance*level/fuel_consumption;
						fuel_consumption=level;
					}
					if (level > 0) 
						distance+=seg_distance;
					level-=fuel_consumption;
				}
			}
            dbgprintf("%d segments\n",totalNumberOfSegments);
		}
		remaining=level/fuel_consumption_l_100km*100;
        dbgprintf("distance_on_route %f remaining %f\n",distance/1000,remaining);
		return distance/1000+(remaining > 0 ? remaining:0);
	}
	
	void update_data()
	{
        tripComputerInput_t tripComputerInput;
        DBus::Variant variant;
        DBus::MessageIter it;
        uint32_t odometer;
        uint16_t level;
        uint32_t consumption;
        double time;


        variant=fuel_properties->Get("org.automotive.Fuel","Level");
        it=variant.reader();
        it >> level;

        variant=odometer_properties->Get("org.automotive.Odometer","Time");
        it=variant.reader();
        it >> time;

        //odometer is used for simulating distance
        variant=odometer_properties->Get("org.automotive.Odometer","Odometer");
        it=variant.reader();
        it >> odometer;

        if (initFlag)
        {
            if (time != 0)
            {
                initFlag = false;
                lastTime = time;
                lastOdometer = odometer;
            }
            timeCounter = 0;
            distanceCounter = 0;
        }
        else
        {
            if ((timeCounter+(time-lastTime)*CTripComputer::CONVERT_SECOND_IN_MILLISECOND) > USHRT_MAX)
            {
                timeCounter =  (time-lastTime)*CTripComputer::CONVERT_SECOND_IN_MILLISECOND - (USHRT_MAX - timeCounter);
            }
            else
            {
                timeCounter += (time-lastTime)*CTripComputer::CONVERT_SECOND_IN_MILLISECOND;
            }
            lastTime = time;

//            if ((distanceCounter+(odometer-lastOdometer)) > USHRT_MAX)
            if ((distanceCounter+odometer) > USHRT_MAX)
            {
//                distanceCounter =  (odometer-lastOdometer) - (USHRT_MAX - distanceCounter);
                distanceCounter =  (distanceCounter+odometer)-USHRT_MAX ;
            }
            else
            {
//                distanceCounter += (odometer-lastOdometer);
                distanceCounter += odometer;
            }
//            lastOdometer = odometer;

        }
        tripComputerInput.time = timeCounter;
        tripComputerInput.distance = distanceCounter;

        variant=fuel_properties->Get("org.automotive.Fuel","InstantConsumption");
        it=variant.reader();
        it >> consumption;

        tripComputerInput.fuelLevel = level*CTripComputer::CONVERT_LITER_IN_DL;
        tripComputerInput.fuelConsumption = consumption;

        mp_tripComputer->RefreshTripComputerInput(tripComputerInput);

        fuelLevel = level; //to avoid re-ask it to amb

        fireTripDataUpdatedEvent(0); //arg is for future use
	}

    void updateEnhancedDistance()
    {
        double remaining;
        if (advisorMode) {
            enhancedDistance(fuelLevel, remaining);
            dbgprintf("Advisor %f vs %d\n",remaining, distanceThreshold);
            if (remaining < distanceThreshold) {
                dbgprintf("Warning %f < %d\n",remaining, distanceThreshold);
                destinationCantBeReached = true;
            }
            else
            {
                destinationCantBeReached = false;
            }
            fireFuelStopAdvisorWarningEvent(destinationCantBeReached);
            fireTripDataUpdatedEvent(0); //arg is for future use
        }
    }


	private:
    RoutingClientProxy* mp_routingClientProxy;
    FuelStopAdvisor::Version m_version;
	AutomotiveMessageBroker *amb;
	std::vector< ::DBus::Path > fuel;
	std::vector< ::DBus::Path > odometer;
	Properties *fuel_properties;
	Properties *odometer_properties;
    CTripComputer *mp_tripComputer;
	bool advisorMode;
	uint8_t distanceThreshold;
    bool destinationCantBeReached;
	uint32_t routeHandle;
    bool initFlag;
    double lastTime;
    uint16_t timeCounter;
    uint32_t lastOdometer;
    uint16_t distanceCounter;
    uint16_t fuelLevel;
};

static gboolean
update_data(gpointer user_data)
{
    FuelStopAdvisorServerStub *tc=(FuelStopAdvisorServerStub *)user_data;
	tc->update_data();
	return TRUE;
}

int main(int argc, char **argv)
{
	loop=g_main_loop_new(NULL, false);

    // Init AMB DBus connection
    amb_dispatcher.attach(NULL);
    DBus::default_dispatcher = &amb_dispatcher;
    amb_conn = new DBus::Connection(DBus::Connection::SessionBus());
    amb_conn->setup(&amb_dispatcher);

    // Common API data init
    runtime = CommonAPI::Runtime::get();

    // init the Fuel Stop Advisor server
    const std::string domain = "local";
    const std::string instanceFuelStopAdvisor = "FuelStopAdvisor";

    std::shared_ptr<FuelStopAdvisorServerStub> myServiceFuelStopAdvisor = std::make_shared<FuelStopAdvisorServerStub>();

    bool successfullyRegistered = runtime->registerService(domain, instanceFuelStopAdvisor, myServiceFuelStopAdvisor);
    while (!successfullyRegistered) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        successfullyRegistered = runtime->registerService(domain, instanceFuelStopAdvisor, myServiceFuelStopAdvisor);
    }

    g_timeout_add(CTripComputer::SAMPLING_TIME*CTripComputer::CONVERT_SECOND_IN_MILLISECOND, update_data, myServiceFuelStopAdvisor.get());
	g_main_loop_run(loop);
}
