/**
* @licence app begin@
* SPDX license identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroën
*
* \file ctripcomputertypes.h
*
* \brief This file is part of lbs-fuel-stop-advisor.
*        It contains the declaration of types used by the trip computer class
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
#ifndef CTRIPCOMPUTERTYPES_H
#define CTRIPCOMPUTERTYPES_H

#include <stdint.h>
#include <map>
#include <vector>
#include <math.h>
#include <limits.h>

#include <boost/variant/variant.hpp>

using namespace std;

/**
 * \union variantTripComputer_t
 * \brief Variant used for the trip computer output values (of different types).
 *
 */
typedef boost::variant<uint32_t,uint16_t> variantTripComputer_t;

/**
 * \union tupleVariantTripComputer_t
 * \brief Dictionary for getting the trip computer output values.
 *
 */
typedef map<uint16_t,variantTripComputer_t > tupleVariantTripComputer_t;

/**
 * \union tupleUint16_t
 * \brief Dictionary for setting the trip computer units.
 *
 */
typedef map<uint16_t,uint16_t> tupleUint16_t;

/**
 * \struct version_t
 * \brief Version.
 *
 */
typedef struct
{
    uint16_t major; /*!< Major. */
    uint16_t minor; /*!< Minor. */
    uint16_t micro; /*!< Micro. */
    string date; /*!< Date. */
} version_t;

/**
 * \struct tripComputerInput_t
 * \brief Input data for the trip computer.
 *
 */
typedef struct
{
    uint16_t fuelLevel; /*!< Fuel level in tenth of liter. */
    uint16_t time; /*!< Time in ms, rolling counter. */
    uint16_t distance; /*!< Distance in cm, rolling counter. */
    uint16_t fuelConsumption; /*!< Fuel consumption in µliter per sec. */
} tripComputerInput_t;

/**
 * \struct tripBasicData_t
 * \brief Basic stored data of a trip.
 *        The calculation doesn't use float, so it's needed to keep the remainders
 *
 */
typedef struct
{ //
    uint64_t tripTime; /*!< Total trip time in ms. */
    uint64_t tripDistance; /*!< Total trip traveled distance in cm. */
    uint64_t tripFuel; /*!< Total trip fuel consumption in µliters. */
    uint16_t instantAveragedFuelConsumptionPerDistance; /*!< Instant averaged in µliters per m. */
    uint16_t instantAveragedFuelConsumptionPerDistanceRemainder; /*!< Remainder of instant averaged calculation. */
    uint16_t lastQuarterAveragedFuelConsumptionPerDistance; /*!< Last quarter averaged in µliters per m. */
    uint16_t lastQuarterAveragedFuelConsumptionPerDistanceRemainder; /*!< Remainder of last quarter averaged calculation. */
    uint16_t fuelRemainder; /*!< Fuel remainder. */
} tripBasicData_t;

/**
 * \struct trip_t
 * \brief Displayed data of a trip.
 *
 */
typedef struct
{
    uint16_t distance; /*!< In tenth of kilometers. */
    uint32_t time; /*!< In seconds. */
    uint16_t averageFuelConsumptionPerDistance; /*!< In tenth of liters per 100 kilometers. */
    uint16_t averageSpeed; /*!< In tenth of kilometers per hour. */
    uint16_t tankDistance; /*!< In kilometers. */
    uint16_t instantFuelConsumptionPerDistance; /*!< In tenth of liters per 100 kilometers. */
    tripBasicData_t tripBasicData;
} trip_t;

#endif // CTRIPCOMPUTERTYPES_H
