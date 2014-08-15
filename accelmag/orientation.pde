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

HeadingSensor g_headingSensor;
PMatrix3D     g_rotationMatrix;
boolean       g_filtered = false;
boolean       g_zeroRotation = false;
int           g_samples = 0;
int           g_lastSampleCount;

void setup() 
{
  size(1024, 768, OPENGL);
  fill(255, 0, 0);

  ConfigFile configFile = new ConfigFile(System.getenv("USER") + ".config");
  Serial port = new Serial(this, configFile.param("compass.port"), 230400);

  IntVector minAccel = configFile.vectorParam("compass.accelerometer.min");
  IntVector minMag = configFile.vectorParam("compass.magnetometer.min");
  IntVector maxAccel = configFile.vectorParam("compass.accelerometer.max");
  IntVector maxMag = configFile.vectorParam("compass.magnetometer.max");
  Heading min = new Heading(minAccel.x, minAccel.y, minAccel.z, minMag.x, minMag.y, minMag.z);
  Heading max = new Heading(maxAccel.x, maxAccel.y, maxAccel.z, maxMag.x, maxMag.y, maxMag.z);
  Heading filterWidths = new Heading(16, 16, 16, 16, 16, 16);
  g_headingSensor = new HeadingSensor(port, min, max, filterWidths);
  g_lastSampleCount = millis();
}

void draw()
{
  int elapsedTime = millis() - g_lastSampleCount;
  if (elapsedTime > 10000)
  {
    println(g_samples / (elapsedTime / 1000));
    g_lastSampleCount = millis();
    g_samples = 0;
  }
  
  background(100);

  FloatHeading heading;
  if (g_filtered)
    heading = g_headingSensor.getCurrentFiltered();
  else
    heading = g_headingSensor.getCurrent();   
  
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

  // Setup 3d transformations other than rotation which will come next.
  translate(width / 2, height / 2, 0);
  scale(5.0f, 5.0f, 5.0f);
  
  // To create a rotation matrix, we need all 3 basis vectors so calculate the vector which
  // is orthogonal to both the down and north vectors (ie. the normalized cross product).
  PVector west = north.cross(down);
  west.normalize();
  g_rotationMatrix = new PMatrix3D(north.x, north.y, north.z, 0.0,
                                   down.x, down.y, down.z, 0.0,
                                   west.x, west.y, west.z, 0.0,
                                   0.0, 0.0, 0.0, 1.0);

  // Make the current rotation relative to base orientation.
  // UNDONE: g_rotationMatrix.preApply(g_baseRotation);
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
  if (g_headingSensor != null)
    g_headingSensor.update();
  g_samples++;
}

void keyPressed()
{
  char lowerKey = Character.toLowerCase(key);
  
  switch(lowerKey)
  {
  case ' ':
    g_zeroRotation = true;
    break;
  case 'f':
    g_filtered = !g_filtered;
    break;
  }
}

