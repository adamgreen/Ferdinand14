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
  background(100);

  int elapsedTime = millis() - g_lastSampleCount;
  if (elapsedTime > 10000)
  {
    println(g_samples / (elapsedTime / 1000));
    g_lastSampleCount = millis();
    g_samples = 0;
  }
  
  FloatHeading heading = g_headingSensor.getCurrentFiltered();

  // Setup gravity (down) and north vectors.
  // NOTE: The fields are swizzled to make the axis on the device match the axis on the screen.
  PVector down = new PVector(heading.m_accelY, heading.m_accelZ, heading.m_accelX);
  PVector north = new PVector(-heading.m_magX, heading.m_magZ, heading.m_magY);

  // Project the north vector onto the earth surface plane.
  down.normalize();
  north.sub(PVector.mult(down, north.dot(down)));
  north.normalize();

/* UNDONE: I don't know if I need this anymore.  If I do bring back then need to update compass location.
  // If the user has pressed the space key, then move the camera to face the device front.
  if (g_zeroRotation)
  {
    PVector cam = new PVector(0, (height / 2.0) / tan(radians(30.0)));
    cam.rotate(atan2(-north.z, north.x));
    camera(cam.x + width/2.0, height/2.0, cam.y, width/2.0, height/2.0, 0, 0, 1, 0);
    g_zeroRotation = false;
  }
*/
  // To create a rotation matrix, we need all 3 basis vectors so calculate the vector which
  // is orthogonal to both the down and north vectors (ie. the normalized cross product).
  PVector west = north.cross(down);
  west.normalize();
  g_rotationMatrix = new PMatrix3D(north.x, north.y, north.z, 0.0,
                                   down.x, down.y, down.z, 0.0,
                                   west.x, west.y, west.z, 0.0,
                                   0.0, 0.0, 0.0, 1.0);
                                   
  // Convert rotation matrix into normalized quaternion.
  float w = 0.0f;
  float x = 0.0f;
  float y = 0.0f;
  float z = 0.0f;
  float[] rotationQuaternion = new float[4];
  float trace = g_rotationMatrix.m00 + g_rotationMatrix.m11 + g_rotationMatrix.m22;
  if (trace > 0.0f)
  {
    w = sqrt(trace + 1.0f) / 2.0f;
    float lambda = 1.0f / (4.0f * w);
    x = lambda * (g_rotationMatrix.m21 - g_rotationMatrix.m12);
    y = lambda * (g_rotationMatrix.m02 - g_rotationMatrix.m20);
    z = lambda * (g_rotationMatrix.m10 - g_rotationMatrix.m01);
  }
  else
  {
    if (g_rotationMatrix.m00 > g_rotationMatrix.m11)
    {
      if (g_rotationMatrix.m00 > g_rotationMatrix.m22)
      {
          // m00 is the largest value on diagonal.
          x = sqrt(g_rotationMatrix.m00 - g_rotationMatrix.m11 - g_rotationMatrix.m22 + 1.0f) / 2.0f;
          float lambda = 1.0f / (4.0f * x);
          w = lambda * (g_rotationMatrix.m21 - g_rotationMatrix.m12);
          y = lambda * (g_rotationMatrix.m01 + g_rotationMatrix.m10);
          z = lambda * (g_rotationMatrix.m02 + g_rotationMatrix.m20);
      }
      else
      {
          // m22 is the largest value on diagonal.
          z = sqrt(g_rotationMatrix.m22 - g_rotationMatrix.m00 - g_rotationMatrix.m11 + 1.0f) / 2.0f;
          float lambda = 1.0f / (4.0f * z);
          w = lambda * (g_rotationMatrix.m10 - g_rotationMatrix.m01);
          x = lambda * (g_rotationMatrix.m02 + g_rotationMatrix.m20);
          y = lambda * (g_rotationMatrix.m12 + g_rotationMatrix.m21);
      }
    }
    else
    {
      if (g_rotationMatrix.m11 > g_rotationMatrix.m22)
      {
        // m11 is the largest value on diagonal.
        y = sqrt(g_rotationMatrix.m11 - g_rotationMatrix.m00 - g_rotationMatrix.m22 + 1.0f) / 2.0f;
        float lambda = 1.0f / (4.0f * y);
        w = lambda * (g_rotationMatrix.m02 - g_rotationMatrix.m20);
        x = lambda * (g_rotationMatrix.m01 + g_rotationMatrix.m10);
        z = lambda * (g_rotationMatrix.m12 + g_rotationMatrix.m21);
      }
      else
      {
          // m22 is the largest value on diagonal.
          // UNDONE: This is duplicated code.
          z = sqrt(g_rotationMatrix.m22 - g_rotationMatrix.m00 - g_rotationMatrix.m11 + 1.0f) / 2.0f;
          float lambda = 1.0f / (4.0f * z);
          w = lambda * (g_rotationMatrix.m10 - g_rotationMatrix.m01);
          x = lambda * (g_rotationMatrix.m02 + g_rotationMatrix.m20);
          y = lambda * (g_rotationMatrix.m12 + g_rotationMatrix.m21);
      }
    }
  }
  g_rotationQuaternion[0] = w;
  g_rotationQuaternion[1] = x;
  g_rotationQuaternion[2] = y;
  g_rotationQuaternion[3] = z;

  // Convert quaternion to rotation matrix.
  w = g_rotationQuaternion[0];
  x = g_rotationQuaternion[1];
  y = g_rotationQuaternion[2];
  z = g_rotationQuaternion[3];
  
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

  g_rotationMatrix = new PMatrix3D(1.0f - yy2 - zz2,        xy2 - wz2,        xz2 + wy2, 0.0f,
                                          xy2 + wz2, 1.0f - xx2 - zz2,        yz2 - wx2, 0.0f,
                                          xz2 - wy2,        yz2 + wx2, 1.0f - xx2 - yy2, 0.0f,
                                               0.0f,             0.0f,             0.0f, 1.0f);
  
  // Rotate the rendered box using the calculated rotation matrix.
  pushMatrix();
  translate(width / 2, height / 2, 0);
  scale(5.0f, 5.0f, 5.0f);
  applyMatrix(g_rotationMatrix);
  drawBox();
  popMatrix();
  
  // Calculate the yaw angle and rotate the compass image accordingly.
  /*PVector*/ north = new PVector(g_rotationMatrix.m00, g_rotationMatrix.m01, g_rotationMatrix.m02);
  float headingAngle = atan2(-north.z, north.x);
  translate(width - 150, height - 150, 0);
  drawCompass(headingAngle);
}

