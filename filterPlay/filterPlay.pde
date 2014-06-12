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
boolean       g_filtered = false;
float[]       g_samples;
int           g_sampleIndex;

void setup() 
{
  size(1000, 700);

  g_samples = new float[width];
  g_sampleIndex = 0;

  Serial port = new Serial(this, "/dev/tty.usbmodem1412", 9600);

  // These min/max configuration values were found by rotating my sensor setup
  // and dumping min/max values with the d key in magView.
  Heading min = new Heading(-7744, -8256, -8960, -588, -888, -675);
  Heading max = new Heading(8736, 8320, 7456, 721, 414, 517);
  Heading filterWidths = new Heading(16, 16, 16, 16, 16, 16);
  g_headingSensor = new HeadingSensor(port, min, max, filterWidths);
}

void draw()
{
  background(128);
  stroke(0);
  strokeWeight(1);
  translate(0, height / 2);
  scale(1, -1);

  line(0, 0, width - 1, 0);
  beginShape(LINES);
  int current = g_sampleIndex;
  int i = current;
  for (int x = width - 1; x >= 0 ; x--)
  {
    i--; 
    if (i < 0)
      i = g_samples.length - 1;

    float y = map(g_samples[i], -1.0f, 1.0f, -height/2, height/2);
    vertex(x, y);
  } while (i != current);
  endShape();
}

void serialEvent(Serial port)
{
  if (g_headingSensor == null)
    return;

  g_headingSensor.update();
  FloatHeading heading;
  if (g_filtered)
    heading = g_headingSensor.getCurrentFiltered();
  else
    heading = g_headingSensor.getCurrent();
  
  float sample = 0.0f;
  switch (g_axis)
  {
  case 0:
    sample = heading.m_accelX;
    break;
  case 1:
    sample = heading.m_accelY;
    break;
  case 2:
    sample = heading.m_accelZ;
    break;
  case 3:
    sample = heading.m_magX;
    break;
  case 4:
    sample = heading.m_magY;
    break;
  case 5:
    sample = heading.m_magZ;
    break;
  }
  g_samples[g_sampleIndex] = sample;
  g_sampleIndex = (g_sampleIndex + 1) % g_samples.length;
}

void keyPressed()
{
  char lowerKey = Character.toLowerCase(key);
  
  switch(lowerKey)
  {
  case 'x':
    g_axis = 0;
    break;
  case 'y':
    g_axis = 1;
    break;
  case 'z':
    g_axis = 2;
    break;
  case 'a':
    g_axis = 3;
    break;
  case 'b':
    g_axis = 4;
    break;
  case 'c':
    g_axis = 5;
    break;
   case 'f':
     g_filtered = !g_filtered;
     break;
  }
}


