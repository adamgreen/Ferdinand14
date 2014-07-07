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
/* Processing code to interface with RoboPeak's RPLIDAR and display
   the scan results on the screen. */

import processing.serial.*;

class LidarHealth
{
  public int status;
  public int errorCode;
  
  public LidarHealth(int status, int errorCode)
  {
    this.status = status;
    this.errorCode = errorCode;
  }
  
  public static final int stateGood = 0;
  public static final int stateWarning = 1;
  public static final int stateError = 2;
};

class LidarDeviceInfo
{
  public int  model;
  public int  firmwareMinor;
  public int  firmwareMajor;
  public int  hardware;
  public byte serialNumber[];
  
  public LidarDeviceInfo(int model, int firmwareMinor, int firmwareMajor, int hardware, byte[] serialNumber)
  {
    this.model = model;
    this.firmwareMinor = firmwareMinor;
    this.firmwareMajor = firmwareMajor;
    this.hardware = hardware;
    this.serialNumber = serialNumber;
  }
};

class LidarMeasurement
{
  public float   angle;
  public float   distance;
  public int     quality;
  
  public LidarMeasurement(float angle, float distance, int quality)
  {
    this.angle = angle;
    this.distance = distance;
    this.quality = quality;
  }
};

class LidarScan
{
  public LidarMeasurement[] measurements;
  public int                measurementCount;
  public long               startTime;
  public float              scanRateInHz;
  
  public LidarScan()
  {
    measurements = new LidarMeasurement[115200 / 10 / 5];
    measurementCount = 0;
    startTime = System.currentTimeMillis();
    scanRateInHz = 0.0f;
  }
};

class LidarResponseDescriptor
{
  public int length;
  public int sendMode;
  public int dataType;
  
  public LidarResponseDescriptor(int length, int sendMode, int dataType)
  {
    this.length = length;
    this.sendMode = sendMode;
    this.dataType = dataType;
  }
  
  public static final int modeSingleResponse = 0;
  public static final int modeMultipleResponse = 1;
  public static final int typeMeasurement = 0x81;
  public static final int typeDeviceInfo = 0x4;
  public static final int typeDeviceHealth = 0x6;
};

public class Lidar extends PApplet
{
  public Lidar(String portName)
  {
    m_isScanning = false;
    m_port = new Serial(this, portName, 115200);
    m_port.setDTR(false);
    m_lastScan = new LidarScan();
    m_timeout = 500;
  }

  public LidarHealth getHealth()
  {
    final int lengthOfDataPacket = 3;
    m_startTime = millis();

    println("->getHealth()");

    sendCommand(cmdGetHealth);
    LidarResponseDescriptor responseDescriptor = getResponseDescriptor();
    verifyResponseDescriptor(responseDescriptor, LidarResponseDescriptor.typeDeviceHealth, LidarResponseDescriptor.modeSingleResponse, lengthOfDataPacket);

    byte buffer[] = new byte[lengthOfDataPacket];
    readBytes(buffer);
    
    int status = int(buffer[0]);
    int errorCode = (int(buffer[1]) & 0xFF) | ((int(buffer[2]) & 0xFF) << 8);
    println("status = " + status);
    println("errorCode = " + errorCode);
    
    println("<-getHealth()");
    return new LidarHealth(status, errorCode);
  }
  
  protected void sendCommand(byte command)
  {
    byte header[] = {cmdSyncByte, command};
    
    println("sendCommand: " + hex(header[0]) + " " + hex(header[1]));
    m_port.write(header);
  }
  
  protected LidarResponseDescriptor getResponseDescriptor()
  {
    println("->getResponseDescriptor()");

    waitForResponseSyncBytes();
    
    byte buffer[] = new byte[5];
    readBytes(buffer);
    
    int length = (int(buffer[0]) & 0xFF) | ((int(buffer[1]) & 0xFF) << 8) | ((int(buffer[2]) & 0xFF) << 16) | ((int(buffer[3]) & 0x3F) << 24);
    int mode = (int(buffer[3]) & 0xC0) >> 6;
    int type = int(buffer[4]);  

    println("length = " + length);
    println("mode = " + mode);
    println("type = " + type);
    
    println("<-getResponseDescriptor()");
    return new LidarResponseDescriptor(length, mode, type);
  }
 
