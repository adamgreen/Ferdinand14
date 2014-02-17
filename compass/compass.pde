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
boolean       g_sensorFlat = false;
boolean       g_tiltCompensated = true;
void setup() 
{
  size(400, 225, OPENGL);
  fill(255, 0, 0);

  Serial port = new Serial(this, "/dev/tty.usbmodem1412", 9600);

  // These min/max configuration values were found by rotating my sensor setup
  // and dumping min/max values with the d key.
  Heading min = new Heading(-16592,-16112,-16144,-472,-229,-221);
  Heading max = new Heading(16448,16400,16448,41,245,173);
  g_headingSensor = new HeadingSensor(port, min, max);
}

void draw()
{
  background(0);

  FloatHeading heading = g_headingSensor.getCurrent();
  
  // The magnetometer output represents the north vector.
  PVector north = new PVector(heading.m_magX, heading.m_magY, heading.m_magZ);
  
  if (g_tiltCompensated)
  {
    // The accelerometer represents the gravity vector.
    // The gravity vector is the normal of the plane representing the surface of the earth.
    PVector gravity = new PVector(heading.m_accelX, heading.m_accelY, heading.m_accelZ);
    gravity.normalize();

    // Project the north vector onto the earth surface plane.
    north.sub(PVector.mult(gravity, north.dot(gravity)));
  }

  float headingAngle = 0;
  if (g_sensorFlat)
    headingAngle = atan2(north.y, north.x);
  else
    headingAngle = atan2(north.y, north.z);

  lights();
  translate(width/2, height/2, 0);
  drawCompass(headingAngle);
}

void drawCompass(float angle)
{
  rotateX(radians(-10));

  noStroke();
  fill(255, 0, 0);
  drawCylinder(100, 100, 10, 64);

  fill(0, 0, 255);
  rotateY(angle);
  translate(2.5, 0, 50);
  box(5, 10, 100);
}

void drawCylinder(float topRadius, float bottomRadius, float tall, int sides) {
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
  if (g_headingSensor != null)
    g_headingSensor.update();
}

void keyPressed()
{
  char lowerKey = Character.toLowerCase(key);
  
  switch(lowerKey)
  {
  case 'd':
    print("min: ");
    g_headingSensor.getMin().print();
    println();

    print("max: ");
    g_headingSensor.getMax().print();
    println();
    break;
  case 'f':
    g_sensorFlat = true;
    break;
  case 'r':
    g_sensorFlat = false;
    break;
  case 'c':
    g_tiltCompensated = true;
    break;
  case 'n':
    g_tiltCompensated = false;
    break;
  }
}

