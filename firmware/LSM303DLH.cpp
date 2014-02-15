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
#include "LSM303DLH.h"


/* I2C Addresses for Accelerometer and Magnetometer in LSM303DLH */
#define I2C_ADDRESS_ACCEL_BASE 0x30
#define I2C_ADDRESS_MAG        0x3C

/* LSM303DLH Accelerometer I2C Registers */
#define CTRL_REG1_A         0x20
#define CTRL_REG2_A         0x21
#define CTRL_REG3_A         0x22
#define CTRL_REG4_A         0x23
#define CTRL_REG5_A         0x24
#define HP_FILTER_RESET_A   0x25
#define REFERENCE_A         0x26
#define STATUS_REG_A        0x27
#define OUT_X_L_A           0x28
#define OUT_X_H_A           0x29
#define OUT_Y_L_A           0x2a
#define OUT_Y_H_A           0x2b
#define OUT_Z_L_A           0x2c
#define OUT_Z_H_A           0x2d
#define INT1_CFG_A          0x30
#define INT1_SOURCE_A       0x31
#define INT1_THS_A          0x32
#define INT1_DURATION_A     0x33
#define INT2_CFG_A          0x34
#define INT2_SOURCE_A       0x35
#define INT2_THS_A          0x36
#define INT2_DURATION_A     0x37

/* LSM303DLH Magnetometer I2C Registers */
#define CRA_REG_M           0x00
#define CRB_REG_M           0x01
#define MR_REG_M            0x02
#define OUT_X_H_M           0x03
#define OUT_X_L_M           0x04
#define OUT_Y_H_M           0x05
#define OUT_Y_L_M           0x06
#define OUT_Z_H_M           0x07
#define OUT_Z_L_M           0x08
#define SR_REG_M            0x09
#define IRA_REG_M           0x0a
#define IRB_REG_M           0x0b
#define IRC_REG_M           0x0c


LSM303DLH::LSM303DLH(PinName sdaPin, PinName sclPin, int sa0PinValue /* = 0 */, int i2cFrequency /* = 100000 */) :
    m_i2c(sdaPin, sclPin), m_failedInit(0), m_failedIo(0)
{
    m_i2c.frequency(i2cFrequency);
    m_accelAddress = sa0PinValue ? I2C_ADDRESS_ACCEL_BASE | 2 : I2C_ADDRESS_ACCEL_BASE;
    initDevice();
}

void LSM303DLH::initDevice()
{
    initAccelerometer();
    initMagnetometer();
}

void LSM303DLH::initAccelerometer()
{
    do
    {
        static const char normalPowerMode = 0x1 << 5;
        static const char sampleAt50Hz = 0x0 << 3;
        static const char enableAll = 0x7 << 0;
        writeAccelerometerRegister(CTRL_REG1_A, normalPowerMode | sampleAt50Hz | enableAll);
        if (m_failedIo)
            break;
    
        static const char blockDataUpdate = 0x1 << 7;
        static const char littleEndian = 0x0 << 6;
        static const char fullScale2G = 0x0 << 4;
        writeAccelerometerRegister(CTRL_REG4_A, blockDataUpdate | littleEndian | fullScale2G);
        if (m_failedIo)
        break;
    }
    while (0);

    if (m_failedIo)
        m_failedInit = 1;
}

void LSM303DLH::writeAccelerometerRegister(char registerAddress, char value)
{
    writeRegister(m_accelAddress, registerAddress, value);
}

void LSM303DLH::writeRegister(int i2cAddress, char registerAddress, char value)
{
    char dataToSend[2] = { registerAddress, value };
    
    m_failedIo = m_i2c.write(i2cAddress, dataToSend, sizeof(dataToSend), false);
}

void LSM303DLH::initMagnetometer()
{
    do
    {
        static const char dataRate30Hz = 0x5 << 2;
        writeMagnetometerRegister(CRA_REG_M, dataRate30Hz);
        if (m_failedIo)
            break;
    
        static const char range1_3Gauss = 0x1 << 5;
        writeMagnetometerRegister(CRB_REG_M, range1_3Gauss);
        if (m_failedIo)
        break;
        
        static const char continuousConversion = 0x0 << 0;
        writeMagnetometerRegister(MR_REG_M, continuousConversion);
        if (m_failedIo)
        break;
    }
    while (0);

    if (m_failedIo)
        m_failedInit = 1;
}

void LSM303DLH::writeMagnetometerRegister(char registerAddress, char value)
{
    writeRegister(I2C_ADDRESS_MAG, registerAddress, value);
}

Int16Vector LSM303DLH::getAccelerometerVector()
{
    Int16Vector vector;

    readAccelerometerRegisters(OUT_X_L_A, &vector, sizeof(vector));

    return vector;
}

void LSM303DLH::readAccelerometerRegisters(char registerAddress, void* pBuffer, size_t bufferSize)
{
    static const char multipleRegisterReadBit = 1 << 7;
    
    registerAddress |= multipleRegisterReadBit;
    readRegisters(m_accelAddress, registerAddress, pBuffer, bufferSize);
}

void LSM303DLH::readRegisters(int i2cAddress, char registerAddress, void* pBuffer, size_t bufferSize)
{
    m_failedIo = m_i2c.write(i2cAddress, &registerAddress, sizeof(registerAddress), true);
    if (m_failedIo)
        return;
    m_failedIo = m_i2c.read(i2cAddress, (char*)pBuffer, bufferSize, false);
}

Int16Vector LSM303DLH::getMagnetometerVector()
{
    char byteArray[6];

    readMagnetometerRegisters(OUT_X_H_M, byteArray, sizeof(byteArray));
    
    return convertMagnetometerBytesToVector(byteArray);
}

void LSM303DLH::readMagnetometerRegisters(char registerAddress, void* pBuffer, size_t bufferSize)
{
    readRegisters(I2C_ADDRESS_MAG, registerAddress, pBuffer, bufferSize);
}

Int16Vector LSM303DLH::convertMagnetometerBytesToVector(char byteArray[])
{
    // Swap bytes for each axis.
    int16_t x = (byteArray[0] << 8) | byteArray[1];
    int16_t y = (byteArray[2] << 8) | byteArray[3];
    int16_t z = (byteArray[4] << 8) | byteArray[5];
    
    return Int16Vector(x, y, z);
}
