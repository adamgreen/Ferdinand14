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
import processing.serial.*;

HeadingSensorCalibration g_calibration;
HeadingSensor            g_headingSensor;
PMatrix3D                g_rotationMatrix;
boolean                  g_zeroRotation = false;
int                      g_samples = 0;
int                      g_lastSampleCount;
float[]                  g_rotationQuaternion = {1.0f, 0.0f, 0.0f, 0.0f};
float[]                  g_currentRotation = {0.0f, 0.0f, 0.0f};
boolean                  g_dumpRotations = false;

void setup() 
{
  size(1024, 768, OPENGL);
  fill(255, 0, 0);

  ConfigFile configFile = new ConfigFile(System.getenv("USER") + ".config");
  Serial port = new Serial(this, configFile.getString("compass.port"), 230400);
  g_calibration = new HeadingSensorCalibration();
  g_calibration.accelMin = configFile.getIntVector("compass.accelerometer.min");
  g_calibration.magMin = configFile.getIntVector("compass.magnetometer.min");
  g_calibration.accelMax = configFile.getIntVector("compass.accelerometer.max");
  g_calibration.magMax = configFile.getIntVector("compass.magnetometer.max");
  g_calibration.gyroCoefficientA = configFile.getFloatVector("compass.gyro.coefficient.A");
  g_calibration.gyroCoefficientB = configFile.getFloatVector("compass.gyro.coefficient.B");
  g_calibration.gyroScale = configFile.getFloatVector("compass.gyro.scale");
  
  Heading filterWidths = new Heading(16, 16, 16, 16, 16, 16, 0, 0, 0, 0);
  g_headingSensor = new HeadingSensor(port, g_calibration, filterWidths);
  g_lastSampleCount = millis();
}

void draw()
{
  // Setup 3d transformations other than rotation which will come next.
  translate(width / 2, height / 2, 0);
  scale(5.0f, 5.0f, 5.0f);
  background(100);

  int elapsedTime = millis() - g_lastSampleCount;
  if (elapsedTime > 10000)
  {
    println(g_samples / (elapsedTime / 1000));
    g_lastSampleCount = millis();
    g_samples = 0;
  }
  
  FloatHeading heading = g_headingSensor.getCurrentFiltered();
/*
  // Setup gravity (down) and north vectors.
  // NOTE: The fields are swizzled to make the axis on the device match the axis on the screen.
  PVector down = new PVector(heading.m_accelY, heading.m_accelZ, heading.m_accelX);
  PVector north = new PVector(-heading.m_magX, heading.m_magZ, heading.m_magY);

  // Project the north vector onto the earth surface plane.
  down.normalize();
  north.sub(PVector.mult(down, north.dot(down)));
  north.normalize();

  // If the user has pressed the space key, then move the camera to face the device front.
  if (g_zeroRotation)
  {
    PVector cam = new PVector(0, (height / 2.0) / tan(radians(30.0)));
    cam.rotate(atan2(-north.z, north.x));
    camera(cam.x + width/2.0, height/2.0, cam.y, width/2.0, height/2.0, 0, 0, 1, 0);
    g_zeroRotation = false;
  }
*/
  // Convert quaternion to rotation matrix.
  float w = g_rotationQuaternion[0];
  float x = g_rotationQuaternion[1];
  float y = g_rotationQuaternion[2];
  float z = g_rotationQuaternion[3];
  
  float x2 = x * 2;
  float y2 = y * 2;
  float z2 = z * 2;
  float wx2 = w * x2;
  float wy2 = w * y2;
  float wz2 = w * z2;
  float xx2 = x * x2;
  float xy2 = x * y2;
  float xz2 = x * z2;
  float yy2 = y * y2;
  float yz2 = y * z2;
  float zz2 = z * z2;

  g_rotationMatrix = new PMatrix3D(1.0f - yy2 - zz2, xy2 + wz2, xz2 - wy2, 0.0f,
                                   xy2 - wz2, 1.0f - xx2 - zz2, yz2 + wx2, 0.0f,
                                   xz2 + wy2, yz2 - wx2, 1.0f - xx2 - yy2, 0.0f,
                                   0.0f, 0.0f, 0.0f, 1.0f);

  g_rotationMatrix.transpose();
  
/*  
  // To create a rotation matrix, we need all 3 basis vectors so calculate the vector which
  // is orthogonal to both the down and north vectors (ie. the normalized cross product).
  PVector west = north.cross(down);
  west.normalize();
  g_rotationMatrix = new PMatrix3D(north.x, north.y, north.z, 0.0,
                                   down.x, down.y, down.z, 0.0,
                                   west.x, west.y, west.z, 0.0,
                                   0.0, 0.0, 0.0, 1.0);
*/

  
  // Rotate the rendered box using the calculated rotation matrix.
  applyMatrix(g_rotationMatrix);

  // Draw four sides of box with different colours on each.
  stroke(160);
  fill(82, 10, 242);
  beginShape(QUADS);
    vertex(-25, -10, 50);
    vertex(-25, 10, 50);
    vertex(25, 10, 50);
    vertex(25, -10, 50);
  endShape();

  fill(255);
  beginShape(QUADS);
    vertex(-25, -10, -50);
    vertex(-25, -10, 50);
    vertex(25, -10, 50);
    vertex(25, -10, -50);
  endShape();

  fill(0);
  beginShape(QUADS);
    vertex(-25, 10, -50);
    vertex(-25, 10, 50);
    vertex(25, 10, 50);
    vertex(25, 10, -50);
  endShape();

  fill(126, 209, 13);
  beginShape(QUADS);
    vertex(-25, -10, -50);
    vertex(-25, 10, -50);
    vertex(25, 10, -50);
    vertex(25, -10, -50);
  endShape();
  
  fill(209, 6, 10);
  beginShape(QUADS);
    vertex(-25, 10, -50);
    vertex(-25, 10, 50);
    vertex(-25, -10, 50);
    vertex(-25, -10, -50);
  endShape();
  
  fill(237, 255, 0);
  beginShape(QUADS);
    vertex(25, 10, -50);
    vertex(25, 10, 50);
    vertex(25, -10, 50);
    vertex(25, -10, -50);
  endShape();
}

