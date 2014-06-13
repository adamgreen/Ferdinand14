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
#ifndef HMC5883L_H_
#define HMC5883L_H_

#include <mbed.h>
#include "Int16Vector.h"


class HMC5883L
{
public:
    HMC5883L(I2C* pI2C, int address = 0x3C);

    int         didInitFail() { return m_failedInit; }
    int         didIoFail() { return m_failedIo; }
    Int16Vector getVector();

protected:
    void initMagnetometer();
    void writeMagnetometerRegister(char registerAddress, char value);
    void writeRegister(int i2cAddress, char registerAddress, char value);
    void waitForDataReady();
    void readMagnetometerRegister(char registerAddress, void* pBuffer);
    void readRegisters(int i2cAddress, char registerAddress, void* pBuffer, size_t bufferSize);
    void readMagnetometerRegisters(char registerAddress, void* pBuffer, size_t bufferSize);

    I2C*    m_pI2C;
    int     m_failedInit;
    int     m_failedIo;
    int     m_address;
};

#endif /* HMC5883L_H_ */
