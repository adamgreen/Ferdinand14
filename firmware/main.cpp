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
#include <assert.h>
#include <mbed.h>
#include "DmaSerial.h"
#include "Sparkfun9DoFSensorStick.h"


int main()
{
    static Timer timer;
    timer.start();
#if !MRI_ENABLE
    static DmaSerial pc(USBTX, USBRX);
    pc.baud(230400);
#endif // !MRI_ENABLE

    static Sparkfun9DoFSensorStick sensorStick(p9, p10);
    if (sensorStick.didInitFail())
        error("Encountered I2C I/O error during Sparkfun 9DoF Sensor Stick init.\n");

    for (;;)
    {
        // String buffer for ten 16-bit integer sensor readings, one 32-bit time integer, ten comma separators,
        // and one '\0' terminator.
        char buffer[10*6 + 1*11 + 10 + 1];
        int  length;

        SensorReadings sensorReadings = sensorStick.getSensorReadings();
        if (sensorStick.didIoFail())
            error("Encountered I2C I/O error during fetch of Sparkfun 9DoF Sensor Stick readings.\n");

        int elapsedTime = timer.read_us();
        timer.reset();
        length = snprintf(buffer, sizeof(buffer), "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",
                          sensorReadings.m_accel.m_x, sensorReadings.m_accel.m_y, sensorReadings.m_accel.m_z,
                          sensorReadings.m_mag.m_x, sensorReadings.m_mag.m_y, sensorReadings.m_mag.m_z,
                          sensorReadings.m_gyro.m_x, sensorReadings.m_gyro.m_y, sensorReadings.m_gyro.m_z,
                          sensorReadings.m_gyroTemperature,
                          elapsedTime);
        assert( length < (int)sizeof(buffer) );

#if MRI_ENABLE
        printf("%s", buffer);
#else
        pc.dmaTransmit(buffer, length);
#endif
    }

    return 0;
}
