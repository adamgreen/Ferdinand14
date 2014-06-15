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
#ifndef SPARKFUN_9DOF_SENSOR_STICK_H_
#define SPARKFUN_9DOF_SENSOR_STICK_H_

#include <mbed.h>
#include "ADXL345.h"
#include "HMC5883L.h"
#include "ITG3200.h"
#include "Int16Vector.h"
#include "Int32Vector.h"

typedef class SensorReadings
{
public:
    Int32Vector m_accel;
    Int16Vector m_mag;
    Int16Vector m_gyro;
} SensorReadings;


class Sparkfun9DoFSensorStick
{
public:
    Sparkfun9DoFSensorStick(PinName sdaPin, PinName sclPin);

    SensorReadings getSensorReadings();
    int didInitFail() { return m_failedInit; }
    int didIoFail() { return m_failedIo; }

protected:
    I2C      m_i2c;
    ADXL345  m_accel;
    HMC5883L m_mag;
    ITG3200  m_gyro;
    int      m_failedInit;
    int      m_failedIo;
};

#endif /* SPARKFUN_9DOF_SENSOR_STICK_H_ */
