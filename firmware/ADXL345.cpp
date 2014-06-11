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
#include "ADXL345.h"


/* Accelerometer I2C Registers */
#define DEVID               0x00
#define THRESH_TAP          0x1D
#define OFSX                0x1E
#define OFSY                0x1F
#define OFSZ                0x20
#define DUR                 0x21
#define LATENT              0x22
#define WINDOW              0x23
#define THRESH_ACT          0x24
#define THRESH_INACT        0x25
#define TIME_INACT          0x26
#define ACT_INACT_CTL       0x27
#define THRESH_FF           0x28
#define TIME_FF             0x29
#define TAP_AXES            0x2A
#define ACT_TAP_STATUS      0x2B
#define BW_RATE             0x2C
#define POWER_CTL           0x2D
#define INT_ENABLE          0x2E
#define INT_MAP             0x2F
#define INT_SOURCE          0x30
#define DATA_FORMAT         0x31
#define DATAX0              0x32
#define DATAX1              0x33
#define DATAY0              0x34
#define DATAY1              0x35
#define DATAZ0              0x36
#define DATAZ1              0x37
#define FIFO_CTL            0x38
#define FIFO_STATUS         0x39

/* BW_RATE bits */
#define LOW_POWER           (1 << 4)
#define RATE_MASK           0x0F
#define RATE_6_25           0x6
#define RATE_12_5           0x7
#define RATE_25             0x8
#define RATE_50             0x9
#define RATE_100            0xA
#define RATE_200            0xB
#define RATE_400            0xC
#define RATE_800            0xD
#define RATE_1600           0xE
#define RATE_3200           0xF

/* POWER_CTL bits */
#define LINK                (1 << 5)
#define AUTO_SLEEP          (1 << 4)
#define MEASURE             (1 << 3)
#define SLEEP               (1 << 2)
#define WAKEUP_MASK         0x3
#define WAKEUP_8HZ          0x0
#define WAKEUP_4HZ          0x1
#define WAKEUP_2HZ          0x2
#define WAKEUP_1HZ          0x3

/* INT_SOURCE bits */
#define DATA_READY          (1 << 7)
#define SINGLE_TAP          (1 << 6)
#define DOUBLE_TAP          (1 << 5)
#define ACTIVITY            (1 << 4)
#define INACTIVITY          (1 << 3)
#define FREE_FALL           (1 << 2)
#define WATERMARK           (1 << 1)
#define OVERRUN             (1 << 0)

/* DATA_FORMAT bits */
#define SELF_TEST           (1 << 7)
#define SPI_BIT             (1 << 6)
#define INT_INVERT          (1 << 5)
#define FULL_RES            (1 << 3)
#define JUSTIFY             (1 << 2)
#define RANGE_MASK          0x3
#define RANGE_2G            0x0
#define RANGE_4G            0x1
#define RANGE_8G            0x2
#define RANGE_16G           0x3


ADXL345::ADXL345(I2C* pI2C, int address /* = 0xA6 */)
{
    m_pI2C = pI2C;
    m_address = address;
    initAccelerometer();
}

void ADXL345::initAccelerometer()
{
    do
    {
        writeAccelerometerRegister(BW_RATE, RATE_3200);
        if (m_failedIo)
            break;
        writeAccelerometerRegister(DATA_FORMAT, FULL_RES | RANGE_16G);
        if (m_failedIo)
            break;
        writeAccelerometerRegister(POWER_CTL, MEASURE);
        if (m_failedIo)
            break;
    }
    while (0);

    if (m_failedIo)
        m_failedInit = 1;
}

void ADXL345::writeAccelerometerRegister(char registerAddress, char value)
{
    writeRegister(m_address, registerAddress, value);
}

void ADXL345::writeRegister(int i2cAddress, char registerAddress, char value)
{
    char dataToSend[2] = { registerAddress, value };
    
    m_failedIo = m_pI2C->write(i2cAddress, dataToSend, sizeof(dataToSend), false);
}

Int16Vector ADXL345::getVector()
{
    Int16Vector vector;

    waitForDataReady();
    readAccelerometerRegisters(DATAX0, &vector, sizeof(vector));

    return vector;
}

void ADXL345::waitForDataReady()
{
    char intStatus = 0;

    do
    {
        readAccelerometerRegister(INT_SOURCE, &intStatus);
    } while ((intStatus & DATA_READY) == 0);
}

void ADXL345::readAccelerometerRegister(char registerAddress, void* pBuffer)
{
    readRegisters(m_address, registerAddress, pBuffer, 1);
}

void ADXL345::readRegisters(int i2cAddress, char registerAddress, void* pBuffer, size_t bufferSize)
{
    m_failedIo = m_pI2C->write(i2cAddress, &registerAddress, sizeof(registerAddress), true);
    if (m_failedIo)
        return;
    m_failedIo = m_pI2C->read(i2cAddress, (char*)pBuffer, bufferSize, false);
}

void ADXL345::readAccelerometerRegisters(char registerAddress, void* pBuffer, size_t bufferSize)
{
    readRegisters(m_address, registerAddress, pBuffer, bufferSize);
}
