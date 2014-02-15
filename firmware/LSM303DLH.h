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
#ifndef LSM303DLH_H_
#define LSM303DLH_H_

#include <mbed.h>
#include "Int16Vector.h"


class LSM303DLH
{
public:
    LSM303DLH(PinName sdaPin, PinName sclPin, int sa0PinValue = 0, int i2cFrequency = 100000);
    
    int         didInitFail() { return m_failedInit; }
    int         didIoFail() { return m_failedIo; }
    Int16Vector getAccelerometerVector();
    Int16Vector getMagnetometerVector();
    
protected:
    void initDevice();
    void initAccelerometer();
    void writeAccelerometerRegister(char registerAddress, char value);
    void writeRegister(int i2cAddress, char registerAddress, char value);
    void initMagnetometer();
    void writeMagnetometerRegister(char registerAddress, char value);
    void readAccelerometerRegisters(char registerAddress, void* pBuffer, size_t bufferSize);
    void readMagnetometerRegisters(char registerAddress, void* pBuffer, size_t bufferSize);
    void readRegisters(int i2cAddress, char registerAddress, void* pBuffer, size_t bufferSize);
    Int16Vector convertMagnetometerBytesToVector(char byteArray[]);
    
    I2C     m_i2c;
    int     m_failedInit;
    int     m_failedIo;
    int     m_accelAddress;
};

#endif /* LSM303DLH_H_ */
