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
#ifndef ADXL345_H_
#define ADXL345_H_

#include <mbed.h>
#include "Int16Vector.h"


class ADXL345
{
public:
    ADXL345(I2C* pI2C, int address = 0xA6);

    int         didInitFail() { return m_failedInit; }
    int         didIoFail() { return m_failedIo; }
    Int16Vector getVector();

protected:
    void initAccelerometer();
    void writeAccelerometerRegister(char registerAddress, char value);
    void writeRegister(int i2cAddress, char registerAddress, char value);
    void waitForDataReady();
    void readAccelerometerRegister(char registerAddress, void* pBuffer);
    void readRegisters(int i2cAddress, char registerAddress, void* pBuffer, size_t bufferSize);
    void readAccelerometerRegisters(char registerAddress, void* pBuffer, size_t bufferSize);

    I2C*    m_pI2C;
    Ticker  m_ticker;
    int     m_failedInit;
    int     m_failedIo;
    int     m_address;
};

#endif /* ADXL345_H_ */
