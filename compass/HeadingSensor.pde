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
class HeadingSensorCalibration
{
  public IntVector   accelMin;
  public IntVector   accelMax;
  public IntVector   magMin;
  public IntVector   magMax;
  public FloatVector gyroCoefficientA;
  public FloatVector gyroCoefficientB;
  public FloatVector gyroScale;
};

class HeadingSensor
{
  HeadingSensor(Serial port, HeadingSensorCalibration calibration)
  {
    m_calibration = calibration;
    calibrate(calibration);
    
    // Clear out any data that we might be in the middle of.
    m_port = port;
    String dummy = m_port.readStringUntil('\n');
    m_port.bufferUntil('\n');
  }

  void calibrate(HeadingSensorCalibration c)
  {
    m_midpoint = new FloatHeading((c.accelMin.x + c.accelMax.x) / 2.0f,
                                  (c.accelMin.y + c.accelMax.y) / 2.0f,
                                  (c.accelMin.z + c.accelMax.z) / 2.0f,
                                  (c.magMin.x + c.magMax.x) / 2.0f,
                                  (c.magMin.y + c.magMax.y) / 2.0f,
                                  (c.magMin.z + c.magMax.z) / 2.0f,
                                  0.0f,
                                  0.0f,
                                  0.0f,
                                  0.0f);
    m_scale = new FloatHeading((c.accelMax.x - c.accelMin.x) / 2.0f,
                               (c.accelMax.y - c.accelMin.y) / 2.0f,
                               (c.accelMax.z - c.accelMin.z) / 2.0f,
                               (c.magMax.x - c.magMin.x) / 2.0f,
                               (c.magMax.y - c.magMin.y) / 2.0f,
                               (c.magMax.z - c.magMin.z) / 2.0f,
                               1.0f,
                               1.0f,
                               1.0f,
                               1.0f);
  }
  
  boolean update()
  {
    String line = m_port.readString();
    if (line == null)
      return false;
      
    String[] tokens = splitTokens(line, ",\n");
    if (tokens.length == 11)
    {
      m_currentRaw.m_accelX = int(tokens[0]);
      m_currentRaw.m_accelY = int(tokens[1]);
      m_currentRaw.m_accelZ = int(tokens[2]);
      m_currentRaw.m_magX = int(tokens[3]);
      m_currentRaw.m_magY = int(tokens[4]);
      m_currentRaw.m_magZ = int(tokens[5]);
      m_currentRaw.m_gyroX = int(tokens[6]);
      m_currentRaw.m_gyroY = int(tokens[7]);
      m_currentRaw.m_gyroZ = int(tokens[8]);
      m_currentRaw.m_gyroTemperature = int(tokens[9]);
      
      m_max = m_max.max(m_currentRaw);
      m_min = m_min.min(m_currentRaw);
      
      return true;
    }
    
    return false;
  }
    
  Heading getCurrentRaw()
  {
    return m_currentRaw;
  }
  
  FloatHeading getCurrent()
  {
    FloatVector gyro = getCalibratedGyroData();
    return new FloatHeading((m_currentRaw.m_accelX - m_midpoint.m_accelX) / m_scale.m_accelX,
                            (m_currentRaw.m_accelY - m_midpoint.m_accelY) / m_scale.m_accelY,
                            (m_currentRaw.m_accelZ - m_midpoint.m_accelZ) / m_scale.m_accelZ,
                            (m_currentRaw.m_magX - m_midpoint.m_magX) / m_scale.m_magX,
                            (m_currentRaw.m_magY - m_midpoint.m_magY) / m_scale.m_magY,
                            (m_currentRaw.m_magZ - m_midpoint.m_magZ) / m_scale.m_magZ,
                            gyro.x,
                            gyro.y,
                            gyro.z,
                            m_currentRaw.m_gyroTemperature);                           
  }
  
  FloatVector getCalibratedGyroData()
  {
    FloatVector result = new FloatVector();
    result.x = m_currentRaw.m_gyroX - (m_currentRaw.m_gyroTemperature * m_calibration.gyroCoefficientA.x + m_calibration.gyroCoefficientB.x);
    result.y = m_currentRaw.m_gyroY - (m_currentRaw.m_gyroTemperature * m_calibration.gyroCoefficientA.y + m_calibration.gyroCoefficientB.y);
    result.z = m_currentRaw.m_gyroZ - (m_currentRaw.m_gyroTemperature * m_calibration.gyroCoefficientA.z + m_calibration.gyroCoefficientB.z);
    result.x *= radians(1.0f / m_calibration.gyroScale.x);
    result.y *= radians(1.0f / m_calibration.gyroScale.y);
    result.z *= radians(1.0f / m_calibration.gyroScale.z);
    return result;
  }
  
  Heading getMin()
  {
    return m_min;
  }
  
  Heading getMax()
  {
    return m_max;
  }
  
  HeadingSensorCalibration m_calibration;
  Serial  m_port;
  Heading m_currentRaw = new Heading();
  Heading m_min = new Heading(0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
                              0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
                              0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF);
  Heading m_max = new Heading(0x80000000, 0x80000000, 0x80000000,
                              0x80000000, 0x80000000, 0x80000000,
                              0x80000000, 0x80000000, 0x80000000, 0x80000000);
  FloatHeading    m_midpoint;
  FloatHeading    m_scale;
};


