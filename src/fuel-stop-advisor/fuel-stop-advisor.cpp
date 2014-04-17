#include <dbus-c++/glib-integration.h>
#include <glib.h>
#include "fuel-stop-advisor.h"

static DBus::Glib::BusDispatcher dispatcher;
static DBus::Connection *conn;
static class FuelStopAdvisor *server;
static GMainLoop *loop;

class FuelStopAdvisor
: public org::genivi::demonstrator::FuelStopAdvisor_adaptor,
  public DBus::IntrospectableAdaptor,
  public DBus::ObjectAdaptor
{
	public:
        FuelStopAdvisor(DBus::Connection &connection)
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
	GetGlobalData()
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

	void
	ResetTripData(const uint8_t& number)
	{
	}

	void
	SetFuelAdvisorSettings(const bool& advisorMode, const uint8_t& distanceThreshold)
	{
	}

	void
	GetFuelAdvisorSettings(bool& advisorMode, uint8_t& distanceThreshold)
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
	conn->request_name("org.genivi.demonstrator.FuelStopAdvisor");
	server=new FuelStopAdvisor(*conn);
	g_main_loop_run(loop);
}
