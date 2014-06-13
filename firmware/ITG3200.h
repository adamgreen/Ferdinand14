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
#ifndef ITG3200_H_
#define ITG3200_H_

#include <mbed.h>
#include "Int16Vector.h"


class ITG3200
{
public:
    ITG3200(I2C* pI2C, int address = 0xD0);

    int         didInitFail() { return m_failedInit; }
    int         didIoFail() { return m_failedIo; }
    Int16Vector getVector();

protected:
    void initGyro();
    void writeGyroRegister(char registerAddress, char value);
    void writeRegister(int i2cAddress, char registerAddress, char value);
    void waitForPllReady();
    void waitForDataReady();
    void readGyroRegister(char registerAddress, void* pBuffer);
    void readRegisters(int i2cAddress, char registerAddress, void* pBuffer, size_t bufferSize);
    void readGyroRegisters(char registerAddress, void* pBuffer, size_t bufferSize);

    I2C*    m_pI2C;
    int     m_failedInit;
    int     m_failedIo;
    int     m_address;
};

#endif /* ITG3200_H_ */
