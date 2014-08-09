/*  Copyright (C) 2014  Adam Green (https://github.com/adamgreen)

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
*/
#include "Sparkfun9DoFSensorStick.h"


Sparkfun9DoFSensorStick::Sparkfun9DoFSensorStick(PinName sdaPin, PinName sclPin) :
    m_i2c(sdaPin, sclPin),
    m_accel(&m_i2c),
    m_mag(&m_i2c),
    m_gyro(&m_i2c)
{
    m_i2c.frequency(400000);
    m_failedIo = 0;
    m_failedInit = 0;
    m_currentSample = 0;
    m_lastSample = 0;

    m_failedInit = m_accel.didInitFail() || m_mag.didInitFail() || m_gyro.didInitFail();
    m_failedIo = m_failedInit;
    if (!m_failedInit)
        m_ticker.attach_us(this, &Sparkfun9DoFSensorStick::tickHandler, 1000000 / 100);
}


void Sparkfun9DoFSensorStick::tickHandler()
{
    // Assume I/O failed unless we complete everything successfully and then clear this flag.
    int failedIo = 1;

    do
    {
        m_accel.getVector(&m_sensorReadings.m_accel);
        if (m_accel.didIoFail())
            break;

        m_mag.getVector(&m_sensorReadings.m_mag);
        if (m_mag.didIoFail())
            break;

        m_gyro.getVector(&m_sensorReadings.m_gyro, &m_sensorReadings.m_gyroTemperature);
        if (m_gyro.didIoFail())
            break;

        m_currentSample++;

        // If we got here then all reads were successful.
        failedIo = 0;
    } while (0);

    m_failedIo = failedIo;
}


SensorReadings Sparkfun9DoFSensorStick::getSensorReadings()
{
    uint32_t       currentSample;
    SensorReadings sensorReadings;

    // Wait for next sample to become available.
    do
    {
        currentSample = m_currentSample;
    } while (currentSample == m_lastSample);
    m_lastSample = currentSample;

    __disable_irq();
        memcpy(&sensorReadings, &m_sensorReadings, sizeof(sensorReadings));
    __enable_irq();

    return sensorReadings;
}
