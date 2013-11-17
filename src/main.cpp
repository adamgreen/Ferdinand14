/*  Copyright (C) 2013  Adam Green (https://github.com/adamgreen)

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
#include "LSM303DLM.h"


void printVector(Int16Vector* pVector);


int main() 
{
    static LSM303DLM lsm303dlm(p9, p10);
    
    if (lsm303dlm.didInitFail())
        error("Encountered I2C I/O error during init.\n");
    
    for (;;)
    {
        Int16Vector accelerometerVector = lsm303dlm.getAccelerometerVector();
        if (lsm303dlm.didIoFail())
            error("Encountered I2C I/O error during accelerometer vector fetch.\n");
        printVector(&accelerometerVector);
        printf(" ");

        Int16Vector magnetometerVector = lsm303dlm.getMagnetometerVector();
        if (lsm303dlm.didIoFail())
            error("Encountered I2C I/O error during magnetometer vector fetch.\n");
        printVector(&magnetometerVector);
        printf("\n");
    }
    
    return 0;
}

void printVector(Int16Vector* pVector)
{
    printf("%d,%d,%d", pVector->m_x, pVector->m_y, pVector->m_z);
}