  protected void waitForResponseSyncBytes()
  {
    int lastByte = 0;
    
    println("->waitForResponseSyncBytes()");
    
    while (millis() - m_startTime < m_timeout)
    {
      if (m_port.available() == 0)
        continue;
      byte currByte = byte(m_port.read());
      if (currByte == respSyncByte2 && lastByte == respSyncByte1)
      {
        println("<-waitForResponseSyncBytes()");
        return;
      }
      lastByte = currByte;
    }
    
    println("TIMEOUT");
    throw new RuntimeException("Timed out waiting for response sync bytes");
  }
 
  protected void readBytes(byte buffer[])
  {
    int i = 0;
    println("->readBytes()");
    
    while (i < buffer.length && millis() - m_startTime < m_timeout)
    {
      if (m_port.available() == 0)
        continue;

      byte currByte = byte(m_port.read());
      buffer[i++] = currByte;
    }

    if (millis() - m_startTime >= m_timeout)
    {
      println("TIMEOUT");
      throw new RuntimeException("Timed out waiting for bytes to read.");
    }
    println("<-readBytes()");
  }
  
  protected void printByteArrayAsHex(byte[] bytes)
  {
    for (int i = 0 ; i < bytes.length ; i++)
      print(hex(bytes[i]) + " ");
    println();
  }
  
  protected void verifyResponseDescriptor(LidarResponseDescriptor responseDescriptor, int expectedDataType, int expectedSendMode, int expectedLength)
  {
    if (responseDescriptor.dataType != expectedDataType)
    {
      println("BAD TYPE");
      throw new RuntimeException("Unexpected response descriptor type: " + hex(responseDescriptor.dataType));
    }
    if (responseDescriptor.sendMode != expectedSendMode)
    {
      println("BAD SEND MODE");
      throw new RuntimeException("Unexpected response device health descriptor send mode: " + hex(responseDescriptor.sendMode));
    }
    if (responseDescriptor.length != expectedLength)
    {
      println("BAD LENGTH");
      throw new RuntimeException("Unexpected response length: " + responseDescriptor.length);
    }
  }
  
  public LidarDeviceInfo getDeviceInfo()
  {
    final int lengthOfDataPacket = 20;
    m_startTime = millis();
    
    println("->getDeviceInfo()");

    sendCommand(cmdGetDeviceInfo);
    LidarResponseDescriptor responseDescriptor = getResponseDescriptor();
    verifyResponseDescriptor(responseDescriptor, LidarResponseDescriptor.typeDeviceInfo, LidarResponseDescriptor.modeSingleResponse, lengthOfDataPacket);

    byte[] buffer = new byte[lengthOfDataPacket];
    readBytes(buffer);
    
    int model = int(buffer[0]);
    int firmwareMinor = int(buffer[1]);
    int firmwareMajor = int(buffer[2]);
    int hardware = int(buffer[3]);
    byte[] serialNumber = new byte[16];
    System.arraycopy(buffer, 4, serialNumber, 0, 16);
    
    println("model = " + model);
    println("firmware = " + firmwareMajor + "." + firmwareMinor);
    println("hardware = " + hardware);
    print("serialNumber = "); printByteArrayAsHex(serialNumber);
    
    println("<-getDeviceInfo()");
    return new LidarDeviceInfo(model, firmwareMinor, firmwareMajor, hardware, serialNumber);
  }
  
  public void reset()
  {
    println("->reset()");

    sendCommand(cmdReset);
    wait_ms(2);
    
    println("<-reset()");
  }
  
  protected void wait_ms(int millisecondsToWait)
  {
    int startTime = millis();
    while (millis() - startTime < millisecondsToWait)
    {
    }
  }
  
  public void stopScan()
  {
    println("->stopScan()");

    // Stop handling measurement packets in the background.
    m_isScanning = false;
    
    sendCommand(cmdStop);
    wait_ms(1);
    
    // Get rid of any data that is left over in serial buffer.
    m_port.clear();
    
    println("<-stopScan()");
  }
  
  public void startScan()
  {
    final int lengthOfDataPacket = 5;
    m_startTime = millis();
    
    println("->startScan()");

    stopScan();
    
    sendCommand(cmdStart);
    LidarResponseDescriptor responseDescriptor = getResponseDescriptor();
    verifyResponseDescriptor(responseDescriptor, LidarResponseDescriptor.typeMeasurement, LidarResponseDescriptor.modeMultipleResponse, lengthOfDataPacket);

    // Setup to process measurement packets in the background using serialEvent().
    m_currScan = new LidarScan();
    m_isScanning = true;
    m_port.buffer(lengthOfDataPacket);
    
    println("<-startScan()");
  }
  