class FloatHeading
{
  float m_accelX;
  float m_accelY;
  float m_accelZ;
  float m_magX;
  float m_magY;
  float m_magZ;
  float m_gyroX;
  float m_gyroY;
  float m_gyroZ;
  float m_gyroTemperature;
  
  FloatHeading()
  {
  }
  
  FloatHeading(float accelX, float accelY, float accelZ, float magX, float magY, float magZ, float gyroX, float gyroY, float gyroZ, float gyroTemperature)
  {
    m_accelX = accelX;
    m_accelY = accelY;
    m_accelZ = accelZ;
    m_magX = magX;
    m_magY = magY;
    m_magZ = magZ;
    m_gyroX = gyroX;
    m_gyroY = gyroY;
    m_gyroZ = gyroZ;
    m_gyroTemperature = gyroTemperature;
  }

  void print()
  {
    System.out.print(m_accelX + "," +
              m_accelY + "," +
              m_accelZ + "," +
              m_magX + "," +
              m_magY + "," +
              m_magZ + "," +
              m_gyroX + "," +
              m_gyroY + "," +
              m_gyroZ + "," +
              m_gyroTemperature);
  }
};


class Heading
{
  int m_accelX;
  int m_accelY;
  int m_accelZ;
  int m_magX;
  int m_magY;
  int m_magZ;
  int m_gyroX;
  int m_gyroY;
  int m_gyroZ;
  int m_gyroTemperature;
  
  Heading()
  {
  }
  
  Heading(int accelX, int accelY, int accelZ, int magX, int magY, int magZ, int gyroX, int gyroY, int gyroZ, int gyroTemperature)
  {
    m_accelX = accelX;
    m_accelY = accelY;
    m_accelZ = accelZ;
    m_magX = magX;
    m_magY = magY;
    m_magZ = magZ;
    m_gyroX = gyroX;
    m_gyroY = gyroY;
    m_gyroZ = gyroZ;
    m_gyroTemperature = gyroTemperature;
  }
  
  Heading max(Heading other)
  {
    Heading max = new Heading();
    if (m_accelX > other.m_accelX)
      max.m_accelX = m_accelX;
    else
      max.m_accelX = other.m_accelX;
    if (m_accelY > other.m_accelY)
      max.m_accelY = m_accelY;
    else
      max.m_accelY = other.m_accelY;
    if (m_accelZ > other.m_accelZ)
      max.m_accelZ = m_accelZ;
    else
      max.m_accelZ = other.m_accelZ;

    if (m_magX > other.m_magX)
      max.m_magX = m_magX;
    else
      max.m_magX = other.m_magX;
    if (m_magY > other.m_magY)
      max.m_magY = m_magY;
    else
      max.m_magY = other.m_magY;
    if (m_magZ > other.m_magZ)
      max.m_magZ = m_magZ;
    else
      max.m_magZ = other.m_magZ;

    if (m_gyroX > other.m_gyroX)
      max.m_gyroX = m_gyroX;
    else
      max.m_gyroX = other.m_gyroX;
    if (m_gyroY > other.m_gyroY)
      max.m_gyroY = m_gyroY;
    else
      max.m_gyroY = other.m_gyroY;
    if (m_gyroZ > other.m_gyroZ)
      max.m_gyroZ = m_gyroZ;
    else
      max.m_gyroZ = other.m_gyroZ;
    
    if (m_gyroTemperature > other.m_gyroTemperature)
      max.m_gyroTemperature = m_gyroTemperature;
    else
      max.m_gyroTemperature = other.m_gyroTemperature;
      
    return max;
  }
  
  Heading min(Heading other)
  {
    Heading min = new Heading();
    if (m_accelX < other.m_accelX)
      min.m_accelX = m_accelX;
    else
      min.m_accelX = other.m_accelX;
    if (m_accelY < other.m_accelY)
      min.m_accelY = m_accelY;
    else
      min.m_accelY = other.m_accelY;
    if (m_accelZ < other.m_accelZ)
      min.m_accelZ = m_accelZ;
    else
      min.m_accelZ = other.m_accelZ;

    if (m_magX < other.m_magX)
      min.m_magX = m_magX;
    else
      min.m_magX = other.m_magX;
    if (m_magY < other.m_magY)
      min.m_magY = m_magY;
    else
      min.m_magY = other.m_magY;
    if (m_magZ < other.m_magZ)
      min.m_magZ = m_magZ;
    else
      min.m_magZ = other.m_magZ;

    if (m_gyroX < other.m_gyroX)
      min.m_gyroX = m_gyroX;
    else
      min.m_gyroX = other.m_gyroX;
    if (m_gyroY < other.m_gyroY)
      min.m_gyroY = m_gyroY;
    else
      min.m_gyroY = other.m_gyroY;
    if (m_gyroZ < other.m_gyroZ)
      min.m_gyroZ = m_gyroZ;
    else
      min.m_gyroZ = other.m_gyroZ;

    if (m_gyroTemperature < other.m_gyroTemperature)
      min.m_gyroTemperature = m_gyroTemperature;
    else
      min.m_gyroTemperature = other.m_gyroTemperature;
      
    return min;
  }
  
  void print()
  {
    System.out.print(m_accelX + "," +
              m_accelY + "," +
              m_accelZ + "," +
              m_magX + "," +
              m_magY + "," +
              m_magZ + "," +
              m_gyroX + "," +
              m_gyroY + "," +
              m_gyroZ + "," +
              m_gyroTemperature);
  }
};

