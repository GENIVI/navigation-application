/**
* @licence app begin@
* SPDX license identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroën
*
* \file ctripcomputer.cpp
*
* \brief This file is part of lbs-fuel-stop-advisor.
*        It contains the implementation of the trip computer class
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

#include "ctripcomputer.h"
#include <stdio.h>

CTripComputer::CTripComputer()
{
    m_version.date = "11-08-2014";
    m_version.major = 1;
    m_version.minor = 0;
    m_version.micro = 0;

    m_tripNumbers = TRIP_NUMBER;
}


void CTripComputer::Initialize(uint16_t instantFuelConsumptionStartValue)
{
    trip_t tripData;

    tripData.tripBasicData.fuelRemainder = 0;
    tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistance = instantFuelConsumptionStartValue;
    tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistanceRemainder = 0;
    tripData.tripBasicData.instantAveragedFuelConsumptionPerDistance = instantFuelConsumptionStartValue;
    tripData.tripBasicData.instantAveragedFuelConsumptionPerDistanceRemainder = 0;
    tripData.tripBasicData.tripFuel = 0;
    tripData.tripBasicData.tripTime = 0;
    tripData.tripBasicData.tripDistance = 0;

    tripData.distance = GET_UNDEFINED_VALUE(tripData.distance);
    tripData.time = GET_UNDEFINED_VALUE(tripData.time);
    tripData.averageFuelConsumptionPerDistance = GET_UNDEFINED_VALUE(tripData.averageFuelConsumptionPerDistance);
    tripData.averageSpeed = GET_UNDEFINED_VALUE(tripData.averageSpeed);
    tripData.instantFuelConsumptionPerDistance = GET_UNDEFINED_VALUE(tripData.instantFuelConsumptionPerDistance);
    tripData.tankDistance = GET_UNDEFINED_VALUE(tripData.tankDistance);

    m_tripData.clear();
    m_tripData.push_back(tripData);
    m_tripData.push_back(tripData);

    m_firstRefresh = true; //used to avoid wrong value given by rolling counters
}

void CTripComputer::RefreshTripComputerInput(tripComputerInput_t tripComputerInput)
{ //all the calculation is made with integers (no float)
    trip_t tripData;
    uint32_t instantFuelConsumption;
    tripComputerInput_t deltaValue;
    uint64_t deltaFuel;

    if (m_firstRefresh)
    {
        m_firstRefresh = false;
        m_lastTripComputerInput = tripComputerInput;
    }
    else
    {
        //calculation of distance
        if (tripComputerInput.distance >= m_lastTripComputerInput.distance)
            deltaValue.distance = (tripComputerInput.distance - m_lastTripComputerInput.distance);
        else
            deltaValue.distance = (GET_UNDEFINED_VALUE(tripComputerInput.distance) - m_lastTripComputerInput.distance) + tripComputerInput.distance;

        //calculation of time
        if (tripComputerInput.time >= m_lastTripComputerInput.time)
            deltaValue.time = (tripComputerInput.time - m_lastTripComputerInput.time);
        else
            deltaValue.time = (GET_UNDEFINED_VALUE(tripComputerInput.time) - m_lastTripComputerInput.time) + tripComputerInput.time;

        //calculation of fuel consumption, area based
        if (tripComputerInput.fuelConsumption >= m_lastTripComputerInput.fuelConsumption)
        {
            deltaFuel = (((tripComputerInput.fuelConsumption - m_lastTripComputerInput.fuelConsumption)*deltaValue.time)/2 + (m_lastTripComputerInput.fuelConsumption*deltaValue.time))/CONVERT_SECOND_IN_MILLISECOND;
        }
        else
        {
            deltaFuel = (((m_lastTripComputerInput.fuelConsumption -tripComputerInput.fuelConsumption)*deltaValue.time)/2 + (tripComputerInput.fuelConsumption*deltaValue.time))/CONVERT_SECOND_IN_MILLISECOND;
        }

        m_lastTripComputerInput = tripComputerInput; //store it for the next time

        for (int index=0;index<m_tripData.size();index++)
        {
            tripData = m_tripData.at(index);

            //get the input values
            tripData.tripBasicData.tripTime += deltaValue.time; //in ms
            tripData.tripBasicData.tripDistance += deltaValue.distance; //in cm
            tripData.tripBasicData.tripFuel += deltaFuel; //in µliters

            tripData.time = tripData.tripBasicData.tripTime/CONVERT_SECOND_IN_MILLISECOND; //in seconds

            if (tripData.tripBasicData.tripDistance > DISTANCE_THRESHOLD)
            {
                if (tripData.tripBasicData.tripFuel > 0)
                {
                    //calculate the instant fuel consumption per distance in µliters per m, with remainder
                    instantFuelConsumption = ((deltaFuel*CONVERT_METER_IN_CENTIMER) + tripData.tripBasicData.fuelRemainder); //format adjustment and add the remainder of the last calculation
                    tripData.tripBasicData.fuelRemainder = instantFuelConsumption % deltaValue.distance; //save new remainder for next time
                    instantFuelConsumption = instantFuelConsumption / deltaValue.distance; //calculate the instant value (but loose the remainder)

                    //calculate instant fuel consumption per distance in µliters per m, (used by instant fuel consumption per distance) with a moving filter of coeff INSTANT_FUEL_CONSUMPTION_COEFFICIENT
                    tripData.tripBasicData.instantAveragedFuelConsumptionPerDistance = ((INSTANT_FUEL_CONSUMPTION_COEFFICIENT - 1)*tripData.tripBasicData.instantAveragedFuelConsumptionPerDistance)
                                                                   + instantFuelConsumption
                                                                   + tripData.tripBasicData.instantAveragedFuelConsumptionPerDistanceRemainder; //add the remainder of the last calculation
                    tripData.tripBasicData.instantAveragedFuelConsumptionPerDistanceRemainder = tripData.tripBasicData.instantAveragedFuelConsumptionPerDistance % INSTANT_FUEL_CONSUMPTION_COEFFICIENT;//save new remainder
                    tripData.tripBasicData.instantAveragedFuelConsumptionPerDistance = tripData.tripBasicData.instantAveragedFuelConsumptionPerDistance / INSTANT_FUEL_CONSUMPTION_COEFFICIENT; //calculate the averaged value (but loose the remainder)


                    //calculate the last quarter fuel consumption per distance (used by tank distance) in µliters per m, with a moving filter of coeff LAST_QUARTER_FUEL_CONSUMPTION_COEFFICIENT
                    //it uses the result of the first averaged instant fuel consumption per distance calculated above
                    tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistance = ((LAST_QUARTER_FUEL_CONSUMPTION_COEFFICIENT - 1)*tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistance)
                                                                   + tripData.tripBasicData.instantAveragedFuelConsumptionPerDistance
                                                                   + tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistanceRemainder; //add the remainder of the last calculation
                    tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistanceRemainder = tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistance % LAST_QUARTER_FUEL_CONSUMPTION_COEFFICIENT;//save new remainder
                    tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistance = tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistance / LAST_QUARTER_FUEL_CONSUMPTION_COEFFICIENT; //calculate the averaged value (but loose the remainder)

                    //calculate trip data
                    tripData.instantFuelConsumptionPerDistance = tripData.tripBasicData.instantAveragedFuelConsumptionPerDistance; //in tenth of liters per 100 km
                    if (tripData.instantFuelConsumptionPerDistance > INSTANT_FUEL_CONSUMPTION_MAX_VALUE)
                        tripData.instantFuelConsumptionPerDistance = INSTANT_FUEL_CONSUMPTION_MAX_VALUE;
                    tripData.averageSpeed = (tripData.tripBasicData.tripDistance*(CONVERT_HOUR_IN_SECOND/CONVERT_KM_IN_HM))/tripData.tripBasicData.tripTime; //in tenth of kilometers per hour
                    if (tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistance > 0)
                    {
                        tripData.tankDistance = ((tripComputerInput.fuelLevel*(CONVERT_DL_IN_MICROLITER/CONVERT_KM_IN_METER))/tripData.tripBasicData.lastQuarterAveragedFuelConsumptionPerDistance); //fuel level is in tenth of liters,tank distance is in kilometers
                    }
                    else
                    { //assume it never happens (because of INSTANT_FUEL_CONSUMPTION_START_VALUE)
                       tripData.tankDistance = GET_UNDEFINED_VALUE(tripData.tankDistance);
                    }
                    tripData.distance = tripData.tripBasicData.tripDistance/((CONVERT_KM_IN_METER*CONVERT_METER_IN_CENTIMER)/CONVERT_KM_IN_HM) ;//in tenth of kilometers
                    tripData.averageFuelConsumptionPerDistance = (tripData.tripBasicData.tripFuel*(CONVERT_100KM_IN_CM/CONVERT_DL_IN_MICROLITER))/tripData.tripBasicData.tripDistance; //in tenth of liters per 100 kilometers
                    if (tripData.averageFuelConsumptionPerDistance > INSTANT_FUEL_CONSUMPTION_MAX_VALUE)
                        tripData.averageFuelConsumptionPerDistance = INSTANT_FUEL_CONSUMPTION_MAX_VALUE;
                }
                else
                {
                    tripData.distance = tripData.tripBasicData.tripDistance/((CONVERT_KM_IN_METER*CONVERT_METER_IN_CENTIMER)/CONVERT_KM_IN_HM) ;//in tenth of kilometers
                }
            }
            m_tripData[index] = tripData;
        }

        m_lastTripComputerInput = tripComputerInput;

    }
}

version_t CTripComputer::GetVersion()
{
    return m_version;
}

uint8_t CTripComputer::GetSupportedTripNumbers()
{
   return m_tripNumbers;
}

tupleVariantTripComputer_t CTripComputer::GetTripData(const uint8_t &number)
{
    tupleVariantTripComputer_t data;
    variantTripComputer_t value;

    if (number < m_tripNumbers)
    {
        if (m_tripData.at(number).distance != GET_UNDEFINED_VALUE(m_tripData.at(number).distance))
        {
            value = m_tripData.at(number).distance;
            data[TRIPCOMPUTER_DISTANCE] = value;
        }
        if (m_tripData.at(number).time != GET_UNDEFINED_VALUE(m_tripData.at(number).time))
        {
            value = m_tripData.at(number).time;
            data[TRIPCOMPUTER_TIME] = value;
        }
        if (m_tripData.at(number).averageFuelConsumptionPerDistance != GET_UNDEFINED_VALUE(m_tripData.at(number).averageFuelConsumptionPerDistance))
        {
            value = m_tripData.at(number).averageFuelConsumptionPerDistance;
            data[TRIPCOMPUTER_AVERAGE_FUEL_CONSUMPTION_PER_DISTANCE] = value;
        }
        if (m_tripData.at(number).averageSpeed != GET_UNDEFINED_VALUE(m_tripData.at(number).averageSpeed))
        {
            value = m_tripData.at(number).averageSpeed;
            data[TRIPCOMPUTER_AVERAGE_SPEED] = value;
        }
    }

    return data;
}

tupleVariantTripComputer_t CTripComputer::GetInstantData()
{
    tupleVariantTripComputer_t data;
    //by default it takes the data from the trip number 1 (to be improved)
    if (m_tripData.at(TRIP_NUMBER_1).tankDistance != GET_UNDEFINED_VALUE(m_tripData.at(TRIP_NUMBER_1).tankDistance))
    {
        data[TRIPCOMPUTER_TANK_DISTANCE] = m_tripData.at(TRIP_NUMBER_1).tankDistance;
    }
    if (m_tripData.at(TRIP_NUMBER_1).instantFuelConsumptionPerDistance != GET_UNDEFINED_VALUE(m_tripData.at(TRIP_NUMBER_1).instantFuelConsumptionPerDistance))
    {
        data[TRIPCOMPUTER_INSTANT_FUEL_CONSUMPTION_PER_DISTANCE] = m_tripData.at(TRIP_NUMBER_1).instantFuelConsumptionPerDistance;
    }

    return data;
}

void CTripComputer::ResetTrip(const uint8_t &number)
{
    trip_t tripData;

    //note that the basic averaged fuel consumption per distance and the related remainder are kept !
    if (number < m_tripNumbers)
    {
        tripData = m_tripData[number]; //get the current value (to keep some stuff)
        tripData.tripBasicData.tripFuel = 0;
        tripData.tripBasicData.tripTime = 0;
        tripData.tripBasicData.tripDistance = 0;

        tripData.distance = GET_UNDEFINED_VALUE(tripData.distance);
        tripData.time = GET_UNDEFINED_VALUE(tripData.time);
        tripData.averageFuelConsumptionPerDistance = GET_UNDEFINED_VALUE(tripData.averageFuelConsumptionPerDistance);
        tripData.averageSpeed = GET_UNDEFINED_VALUE(tripData.averageSpeed);
        tripData.instantFuelConsumptionPerDistance = GET_UNDEFINED_VALUE(tripData.instantFuelConsumptionPerDistance);
        tripData.tankDistance = GET_UNDEFINED_VALUE(tripData.tankDistance);

        m_tripData[number] = tripData;
    }
}

void CTripComputer::SetUnits(const tupleInt32_t &data)
{
    //to do
    m_units = data;
}

tripBasicData_t CTripComputer::GetTripBasicData(const uint8_t &number)
{

    if (number < m_tripNumbers)
    {
        return((m_tripData[number]).tripBasicData);
    }
    else
    {
        return((m_tripData[0]).tripBasicData); //by default
    }
}