  public void serialEvent(Serial port)
  {
    // Handle data synchronously until actively scanning.
    if (!m_isScanning)
      return;
    
    final int lengthOfDataPacket = 5;
    byte[] packet = new byte[lengthOfDataPacket];
    
    while (m_port.available() >= lengthOfDataPacket)
    {
      m_port.readBytes(packet);
      parseMeasurement(packet);
    }
  }
  
  protected void parseMeasurement(byte[] packet)
  {
    // UNDONE: Could have some code which attempts to get back into sync when an invalid packet is encountered.
    if (!validPacket(packet))
      return;
    if (isNewScanStart(packet))
    {
      m_currScan.scanRateInHz = 1000.0f / float((int)(System.currentTimeMillis() - m_currScan.startTime));
      m_lastScan = m_currScan;
      m_currScan = new LidarScan();
    }
    
    int quality = (int(packet[0]) & 0xFC) >> 2;
    int angleFixed = ((int(packet[1]) & 0xFE) >> 1) | ((int(packet[2]) & 0xFF) << 7);
    int distanceFixed = (int(packet[3]) & 0xFF) | ((int(packet[4]) & 0xFF) << 8);
    float angle = float(angleFixed) / 64.0f;
    float distance = float(distanceFixed) / 4.0f;
    m_currScan.measurements[m_currScan.measurementCount++] = new LidarMeasurement(angle, distance, quality);
  }
  
  protected boolean validPacket(byte[] packet)
  {
    byte firstByte = packet[0];
    
    // A valid packet should have S and ~S bits (bits 0 and 1 in first byte) set to opposite values.
    if (0 == ((firstByte & 0x1) ^ ((firstByte & 0x2) >> 1)))
      return false;
    // A valid packet should have the C bit (bit 0 in second byte) set.
    if (0 == (packet[1] & 0x1))
      return false;
    return true; 
  }
  
  protected boolean isNewScanStart(byte[] packet)
  {
    return (0x1 == (packet[0] & 0x1));
  }

  public LidarScan getLatestScan()
  {
    return m_lastScan;
  }

  protected static final byte cmdSyncByte = (byte)0xA5;
  protected static final byte cmdGetHealth = 0x52;
  protected static final byte cmdGetDeviceInfo = 0x50;
  protected static final byte cmdReset = 0x40;
  protected static final byte cmdStop = 0x25;
  protected static final byte cmdStart = 0x20;

  protected static final byte respSyncByte1 = cmdSyncByte;
  protected static final byte respSyncByte2 = 0x5A; 
  
  protected Serial             m_port;
  protected int                m_startTime;
  protected int                m_timeout;
  protected volatile boolean   m_isScanning;
  protected volatile LidarScan m_lastScan;
  protected LidarScan          m_currScan;
};

Lidar g_lidar;
long  g_lastScanTime;

void setup() 
{
  size(600, 600);
  fill(255, 0, 0);
  colorMode(RGB, 1.0f);
  
  ConfigFile configFile = new ConfigFile(System.getenv("USER") + ".config");
  g_lidar = new Lidar(configFile.param("lidar.port"));

  LidarDeviceInfo deviceInfo = g_lidar.getDeviceInfo();
  LidarHealth health = g_lidar.getHealth();
  g_lidar.startScan();
}

void draw()
{
  background(0);

  LidarScan scan = g_lidar.getLatestScan();
  for (int i = 0 ; i < scan.measurementCount ; i++)
  {
    float angle = scan.measurements[i].angle;
    float distance = scan.measurements[i].distance;
    float quality = map(float(scan.measurements[i].quality), 0.0f, 63.0f, 0.0f, 1.0f);
    
    angle = radians(angle);
    distance = map(distance, 0.0f, 6000.0f, 0.0f, width / 2.0f);
    color colour = color(1.0f - quality, quality, 0.0f);
    float x = width / 2 + distance * sin(angle);
    float y = height / 2 - distance * cos(angle);
    stroke(colour);
    point(x, y);
  }
}

void keyPressed()
{
  char lowerKey = Character.toLowerCase(key);
  
  switch(lowerKey)
  {
  case 'x':
    g_lidar.stopScan(); 
    break;
  case 'g':
    g_lidar.startScan();
    break;
  }
}

