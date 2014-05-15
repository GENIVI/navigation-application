#include <dbus-c++/glib-integration.h>
#include <glib.h>
#include <stdio.h>
#include <unistd.h>
#include "fuel-stop-advisor.h"
#include "constants.h"
#include "amb.h"

static DBus::Glib::BusDispatcher dispatcher;
static DBus::Connection *conn;
static class FuelStopAdvisor *server;
static GMainLoop *loop;

#define TRIP_COUNT 2

/* vehicle parameter */
static double fuel_consumption_l_100km=7.0;


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

		fuel = amb->FindObject("Fuel");
		odometer = amb->FindObject("Odometer");
		printf("%d %d\n",fuel.size(), odometer.size());

		fuel_properties=new Properties(*amb_conn,fuel[0]);
		odometer_properties=new Properties(*amb_conn,odometer[0]);
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
	
	void update_data()
	{
		int i;
		for (i = 0 ; i < TRIP_COUNT ; i++) {
			trips[i].update(fuel_properties, odometer_properties);
		}
#if 0
		DBus::Variant variant=fuel_properties->Get("org.automotive.Fuel","Level");
		DBus::MessageIter it=variant.reader();
		uint16_t res;
		it >> res;
		printf("%d\n",res);
		variant=fuel_properties->Get("org.automotive.Fuel","InstantConsumption");
		it=variant.reader();
		it >> res;
		printf("%d\n",res);
		variant=odometer_properties->Get("org.automotive.Odometer","Odometer");
		it=variant.reader();
		uint32_t res2;
		it >> res2;
		printf("%d\n",res2);
#endif
	}

	void
	SetFuelAdvisorSettings(const bool& advisorMode, const uint8_t& distanceThreshold)
	{
	}
	
	void
	GetFuelAdvisorSettings(bool& advisorMode, uint8_t& distanceThreshold)
	{
	}

	void SetRouteHandle(const uint32_t& routeHandle)
	{
	}

	private:
	DBus::Glib::BusDispatcher amb_dispatcher;
	DBus::Connection *amb_conn;
	AutomotiveMessageBroker *amb;
	std::vector< ::DBus::Path > fuel;
	std::vector< ::DBus::Path > odometer;
	Properties *fuel_properties;
	Properties *odometer_properties;
	Trip trips[TRIP_COUNT];
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
