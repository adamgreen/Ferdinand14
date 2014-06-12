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
#include "ADXL345.h"
#include "HMC5883L.h"
#include "Int32Vector.h"

template<class T>
void printVector(T* pVector)
{
    printf("%ld,%ld,%ld", (int32_t)pVector->m_x, (int32_t)pVector->m_y, (int32_t)pVector->m_z);
}


int main()
{
    static I2C     i2c(p9, p10);
    i2c.frequency(400000);

    static ADXL345  accelerometer(&i2c);
    if (accelerometer.didInitFail())
        error("Encountered I2C I/O error during accelerometer init.\n");

    static HMC5883L magnetometer(&i2c);
    if (magnetometer.didInitFail())
        error("Encountered I2C I/O error during magnetometer init.\n");

    for (;;)
    {
        Int32Vector accelerometerVector;

        for (int i = 0 ; i < 32 ; i++)
        {
            Int16Vector sampleVector = accelerometer.getVector();
            if (accelerometer.didIoFail())
                error("Encountered I2C I/O error during accelerometer vector fetch.\n");
            accelerometerVector.add(&sampleVector);
        }
        printVector(&accelerometerVector);
        printf(",");

        Int16Vector magnetometerVector = magnetometer.getVector();
        if (magnetometer.didIoFail())
            error("Encountered I2C I/O error during magnetometer vector fetch.\n");
        printVector(&magnetometerVector);
        printf("\n");
    }

    return 0;
}
