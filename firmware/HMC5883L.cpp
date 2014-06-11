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
#include "HMC5883L.h"


/* Magnetometer I2C Registers */
#define CONFIG_A            0x00
#define CONFIG_B            0x01
#define MODE                0x02
#define DATA_OUT_X_MSB      0x03
#define DATA_OUT_X_LSB      0x04
#define DATA_OUT_Z_MSB      0x05
#define DATA_OUT_Z_LSB      0x06
#define DATA_OUT_Y_MSB      0x07
#define DATA_OUT_Y_LSB      0x08
#define STATUS              0x09
#define ID_A                0x0A
#define ID_B                0x0B
#define ID_C                0x0C

/* CONFIG_A bits */
#define SAMPLES_SHIFT           5
#define SAMPLES_MASK            (3 << SAMPLES_SHIFT)
#define SAMPLES_1               (0 << SAMPLES_SHIFT)
#define SAMPLES_2               (1 << SAMPLES_SHIFT)
#define SAMPLES_4               (2 << SAMPLES_SHIFT)
#define SAMPLES_8               (3 << SAMPLES_SHIFT)
#define RATE_SHIFT              2
#define RATE_MASK               (7 << RATE_SHIFT)
#define RATE_0_75               (0 << RATE_SHIFT)
#define RATE_1_5                (1 << RATE_SHIFT)
#define RATE_3                  (2 << RATE_SHIFT)
#define RATE_7_5                (3 << RATE_SHIFT)
#define RATE_15                 (4 << RATE_SHIFT)
#define RATE_30                 (5 << RATE_SHIFT)
#define RATE_75                 (6 << RATE_SHIFT)
#define MEASUREMENT_MASK        3
#define MEASUREMENT_NORMAL      0
#define MEASUREMENT_POS_BIAS    1
#define MEASUREMENT_NEG_BIAS    2

/* CONFIG_B bits */
#define GAIN_SHIFT              5
#define GAIN_MASK               (7 << GAIN_SHIFT)
#define GAIN_0_88GA             (0 << GAIN_SHIFT)
#define GAIN_1_3GA              (1 << GAIN_SHIFT)
#define GAIN_1_9GA              (2 << GAIN_SHIFT)
#define GAIN_2_5GA              (3 << GAIN_SHIFT)
#define GAIN_4_0GA              (4 << GAIN_SHIFT)
#define GAIN_4_7GA              (5 << GAIN_SHIFT)
#define GAIN_5_6GA              (6 << GAIN_SHIFT)
#define GAIN_8_1GA              (7 << GAIN_SHIFT)

/* MODE bits */
#define MODE_MASK               3
#define MODE_CONTINUOUS         0
#define MODE_SINGLE             1
#define MODE_IDLE1              2
#define MODE_IDLE2              3

/* STATUS bits */
#define STATUS_LOCK             (1 << 1)
#define STATUS_RDY              (1 << 0)

HMC5883L::HMC5883L(I2C* pI2C, int address /* = 0x3C */)
{
    m_pI2C = pI2C;
    m_address = address;
    initMagnetometer();
}

void HMC5883L::initMagnetometer()
{
    do
    {
        writeMagnetometerRegister(CONFIG_A, SAMPLES_8 | MEASUREMENT_NORMAL);
        if (m_failedIo)
            break;
        writeMagnetometerRegister(CONFIG_B, GAIN_1_3GA);
        if (m_failedIo)
            break;
    }
    while (0);

    if (m_failedIo)
        m_failedInit = 1;
}

void HMC5883L::writeMagnetometerRegister(char registerAddress, char value)
{
    writeRegister(m_address, registerAddress, value);
}

void HMC5883L::writeRegister(int i2cAddress, char registerAddress, char value)
{
    char dataToSend[2] = { registerAddress, value };

    m_failedIo = m_pI2C->write(i2cAddress, dataToSend, sizeof(dataToSend), false);
}

Int16Vector HMC5883L::getVector()
{
    uint8_t     bigEndianData[6];
    Int16Vector vector;

    do
    {
        writeMagnetometerRegister(MODE, MODE_SINGLE);
        if (m_failedIo)
            break;

        wait_ms(6);

        readMagnetometerRegisters(DATA_OUT_X_MSB, &bigEndianData, sizeof(bigEndianData));
        if (m_failedIo)
            break;

        // Data returned from sensor is in big endian byte order with an axis order of X, Z, Y
        vector.m_x = (bigEndianData[0] << 8) | bigEndianData[1];
        vector.m_z = (bigEndianData[2] << 8) | bigEndianData[3];
        vector.m_y = (bigEndianData[4] << 8) | bigEndianData[5];
    } while (0);

    return vector;
}

void HMC5883L::readMagnetometerRegister(char registerAddress, void* pBuffer)
{
    readRegisters(m_address, registerAddress, pBuffer, 1);
}

void HMC5883L::readRegisters(int i2cAddress, char registerAddress, void* pBuffer, size_t bufferSize)
{
    m_failedIo = m_pI2C->write(i2cAddress, &registerAddress, sizeof(registerAddress), true);
    if (m_failedIo)
        return;
    m_failedIo = m_pI2C->read(i2cAddress, (char*)pBuffer, bufferSize, false);
}

void HMC5883L::readMagnetometerRegisters(char registerAddress, void* pBuffer, size_t bufferSize)
{
    readRegisters(m_address, registerAddress, pBuffer, bufferSize);
}