void serialEvent(Serial port)
{
  if (g_headingSensor == null)
    return;
  if (!g_headingSensor.update())
    return;
  g_samples++;
  
  // Retrieve latest gyro readings and swizzle the axis so that gyro's axis match overall sensor setup.
  FloatHeading heading = g_headingSensor.getCurrentFiltered();
  float gyroX = heading.m_gyroY;
  float gyroY = heading.m_gyroZ;
  float gyroZ = heading.m_gyroX;

  // Apply gyro rates (derivatives) to quaternion.
  float timeScale = (1.0f / 100.0f) * 0.5f;
  gyroX *= timeScale;
  gyroY *= timeScale;
  gyroZ *= timeScale;
  PMatrix3D gyroMatrix = new PMatrix3D( 1.0f, -gyroX, -gyroY, -gyroZ,
                                       gyroX,   1.0f,  gyroZ, -gyroY,
                                       gyroY, -gyroZ,   1.0f,  gyroX,
                                       gyroZ,  gyroY, -gyroX, 1.0f);

  float[] updatedQuaternion = new float[4];
  gyroMatrix.mult(g_rotationQuaternion, updatedQuaternion);
  g_rotationQuaternion = updatedQuaternion;
  float magnitude = sqrt(g_rotationQuaternion[0] * g_rotationQuaternion[0] +
                         g_rotationQuaternion[1] * g_rotationQuaternion[1] +  
                         g_rotationQuaternion[2] * g_rotationQuaternion[2] +  
                         g_rotationQuaternion[3] * g_rotationQuaternion[3]);
  g_rotationQuaternion[0] /= magnitude;
  g_rotationQuaternion[1] /= magnitude;
  g_rotationQuaternion[2] /= magnitude;
  g_rotationQuaternion[3] /= magnitude;
  
  // Integrate gryo readings (after removing 0.5 factor used in derivative calculation.)
  // Dump if user has made such a request.
  g_currentRotation[0] += gyroX / 0.5f;
  g_currentRotation[1] += gyroY / 0.5f;
  g_currentRotation[2] += gyroZ / 0.5f;
  if (g_dumpRotations)
  {
    println(degrees(g_currentRotation[0]) + "," + degrees(g_currentRotation[1]) + "," + degrees(g_currentRotation[2]));
  }
}

void keyPressed()
{
  char lowerKey = Character.toLowerCase(key);
  
  switch(lowerKey)
  {
  case ' ':
    g_zeroRotation = true;
    break;
  case 'z':
    g_dumpRotations = true;
    g_currentRotation[0] = 0.0f;
    g_currentRotation[1] = 0.0f;
    g_currentRotation[2] = 0.0f;
  }
}

