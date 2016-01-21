#include "NavigationCoreConfiguration.h"

#include "NavigationCoreConfiguration_ems.cpp"


NavigationCoreConfiguration::NavigationCoreConfiguration(int interface_id)
{
    m_interfaceId = interface_id;
    m_version.versionMajor = 0;
    m_version.versionMicro = 0;
    m_version.versionMicro = 1;
    m_version.date = "12-01-2016";

}

NavigationCoreConfiguration::~NavigationCoreConfiguration()
{
}

unsigned short NavigationCoreConfiguration::getVersion()
{
}