void drawBox()
{
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

void drawCompass(float angle)
{
  rotateX(radians(-90));

  noStroke();
  fill(255, 0, 0);
  drawCylinder(100, 100, 10, 64);

  fill(0, 0, 255);
  rotateY(angle);
  translate(2.5, 0, 50);
  box(5, 10, 100);
}

void drawCylinder(float topRadius, float bottomRadius, float tall, int sides) 
{
  float angle = 0;
  float angleIncrement = TWO_PI / sides;
  beginShape(QUAD_STRIP);
  for (int i = 0; i < sides + 1; ++i) {
    vertex(topRadius*cos(angle), 0, topRadius*sin(angle));
    vertex(bottomRadius*cos(angle), tall, bottomRadius*sin(angle));
    angle += angleIncrement;
  }
  endShape();

  // If it is not a cone, draw the circular top cap
  if (topRadius != 0) {
    angle = 0;
    beginShape(TRIANGLE_FAN);

    // Center point
    vertex(0, 0, 0);
    for (int i = 0; i < sides + 1; i++) {
      vertex(topRadius * cos(angle), 0, topRadius * sin(angle));
      angle += angleIncrement;
    }
    endShape();
  }

  // If it is not a cone, draw the circular bottom cap
  if (bottomRadius != 0) {
    angle = 0;
    beginShape(TRIANGLE_FAN);

    // Center point
    vertex(0, tall, 0);
    for (int i = 0; i < sides + 1; i++) {
      vertex(bottomRadius * cos(angle), tall, bottomRadius * sin(angle));
      angle += angleIncrement;
    }
    endShape();
  }
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

