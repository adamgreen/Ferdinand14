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
int           g_axis = 0;
boolean       g_dumpAccel = true;
boolean       g_initScreen = true;

void setup() 
{
  size(400, 400);

  Serial port = new Serial(this, "/dev/tty.usbmodem1412", 9600);

  // These min/max configuration values were found by rotating my sensor setup
  // and dumping min/max values with the d key.
  Heading min = new Heading(-16592,-16112,-16144,-648,-571,-526);
  Heading max = new Heading(16448,16400,16448,526,602,500);
  g_headingSensor = new HeadingSensor(port, min, max);

  g_axis = 0;
  g_initScreen = true;
}

void draw()
{
  if (g_initScreen)
  {
    g_initScreen = false;
    background(0);
    stroke(0, 0, 255);
    noFill();
    strokeWeight(1);
    ellipse(width/2, height/2, 200, 200);
  }
  
  FloatHeading heading = g_headingSensor.getCurrent();
  
  // The magnetometer output represents the north vector.
  PVector north = new PVector(heading.m_magX, heading.m_magY, heading.m_magZ);
  
  translate(width/2, height/2);
  scale(100, 100);
  
  pushMatrix();
  switch(g_axis)
  {
    case 0:
      translate(north.y, north.z);
      break;
    case 1:
      translate(north.x, north.z);
      break;
    case 2:
      translate(north.x, north.y);
      break;
  }
  stroke(255, 0, 0);
  strokeWeight(0.01);
  point(0, 0);
  popMatrix();
  
  if (g_dumpAccel)
  {
    g_headingSensor.getCurrentRaw().print();
    println();
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
    
    g_dumpAccel = false;
    break;
  case 'x':
    g_initScreen = true;
    g_axis = 0;
    break;
  case 'y':
    g_initScreen = true;
    g_axis = 1;
    break;
  case 'z':
    g_initScreen = true;
    g_axis = 2;
    break;
  case 'a':
    g_dumpAccel = !g_dumpAccel;
    break;
  }
}

