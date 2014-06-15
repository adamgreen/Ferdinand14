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

    m_failedInit = m_accel.didInitFail() || m_mag.didInitFail() || m_gyro.didInitFail();
    m_failedIo = m_failedInit;
}


SensorReadings Sparkfun9DoFSensorStick::getSensorReadings()
{
    SensorReadings sensorReadings;

    // Assume I/O failed unless we complete everything successfully and then clear this flag.
    m_failedIo = 1;
    do
    {
        // Oversample the accelerometer.
        for (int i = 0 ; i < 32 ; i++)
        {
            IntVector<int16_t> sampleVector = m_accel.getVector();
            if (m_accel.didIoFail())
                break;
            sensorReadings.m_accel.add(&sampleVector);
        }

        sensorReadings.m_mag = m_mag.getVector();
        if (m_mag.didIoFail())
            break;

        sensorReadings.m_gyro = m_gyro.getVector();
        if (m_gyro.didIoFail())
            break;

        // If we got here then all reads were successful.
        m_failedIo = 0;
    } while (0);

    return sensorReadings;
}
