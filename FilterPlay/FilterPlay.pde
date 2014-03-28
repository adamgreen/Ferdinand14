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
Complex[][]   g_samples;
int           g_samplePingPong = 0;
int           g_displayPingPong = 0;
int           g_sampleIndex = 0;
int           g_axis = 0;

void setup() 
{
  size(128, 128);

  g_samples = new Complex[2][];
  for (int i = 0 ; i < g_samples.length ; i++)
    g_samples[i] = new Complex[width * 2];
  
  Serial port = new Serial(this, "/dev/tty.usbmodem1412", 9600);

  // These min/max configuration values were found by rotating my sensor setup
  // and dumping min/max values with the d key.
  Heading min = new Heading(-16592,-16112,-16144,-648,-571,-526);
  Heading max = new Heading(16448,16400,16448,526,602,500);
  g_headingSensor = new HeadingSensor(port, min, max);
}

void draw()
{
  if (g_displayPingPong == g_samplePingPong)
    return;
   
  calculateFFT(g_samples[g_displayPingPong]);

  Float[] magnitudes = calculateMagnitudes(g_samples[g_displayPingPong]);
  float maximumMag = 0.0f;
  for (int i = 0 ; i < magnitudes.length / 2 ; i++)
  {
    if (magnitudes[i] > maximumMag)
      maximumMag = magnitudes[i];
  }

  background(0);
  stroke(0, 0, 255);
  strokeWeight(1);
  for (int i = 0 ; i < magnitudes.length / 2 ; i++)
  {
    line(i, height, i, map(magnitudes[i], 0, maximumMag, height, 0));
  }
  g_displayPingPong = g_samplePingPong;
}

void serialEvent(Serial port)
{
  if (g_headingSensor == null)
    return;

  g_headingSensor.update();
  FloatHeading heading = g_headingSensor.getCurrent();

  g_samples[g_samplePingPong][g_sampleIndex++] = new Complex(heading.m_accelX, 0.0f);
  if (g_sampleIndex >= g_samples[g_samplePingPong].length)
  {
    g_samplePingPong ^= 1;
    g_sampleIndex = 0;
  }
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
  }
}


