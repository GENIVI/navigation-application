/**
* @licence app begin@
* SPDX license identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroën
*
* \file ctripcomputer.h
*
* \brief This file is part of lbs-fuel-stop-advisor.
*        It contains the declaration of the trip computer class
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \version 0.1
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
* <date>, <name>, <description of change>
* <date>, <name>, <description of change>
*
* @licence end@
*/

#ifndef CTRIPCOMPUTER_H
#define CTRIPCOMPUTER_H

#include "ctripcomputertypes.h"


#define GET_UNDEFINED_VALUE(a) (static_cast<typeof(a)>(pow(2,8*pow(2,sizeof(a)))-1))

class CTripComputer
{
public:
    enum TRIPCOMPUTER_Constants {
        TRIPCOMPUTER_ODOMETER = 0x0020,
        TRIPCOMPUTER_FUEL_LEVEL = 0x0021,
        TRIPCOMPUTER_DISTANCE = 0x0030,
        TRIPCOMPUTER_TIME = 0x0031,
        TRIPCOMPUTER_AVERAGE_FUEL_CONSUMPTION_PER_DISTANCE = 0x0032,
        TRIPCOMPUTER_AVERAGE_SPEED = 0x0033,
        TRIPCOMPUTER_TANK_DISTANCE = 0x0034,
        TRIPCOMPUTER_INSTANT_FUEL_CONSUMPTION_PER_DISTANCE = 0x0035
    };

    enum {
        TRIP_NUMBER = 2,
        TRIP_NUMBER_1 = 0,
        SAMPLING_TIME = 1, /*!< Sampling time of 1 sec. */
        INSTANT_FUEL_CONSUMPTION_COEFFICIENT = 10/SAMPLING_TIME, /*!< Time constant for the instant fuel consumption. */
        LAST_QUARTER_FUEL_CONSUMPTION_COEFFICIENT = 90/SAMPLING_TIME, /*!< Time constant for the last quarter fuel consumption. */
        DISTANCE_THRESHOLD = 40000, /*!< Threshold for trip data calculation in cm. */
        INSTANT_FUEL_CONSUMPTION_MAX_VALUE = 300, /*!< in tenth of liters per 100 km. */
        INSTANT_FUEL_CONSUMPTION_START_VALUE = 50, /*!< To set an initial value of 50 µl/m (5 l/100), in order to avoid wrong tank distance the first time. */
        CONVERT_SECOND_IN_MILLISECOND = 1000,
        CONVERT_HOUR_IN_SECOND = 3600,
        CONVERT_METER_IN_CENTIMER = 100,
        CONVERT_KM_IN_METER = 1000,
        CONVERT_KM_IN_HM = 10,
        CONVERT_100KM_IN_CM = 100*CONVERT_KM_IN_METER*CONVERT_METER_IN_CENTIMER,
        CONVERT_LITER_IN_MICROLITER = 1000000,
        CONVERT_LITER_IN_DL = 10,
        CONVERT_DL_IN_MICROLITER = CONVERT_LITER_IN_MICROLITER/CONVERT_LITER_IN_DL
    };

    /*!
     *  \brief Constructor.
     *
     */
    CTripComputer();

    /*!
     *  \brief Initialization.
     *
     */
    void Initialize(uint16_t instantFuelConsumptionStartValue);

    /*!
     *  \brief Refresh the input values of the trips, calculate and update the trip number output values
     *
     *  \param tripComputerInput : basic input data
     */
    void RefreshTripComputerInput(tripComputerInput_t tripComputerInput);

    /*!
     *  \brief Get the version of the trip computer
     *
     *  \return The version
     */
    version_t GetVersion();

    /*!
     *  \brief Get the supported trip numbers
     *
     *   \return Supported trip numbers
     */
    uint8_t GetSupportedTripNumbers();

    /*!
     *  \brief Get the trip values of a given trip number
     *
     *  \param number : number of the trip
     *
     *  \return dictionary of trip values
     */
    tupleVariantTripComputer_t GetTripData(const uint8_t &number);

    /*!
     *  \brief Get the data not depending of a trip
     *
     *
     *  \return dictionary of trip values
     */
    tupleVariantTripComputer_t GetInstantData();

    /*!
     *  \brief Reset a given trip
     *
     *  \param number : number of the trip
     *
     */
    void ResetTrip(const uint8_t &number);

    /*!
     *  \brief Set the units used for each value
     *
     *  \param data : dictionary of unit per value
     *
     */
    void SetUnits(const tupleUint16_t &data);

    /*!
     *  \brief Get the basic data of a given trip (for testing)
     *
     *  \param number : number of the trip
     *
     *  \return trip data
     */
    tripBasicData_t GetTripBasicData(const uint8_t &number);


private:
    version_t m_version;
    uint8_t m_tripNumbers;
    vector<trip_t> m_tripData;
    tupleUint16_t m_units;
    bool m_firstRefresh;
    tripComputerInput_t m_lastTripComputerInput;
};

#endif // CTRIPCOMPUTER_H
