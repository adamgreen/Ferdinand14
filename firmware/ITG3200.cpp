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
#include "ITG3200.h"


/* Gyro I2C Registers */
#define WHO_AM_I            0x00
#define SMPLRT_DIV          0x15
#define DLPF_FS             0x16
#define INT_CFG             0x17
#define INT_STATUS          0x1A
#define TEMP_OUT_H          0x1B
#define TEMP_OUT_L          0x1C
#define GYRO_XOUT_H         0x1D
#define GYRO_XOUT_L         0x1E
#define GYRO_YOUT_H         0x1F
#define GYRO_YOUT_L         0x20
#define GYRO_ZOUT_H         0x21
#define GYRO_ZOUT_L         0x22
#define PWR_MGM             0x3E

/* DLPF bits */
#define FS_SEL_SHIFT        3
#define FS_SEL_MASK         (0x3 << FS_SEL_SHIFT)
#define FS_SEL_2000         (3 << FS_SEL_SHIFT)
#define DLPF_CFG_MASK       0x7
#define DLPF_CFG_256HZ      0
#define DLPF_CFG_188HZ      1
#define DLPF_CFG_98HZ       2
#define DLPF_CFG_42HZ       3
#define DLPF_CFG_20HZ       4
#define DLPF_CFG_10HZ       5
#define DLPF_CFG_5HZ        6

/* INT_CFG bits */
#define ACTL                (1 << 7)
#define OPEN                (1 << 6)
#define LATCH_INT_EN        (1 << 5)
#define INT_ANYRD_2CLEAR    (1 << 4)
#define ITG_RDY_EN          (1 << 2)
#define RAW_RDY_EN          (1 << 0)

/* INT_STATUS  bits */
#define ITG_RDY             (1 << 2)
#define RAW_DATA_RDY        (1 << 0)

/* PWR_MGM bits */
#define H_RESET                 (1 << 7)
#define SLEEP                   (1 << 6)
#define STBY_XG                 (1 << 5)
#define STBY_YG                 (1 << 4)
#define STBY_ZG                 (1 << 3)
#define CLK_SEL_MASK            7
#define CLK_SEL_INT             0
#define CLK_SEL_PLL_X           1
#define CLK_SEL_PLL_Y           2
#define CLK_SEL_PLL_Z           3
#define CLK_SEL_PLL_EXT_32768HZ 4
#define CLK_SEL_PLL_EXT_19_2MHZ 5




ITG3200::ITG3200(I2C* pI2C, int address /* = 0xA6 */)
{
    m_pI2C = pI2C;
    m_address = address;
    initGyro();
}

void ITG3200::initGyro()
{
    do
    {
        writeGyroRegister(PWR_MGM, H_RESET);
        if (m_failedIo)
            break;
        writeGyroRegister(INT_CFG, LATCH_INT_EN | ITG_RDY_EN | RAW_RDY_EN);
        if (m_failedIo)
            break;
        writeGyroRegister(PWR_MGM, CLK_SEL_PLL_X);
        if (m_failedIo)
            break;
        waitForPllReady();
        writeGyroRegister(SMPLRT_DIV, (1000 / 100) - 1);
        if (m_failedIo)
            break;
        writeGyroRegister(DLPF_FS, FS_SEL_2000 | DLPF_CFG_42HZ);
        if (m_failedIo)
            break;
    }
    while (0);

    if (m_failedIo)
        m_failedInit = 1;
}

void ITG3200::writeGyroRegister(char registerAddress, char value)
{
    writeRegister(m_address, registerAddress, value);
}

void ITG3200::writeRegister(int i2cAddress, char registerAddress, char value)
{
    char dataToSend[2] = { registerAddress, value };

    m_failedIo = m_pI2C->write(i2cAddress, dataToSend, sizeof(dataToSend), false);
}

void ITG3200::waitForPllReady()
{
    char intStatus = 0;

    do
    {
        readGyroRegister(INT_STATUS, &intStatus);
    } while ((intStatus & ITG_RDY) == 0);
}

Int16Vector ITG3200::getVector()
{
    char        bigEndianDataWithTemp[8];
    Int16Vector vector;

    waitForDataReady();
    readGyroRegisters(TEMP_OUT_H, bigEndianDataWithTemp, sizeof(bigEndianDataWithTemp));
    if (m_failedIo)
        return vector;

    // Data returned is big endian and includes temperature which we are discarding for now.
    vector.m_x = (bigEndianDataWithTemp[2] << 8) | bigEndianDataWithTemp[3];
    vector.m_y = (bigEndianDataWithTemp[4] << 8) | bigEndianDataWithTemp[5];
    vector.m_z = (bigEndianDataWithTemp[6] << 8) | bigEndianDataWithTemp[7];
    return vector;
}

void ITG3200::waitForDataReady()
{
    char intStatus = 0;

    do
    {
        readGyroRegister(INT_STATUS, &intStatus);
    } while ((intStatus & RAW_DATA_RDY) == 0);
}

void ITG3200::readGyroRegister(char registerAddress, void* pBuffer)
{
    readRegisters(m_address, registerAddress, pBuffer, 1);
}

void ITG3200::readRegisters(int i2cAddress, char registerAddress, void* pBuffer, size_t bufferSize)
{
    m_failedIo = m_pI2C->write(i2cAddress, &registerAddress, sizeof(registerAddress), true);
    if (m_failedIo)
        return;
    m_failedIo = m_pI2C->read(i2cAddress, (char*)pBuffer, bufferSize, false);
}

void ITG3200::readGyroRegisters(char registerAddress, void* pBuffer, size_t bufferSize)
{
    readRegisters(m_address, registerAddress, pBuffer, bufferSize);
}
