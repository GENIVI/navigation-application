#include <dbus-c++/glib-integration.h>
#include <glib.h>
#include "tripcomputer.h"

static DBus::Glib::BusDispatcher dispatcher;
static DBus::Connection *conn;
static class TripComputer *server;
static GMainLoop *loop;

class TripComputer
: public org::genivi::demonstrator::TripComputer_adaptor,
  public DBus::IntrospectableAdaptor,
  public DBus::ObjectAdaptor
{
	public:
        TripComputer(DBus::Connection &connection)
        : DBus::ObjectAdaptor(connection, "/org/genivi/demonstrator")
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
	g_main_loop_run(loop);
}
