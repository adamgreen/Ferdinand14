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
PVector[]     g_baseRotation;

void setup() 
{
  size(1024, 768, OPENGL);
  fill(255, 0, 0);

  Serial port = new Serial(this, "/dev/tty.usbmodem1412", 9600);

  g_baseRotation = new PVector[3];
  for (int i = 0 ; i < g_baseRotation.length ; i++)
    g_baseRotation[i] = new PVector(0, 0, 0);
  
  // These min/max configuration values were found by rotating my sensor setup
  // and dumping min/max values with the d key.
  Heading min = new Heading(-16592,-16112,-16144,-648,-571,-526);
  Heading max = new Heading(16448,16400,16448,526,602,500);
  Heading filterWidths = new Heading(4, 4, 4, 16, 16, 16);
  g_headingSensor = new HeadingSensor(port, min, max, filterWidths);
}

void draw()
{
  background(100);

  FloatHeading heading = g_headingSensor.getCurrentFiltered();
  
  // Setup gravity (down) and north vectors.
  // NOTE: The fields are swizzled to make the axis on the device match the axis on the screen.
  PVector down = new PVector(heading.m_accelX, heading.m_accelZ, -heading.m_accelY);
  PVector north = new PVector(heading.m_magX, heading.m_magZ, -heading.m_magY);

  // Project the north vector onto the earth surface plane.
  down.normalize();
  north.sub(PVector.mult(down, north.dot(down)));
  north.normalize();

  // Setup 3d transformations other than rotation which will come next.
  translate(width / 2, height / 2, 0);
  scale(5.0f, 5.0f, 5.0f);
  
  // To create a rotation matrix, we need all 3 basis vectors so calculate the vector which
  // is orthogonal to both the down and north vectors (ie. the normalized cross product).
  PVector orth = north.cross(down);
  orth.normalize();
  applyMatrix(north.x, north.y, north.z, 0.0,
              down.x, down.y, down.z, 0.0,
              orth.x, orth.y, orth.z, 0.0,
              0.0, 0.0, 0.0, 1.0);

  // Draw four sides of box with different colours on each.
  stroke(160);
  fill(0, 0, 255);
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

  fill(0, 255, 0);
  beginShape(QUADS);
    vertex(-25, -10, -50);
    vertex(-25, 10, -50);
    vertex(25, 10, -50);
    vertex(25, -10, -50);
  endShape();
}

void serialEvent(Serial port)
{
  if (g_headingSensor != null)
    g_headingSensor.update();
}

