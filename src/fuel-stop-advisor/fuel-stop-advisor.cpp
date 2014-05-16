#include <dbus-c++/glib-integration.h>
#include <glib.h>
#include <stdio.h>
#include <unistd.h>
#include "fuel-stop-advisor.h"
#include "constants.h"
#include "amb.h"
#include "genivi-navigationcore-constants.h"
#include "genivi-navigationcore-routing_proxy.h"

static DBus::Glib::BusDispatcher dispatcher;
static DBus::Connection *conn;
static class FuelStopAdvisor *server;
static GMainLoop *loop;

#define TRIP_COUNT 2

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

class Routing
: public org::genivi::navigationcore::Routing_proxy,
  public DBus::ObjectProxy
{
	public:
	Routing(DBus::Connection &connection)
        : DBus::ObjectProxy(connection, "/org/genivi/navigationcore","org.genivi.navigationcore.Routing")
	{
	}

	void RouteDeleted(const uint32_t& routeHandle)
	{
	}

	void RouteCalculationCancelled(const uint32_t& routeHandle)
	{
	}

	void RouteCalculationSuccessful(const uint32_t& routeHandle, const std::map< uint16_t, uint16_t >& unfullfilledPreferences)
	{
	}

	void RouteCalculationFailed(const uint32_t& routeHandle, const uint16_t& errorCode, const std::map< uint16_t, uint16_t >& unfullfilledPreferences)
	{
	}

	void RouteCalculationProgressUpdate(const uint32_t& routeHandle, const uint16_t& status, const uint8_t& percentage)
	{
	}

	void AlternativeRoutesAvailable(const std::vector< uint32_t >& routeHandlesList)
	{
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

class Trip {
	public:
	Trip()
	{
		reset();
	}

	void
	reset()
	{
		fuelTime=0;
		level=0;
		odometerTime=0;
		odometer=0;
	}
	
	void
	update(Properties *fuel_properties, Properties *odometer_properties)
	{
		DBus::Variant variant;

		if (!fuelTime) {
			variant=fuel_properties->Get("org.automotive.Fuel","Time");
			DBus::MessageIter it=variant.reader();
			it >> fuelTime;
			if (fuelTime) {
				variant=fuel_properties->Get("org.automotive.Fuel","Level");
				DBus::MessageIter it=variant.reader();
				it >> level;
				printf("New fuel level %d at %f\n",level,fuelTime);
			}
		}

		if (!odometerTime) {
			variant=odometer_properties->Get("org.automotive.Odometer","Time");
			DBus::MessageIter it=variant.reader();
			it >> odometerTime;
			if (odometerTime) {
				variant=odometer_properties->Get("org.automotive.Odometer","Odometer");
				it=variant.reader();
				it >> odometer;
				printf("New odometer %d at %f\n",odometer,odometerTime);
			}
		}
	}
	double fuelTime;
	uint16_t level;
	double odometerTime;
	uint32_t odometer;
};


class FuelStopAdvisor
: public org::genivi::demonstrator::FuelStopAdvisor_adaptor,
  public DBus::IntrospectableAdaptor,
  public DBus::ObjectAdaptor
{
	public:
        FuelStopAdvisor(DBus::Connection &connection)
        : DBus::ObjectAdaptor(connection, "/org/genivi/demonstrator/FuelStopAdvisor")
        {
		amb_dispatcher.attach(NULL);
		amb_conn = new DBus::Connection(DBus::Connection::SessionBus());
		amb_conn->setup(&amb_dispatcher);
		amb=new AutomotiveMessageBroker(*amb_conn);

		routing_dispatcher.attach(NULL);
		routing_conn = new DBus::Connection(DBus::Connection::SessionBus());
		routing_conn->setup(&routing_dispatcher);
		routing=new Routing(*routing_conn);

		fuel = amb->FindObject("Fuel");
		odometer = amb->FindObject("Odometer");
		printf("%d %d\n",fuel.size(), odometer.size());

		fuel_properties=new Properties(*amb_conn,fuel[0]);
		odometer_properties=new Properties(*amb_conn,odometer[0]);
		advisorMode=false;
		distanceThreshold=0;
		routeHandle=0;
        }

	::DBus::Struct< uint16_t, uint16_t, uint16_t, std::string >
	GetVersion()
	{
		::DBus::Struct< uint16_t, uint16_t, uint16_t, std::string > ret;
		ret._1=0;
		ret._2=0;
		ret._3=0;
		ret._4="29-11-2013";
		return ret;
	}

	void
	SetUnits(const std::map< uint16_t, uint16_t >& data)
	{
	}

	std::map< uint16_t, ::DBus::Variant >
	GetGlobalData()
	{
		std::map< uint16_t, ::DBus::Variant > ret;
		uint32_t odometer;
		uint16_t level;
		uint16_t consumption;
		double remaining;
		DBus::Variant variant;
		DBus::MessageIter it;

		variant=odometer_properties->Get("org.automotive.Odometer","Odometer");
		it=variant.reader();
		it >> odometer;
		ret[GENIVI_FUELSTOPADVISOR_ODOMETER]=variant_uint32(odometer);

		variant=fuel_properties->Get("org.automotive.Fuel","Level");
		it=variant.reader();
		it >> level;
		ret[GENIVI_FUELSTOPADVISOR_FUEL_LEVEL]=variant_uint16(level);

		variant=fuel_properties->Get("org.automotive.Fuel","InstantConsumption");
		it=variant.reader();
		it >> consumption;
		ret[GENIVI_FUELSTOPADVISOR_INSTANT_FUEL_CONSUMPTION_PER_DISTANCE]=variant_uint16(consumption);

		ret[GENIVI_FUELSTOPADVISOR_TANK_DISTANCE]=variant_uint16(level/fuel_consumption_l_100km*100+0.5);
		ret[GENIVI_FUELSTOPADVISOR_ENHANCED_TANK_DISTANCE]=variant_uint16(enhancedDistance(level,remaining)+0.5);
		return ret;
	}

	uint8_t
	GetSupportedTripNumbers()
	{
		return TRIP_COUNT;
	}

	std::map< uint16_t, ::DBus::Variant >
	GetTripData(const uint8_t& number)
	{
		if (number >= TRIP_COUNT)
			throw DBus::ErrorInvalidArgs("Invalid trip number");
		Trip current;
		trips[number].update(fuel_properties, odometer_properties);
		current.update(fuel_properties, odometer_properties);
		std::map< uint16_t, ::DBus::Variant > ret;
		if (trips[number].odometerTime != current.odometerTime) {
			printf("Current odometer %d last odometer %d\n",current.odometer,trips[number].odometer);
			printf("Current time %f last time %f\n",current.odometerTime,trips[number].odometerTime);
			double average_speed=((current.odometer-trips[number].odometer)/10.0)/((current.odometerTime-trips[number].odometerTime)/3600.0);
			printf("Average Speed %f km/h\n",average_speed);
			ret[GENIVI_FUELSTOPADVISOR_AVERAGE_SPEED]=variant_uint16(average_speed*10+0.5);
		} else {
			ret[GENIVI_FUELSTOPADVISOR_AVERAGE_SPEED]=variant_uint16(0);
		}
		if (current.odometer != trips[number].odometer) {
			printf("Current level %d last level %d\n",current.level,trips[number].level);
			printf("Current odometer %d last odometer %d\n",current.odometer,trips[number].odometer);
			double consumption=100.0*(trips[number].level-current.level)/((current.odometer-trips[number].odometer)/10);
			printf("Consumption %f\n",consumption);
			ret[GENIVI_FUELSTOPADVISOR_AVERAGE_FUEL_CONSUMPTION_PER_DISTANCE]=variant_uint16(consumption*10+0.5);
		} else {
			ret[GENIVI_FUELSTOPADVISOR_AVERAGE_FUEL_CONSUMPTION_PER_DISTANCE]=variant_uint16(0);
		}
		ret[GENIVI_FUELSTOPADVISOR_ODOMETER]=variant_uint32(current.odometer-trips[number].odometer);
		return ret;
	}

	void ResetTripData(const uint8_t& number)
	{
		if (number >= TRIP_COUNT)
			throw DBus::ErrorInvalidArgs("Invalid trip number");
		printf("Reset Trip %d\n",number);
		trips[number].reset();
		trips[number].update(fuel_properties, odometer_properties);
		TripDataResetted(number);
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
		printf("routeHandle %d\n",routeHandle);
		if (routeHandle) {
			std::vector< std::map< uint16_t, ::DBus::Variant > > RouteShape;
			std::vector< uint16_t > valuesToReturn;
			uint32_t totalNumberOfSegments;
			valuesToReturn.push_back(GENIVI_NAVIGATIONCORE_DISTANCE);
			valuesToReturn.push_back(GENIVI_NAVIGATIONCORE_SPEED);
			routing->GetRouteSegments(routeHandle, 1, valuesToReturn, 0xffffffff, 0, totalNumberOfSegments, RouteShape);
			for (int i=0 ; i < RouteShape.size(); i++) {
				double seg_distance;
				uint16_t seg_speed;
				DBus::MessageIter it;

				it=RouteShape[i][GENIVI_NAVIGATIONCORE_DISTANCE].reader();
				it >> seg_distance;
				it=RouteShape[i][GENIVI_NAVIGATIONCORE_SPEED].reader();
				it >> seg_speed;
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
			printf("%d segments\n",totalNumberOfSegments);
		}
		remaining=level/fuel_consumption_l_100km*100;
		printf("distance_on_route %f remaining %f\n",distance/1000,remaining);
		return distance/1000+(remaining > 0 ? remaining:0);
	}
	
	void update_data()
	{
		int i;
		for (i = 0 ; i < TRIP_COUNT ; i++) {
			trips[i].update(fuel_properties, odometer_properties);
		}
		if (advisorMode) {
			uint16_t level;
			double remaining;
			DBus::Variant variant;
			DBus::MessageIter it;

			variant=fuel_properties->Get("org.automotive.Fuel","Level");
			it=variant.reader();
			it >> level;
			enhancedDistance(level, remaining);
			if (remaining < distanceThreshold)
				FuelStopAdvisorWarning();
		}
	}

	void
	SetFuelAdvisorSettings(const bool& advisorMode, const uint8_t& distanceThreshold)
	{
		this->advisorMode=advisorMode;
		this->distanceThreshold=distanceThreshold;
	}
	
	void
	GetFuelAdvisorSettings(bool& advisorMode, uint8_t& distanceThreshold)
	{
		advisorMode=this->advisorMode;
		distanceThreshold=this->distanceThreshold;
	}

	void SetRouteHandle(const uint32_t& routeHandle)
	{
		printf("SetRouteHandle %d\n",routeHandle);
		this->routeHandle=routeHandle;
	}

	private:
	DBus::Glib::BusDispatcher amb_dispatcher;
	DBus::Connection *amb_conn;
	AutomotiveMessageBroker *amb;
	DBus::Glib::BusDispatcher routing_dispatcher;
	DBus::Connection *routing_conn;
	Routing *routing;
	std::vector< ::DBus::Path > fuel;
	std::vector< ::DBus::Path > odometer;
	Properties *fuel_properties;
	Properties *odometer_properties;
	Trip trips[TRIP_COUNT];
	bool advisorMode;
	uint8_t distanceThreshold;
	uint32_t routeHandle;
};

static gboolean
update_data(gpointer user_data)
{
	FuelStopAdvisor *tc=(FuelStopAdvisor *)user_data;
	tc->update_data();
	return TRUE;
}

int main(int argc, char **argv)
{
	loop=g_main_loop_new(NULL, false);
	dispatcher.attach(NULL);
	DBus::default_dispatcher = &dispatcher;
	conn = new DBus::Connection(DBus::Connection::SessionBus());
	conn->setup(&dispatcher);
	conn->request_name("org.genivi.demonstrator.FuelStopAdvisor");
	server=new FuelStopAdvisor(*conn);

	g_timeout_add(1000, update_data, server);
	g_main_loop_run(loop);
}
