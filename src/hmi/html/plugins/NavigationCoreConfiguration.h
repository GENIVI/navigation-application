#include <stdio.h>
#include <string.h>

enum Settings {
    INVALID 				= 0,
    UNITS_OF_MEASUREMENT 	= 48, //Base 0x0030
    LOCALE 					= 37,
    TIME_FORMAT 			= 3,
    COORDINATES_FORMAT 		= 6
};

struct Version {
	unsigned short versionMajor;
	unsigned short versionMinor;
	unsigned short versionMicro;
	char *date;
};

class NavigationCoreConfiguration {
protected:
  int m_interfaceId;
public:
    NavigationCoreConfiguration(int interface_id);
    ~NavigationCoreConfiguration();
    int getInterfaceId() {return m_interfaceId;}
    char* getVersion();
    char* getDate() {return m_version.date;}
	Version m_version;
private:
};
