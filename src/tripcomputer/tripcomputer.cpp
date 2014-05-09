#include <dbus-c++/glib-integration.h>
#include <glib.h>
#include <stdio.h>
#include <unistd.h>
#include "tripcomputer.h"
#include "constants.h"
#include "amb.h"

static DBus::Glib::BusDispatcher dispatcher,amb_dispatcher;
static DBus::Connection *conn,*amb_conn;
static class TripComputer *server;
static class AutomotiveMessageBroker *amb;
static GMainLoop *loop;

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


class TripComputer
: public org::genivi::demonstrator::TripComputer_adaptor,
  public DBus::IntrospectableAdaptor,
  public DBus::ObjectAdaptor
{
	public:
        TripComputer(DBus::Connection &connection)
        : DBus::ObjectAdaptor(connection, "/org/genivi/demonstrator/TripComputer")
        {
        }

	::DBus::Struct< uint16_t, uint16_t, uint16_t, std::string >
	GetVersion()
	{
	}

	void
	SetUnits(const std::map< uint16_t, uint16_t >& data)
	{
	}

	std::map< uint16_t, ::DBus::Variant >
	GetInstantData()
	{
	}

	uint8_t
	GetSupportedTripNumbers()
	{
	}

	std::map< uint16_t, ::DBus::Variant >
	GetTripData(const uint8_t& number)
	{
		std::map< uint16_t, ::DBus::Variant > ret;
		ret[GENIVI_TRIPCOMPUTER_AVERAGE_SPEED]=variant_uint16(470);
		ret[GENIVI_TRIPCOMPUTER_AVERAGE_FUEL_CONSUMPTION]=variant_uint16(58);
		ret[GENIVI_TRIPCOMPUTER_ODOMETER]=variant_uint32(1300);
		return ret;
	}

	void ResetTripData(const uint8_t& number)
	{
	}
};



int main(int argc, char **argv)
{
	loop=g_main_loop_new(NULL, false);
	dispatcher.attach(NULL);
	DBus::default_dispatcher = &dispatcher;
	conn = new DBus::Connection(DBus::Connection::SessionBus());
	conn->setup(&dispatcher);
	conn->request_name("org.genivi.demonstrator.TripComputer");
	server=new TripComputer(*conn);

	amb_dispatcher.attach(NULL);
	amb_conn = new DBus::Connection(DBus::Connection::SessionBus());
	amb_conn->setup(&amb_dispatcher);
	amb=new AutomotiveMessageBroker(*amb_conn);

	std::vector< ::DBus::Path > fuel = amb->FindObject("Fuel");
	std::vector< ::DBus::Path > odometer = amb->FindObject("Odometer");
	printf("%d %d\n",fuel.size(), odometer.size());

	Properties *fuel_properties=new Properties(*amb_conn,fuel[0]);
	Properties *odometer_properties=new Properties(*amb_conn,odometer[0]);
#if 0
	for (;;) {
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
		sleep(1);
	}
#endif
	

	g_main_loop_run(loop);
}
