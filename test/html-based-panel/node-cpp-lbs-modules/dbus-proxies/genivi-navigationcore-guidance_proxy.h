
/*
 *	This file was automatically generated by dbusxx-xml2cpp; DO NOT EDIT!
 */

#ifndef __dbusxx___home_fifi_Bureau_genivi_navigation_src_navigation_build_dbus_include_navigation_core_genivi_navigationcore_guidance_proxy_h__PROXY_MARSHAL_H
#define __dbusxx___home_fifi_Bureau_genivi_navigation_src_navigation_build_dbus_include_navigation_core_genivi_navigationcore_guidance_proxy_h__PROXY_MARSHAL_H

#include <dbus-c++/dbus.h>
#include <cassert>

namespace org {
namespace genivi {
namespace navigationcore {

class Guidance_proxy
: public ::DBus::InterfaceProxy
{
public:

    Guidance_proxy()
    : ::DBus::InterfaceProxy("org.genivi.navigationcore.Guidance")
    {
        connect_signal(Guidance_proxy, VehicleLeftTheRoadNetwork, _VehicleLeftTheRoadNetwork_stub);
        connect_signal(Guidance_proxy, GuidanceStatusChanged, _GuidanceStatusChanged_stub);
        connect_signal(Guidance_proxy, WaypointReached, _WaypointReached_stub);
        connect_signal(Guidance_proxy, ManeuverChanged, _ManeuverChanged_stub);
        connect_signal(Guidance_proxy, PositionOnRouteChanged, _PositionOnRouteChanged_stub);
        connect_signal(Guidance_proxy, VehicleLeftTheRoute, _VehicleLeftTheRoute_stub);
        connect_signal(Guidance_proxy, PositionToRouteChanged, _PositionToRouteChanged_stub);
        connect_signal(Guidance_proxy, ActiveRouteChanged, _ActiveRouteChanged_stub);
    }

public:

    /* properties exported by this interface */
public:

    /* methods exported by this interface,
     * this functions will invoke the corresponding methods on the remote objects
     */
    ::DBus::Struct< uint16_t, uint16_t, uint16_t, std::string > GetVersion()
    {
        ::DBus::CallMessage call;
        call.member("GetVersion");
        ::DBus::Message ret = invoke_method (call);
        ::DBus::MessageIter ri = ret.reader();

        ::DBus::Struct< uint16_t, uint16_t, uint16_t, std::string > argout;
        ri >> argout;
        return argout;
    }

    void StartGuidance(const uint32_t& sessionHandle, const uint32_t& routeHandle)
    {
        ::DBus::CallMessage call;
        ::DBus::MessageIter wi = call.writer();

        wi << sessionHandle;
        wi << routeHandle;
        call.member("StartGuidance");
        ::DBus::Message ret = invoke_method (call);
    }

    void StopGuidance(const uint32_t& sessionHandle)
    {
        ::DBus::CallMessage call;
        ::DBus::MessageIter wi = call.writer();

        wi << sessionHandle;
        call.member("StopGuidance");
        ::DBus::Message ret = invoke_method (call);
    }

    void SetVoiceGuidance(const bool& activate, const std::string& voice)
    {
        ::DBus::CallMessage call;
        ::DBus::MessageIter wi = call.writer();

        wi << activate;
        wi << voice;
        call.member("SetVoiceGuidance");
        ::DBus::Message ret = invoke_method (call);
    }

    void GetGuidanceDetails(bool& voiceGuidance, bool& vehicleOnTheRoad, bool& isDestinationReached, int32_t& maneuver)
    {
        ::DBus::CallMessage call;
        call.member("GetGuidanceDetails");
        ::DBus::Message ret = invoke_method (call);
        ::DBus::MessageIter ri = ret.reader();

        ri >> voiceGuidance;
        ri >> vehicleOnTheRoad;
        ri >> isDestinationReached;
        ri >> maneuver;
    }

    void PlayVoiceManeuver()
    {
        ::DBus::CallMessage call;
        call.member("PlayVoiceManeuver");
        ::DBus::Message ret = invoke_method (call);
    }

    void GetWaypointInformation(const uint16_t& requestedNumberOfWaypoints, uint16_t& numberOfWaypoints, std::vector< ::DBus::Struct< uint32_t, uint32_t, int32_t, int32_t, int16_t, int16_t, bool, uint16_t > >& waypointsList)
    {
        ::DBus::CallMessage call;
        ::DBus::MessageIter wi = call.writer();

        wi << requestedNumberOfWaypoints;
        call.member("GetWaypointInformation");
        ::DBus::Message ret = invoke_method (call);
        ::DBus::MessageIter ri = ret.reader();

        ri >> numberOfWaypoints;
        ri >> waypointsList;
    }

    void GetDestinationInformation(uint32_t& offset, uint32_t& travelTime, int32_t& direction, int32_t& side, int16_t& timeZone, int16_t& daylightSavingTime)
    {
        ::DBus::CallMessage call;
        call.member("GetDestinationInformation");
        ::DBus::Message ret = invoke_method (call);
        ::DBus::MessageIter ri = ret.reader();

        ri >> offset;
        ri >> travelTime;
        ri >> direction;
        ri >> side;
        ri >> timeZone;
        ri >> daylightSavingTime;
    }

    void GetManeuversList(const uint16_t& requestedNumberOfManeuvers, const uint32_t& maneuverOffset, uint16_t& numberOfManeuvers, std::vector< ::DBus::Struct< std::string, std::string, uint16_t, int32_t, uint32_t, std::vector< ::DBus::Struct< uint32_t, uint32_t, int32_t, int32_t, std::map< int32_t, ::DBus::Struct< uint8_t, ::DBus::Variant > > > > > >& maneuversList)
    {
        ::DBus::CallMessage call;
        ::DBus::MessageIter wi = call.writer();

        wi << requestedNumberOfManeuvers;
        wi << maneuverOffset;
        call.member("GetManeuversList");
        ::DBus::Message ret = invoke_method (call);
        ::DBus::MessageIter ri = ret.reader();

        ri >> numberOfManeuvers;
        ri >> maneuversList;
    }

    void SetRouteCalculationMode(const uint32_t& sessionHandle, const int32_t& routeCalculationMode)
    {
        ::DBus::CallMessage call;
        ::DBus::MessageIter wi = call.writer();

        wi << sessionHandle;
        wi << routeCalculationMode;
        call.member("SetRouteCalculationMode");
        ::DBus::Message ret = invoke_method (call);
    }

    void SkipNextManeuver(const uint32_t& sessionHandle)
    {
        ::DBus::CallMessage call;
        ::DBus::MessageIter wi = call.writer();

        wi << sessionHandle;
        call.member("SkipNextManeuver");
        ::DBus::Message ret = invoke_method (call);
    }

    void GetGuidanceStatus(int32_t& guidanceStatus, uint32_t& routeHandle)
    {
        ::DBus::CallMessage call;
        call.member("GetGuidanceStatus");
        ::DBus::Message ret = invoke_method (call);
        ::DBus::MessageIter ri = ret.reader();

        ri >> guidanceStatus;
        ri >> routeHandle;
    }

    void SetVoiceGuidanceSettings(const int32_t& promptMode)
    {
        ::DBus::CallMessage call;
        ::DBus::MessageIter wi = call.writer();

        wi << promptMode;
        call.member("SetVoiceGuidanceSettings");
        ::DBus::Message ret = invoke_method (call);
    }

    int32_t GetVoiceGuidanceSettings()
    {
        ::DBus::CallMessage call;
        call.member("GetVoiceGuidanceSettings");
        ::DBus::Message ret = invoke_method (call);
        ::DBus::MessageIter ri = ret.reader();

        int32_t argout;
        ri >> argout;
        return argout;
    }


public:

    /* signal handlers for this interface
     */
    virtual void VehicleLeftTheRoadNetwork() = 0;
    virtual void GuidanceStatusChanged(const int32_t& guidanceStatus, const uint32_t& routeHandle) = 0;
    virtual void WaypointReached(const bool& isDestination) = 0;
    virtual void ManeuverChanged(const int32_t& maneuver) = 0;
    virtual void PositionOnRouteChanged(const uint32_t& offsetOnRoute) = 0;
    virtual void VehicleLeftTheRoute() = 0;
    virtual void PositionToRouteChanged(const uint32_t& distance, const int32_t& direction) = 0;
    virtual void ActiveRouteChanged(const int32_t& changeCause) = 0;

private:

    /* unmarshalers (to unpack the DBus message before calling the actual signal handler)
     */
    void _VehicleLeftTheRoadNetwork_stub(const ::DBus::SignalMessage &sig)
    {
        VehicleLeftTheRoadNetwork();
    }
    void _GuidanceStatusChanged_stub(const ::DBus::SignalMessage &sig)
    {
        ::DBus::MessageIter ri = sig.reader();

        int32_t guidanceStatus;
        ri >> guidanceStatus;
        uint32_t routeHandle;
        ri >> routeHandle;
        GuidanceStatusChanged(guidanceStatus, routeHandle);
    }
    void _WaypointReached_stub(const ::DBus::SignalMessage &sig)
    {
        ::DBus::MessageIter ri = sig.reader();

        bool isDestination;
        ri >> isDestination;
        WaypointReached(isDestination);
    }
    void _ManeuverChanged_stub(const ::DBus::SignalMessage &sig)
    {
        ::DBus::MessageIter ri = sig.reader();

        int32_t maneuver;
        ri >> maneuver;
        ManeuverChanged(maneuver);
    }
    void _PositionOnRouteChanged_stub(const ::DBus::SignalMessage &sig)
    {
        ::DBus::MessageIter ri = sig.reader();

        uint32_t offsetOnRoute;
        ri >> offsetOnRoute;
        PositionOnRouteChanged(offsetOnRoute);
    }
    void _VehicleLeftTheRoute_stub(const ::DBus::SignalMessage &sig)
    {
        VehicleLeftTheRoute();
    }
    void _PositionToRouteChanged_stub(const ::DBus::SignalMessage &sig)
    {
        ::DBus::MessageIter ri = sig.reader();

        uint32_t distance;
        ri >> distance;
        int32_t direction;
        ri >> direction;
        PositionToRouteChanged(distance, direction);
    }
    void _ActiveRouteChanged_stub(const ::DBus::SignalMessage &sig)
    {
        ::DBus::MessageIter ri = sig.reader();

        int32_t changeCause;
        ri >> changeCause;
        ActiveRouteChanged(changeCause);
    }
};

} } } 
#endif //__dbusxx___home_fifi_Bureau_genivi_navigation_src_navigation_build_dbus_include_navigation_core_genivi_navigationcore_guidance_proxy_h__PROXY_MARSHAL_H
