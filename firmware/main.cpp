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
/* Test harness for my heading class. */
#include <mbed.h>
#include "Sparkfun9DoFSensorStick.h"

template<class T>
void printVector(T* pVector)
{
    printf("%ld,%ld,%ld", (int32_t)pVector->m_x, (int32_t)pVector->m_y, (int32_t)pVector->m_z);
}


int main()
{
    static Sparkfun9DoFSensorStick sensorStick(p9, p10);
    if (sensorStick.didInitFail())
        error("Encountered I2C I/O error during Sparkfun 9DoF Sensor Stick init.\n");

    for (;;)
    {
        SensorReadings sensorReadings = sensorStick.getSensorReadings();
        if (sensorStick.didIoFail())
            error("Encountered I2C I/O error during fetch of Sparkfun 9DoF Sensor Stick readings.\n");

        printVector(&sensorReadings.m_accel);
        printf(",");
        printVector(&sensorReadings.m_mag);
        printf(",");
        printVector(&sensorReadings.m_gyro);
        printf("\n");
    }

    return 0;
}
