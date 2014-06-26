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
FloatHeading  g_samplesSum;
FloatHeading  g_samplesSquaredSum;
int           g_statSamples;

void setup() 
{
  size(1000, 700);

  g_samples = new float[width];
  g_sampleIndex = 0;
  g_samplesSum = new FloatHeading(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
  g_samplesSquaredSum = new FloatHeading(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
  g_statSamples = 0;

  ConfigFile configFile = new ConfigFile(System.getenv("USER") + ".config");
  Serial port = new Serial(this, configFile.param("compass.port"), 230400);

  IntVector minAccel = configFile.vectorParam("compass.accelerometer.min");
  IntVector minMag = configFile.vectorParam("compass.magnetometer.min");
  IntVector maxAccel = configFile.vectorParam("compass.accelerometer.max");
  IntVector maxMag = configFile.vectorParam("compass.magnetometer.max");
  Heading min = new Heading(minAccel.x, minAccel.y, minAccel.z, minMag.x, minMag.y, minMag.z, 0, 0, 0);
  Heading max = new Heading(maxAccel.x, maxAccel.y, maxAccel.z, maxMag.x, maxMag.y, maxMag.z, 0, 0, 0);
  Heading filterWidths = new Heading(16, 16, 16, 16, 16, 16, 0, 0, 0);
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
    sample = (float)heading.m_accelX;
    break;
  case 1:
    sample = (float)heading.m_accelY;
    break;
  case 2:
    sample = (float)heading.m_accelZ;
    break;
  case 3:
    sample = (float)heading.m_magX;
    break;
  case 4:
    sample = (float)heading.m_magY;
    break;
  case 5:
    sample = (float)heading.m_magZ;
    break;
  }
  g_samples[g_sampleIndex] = sample;
  g_sampleIndex = (g_sampleIndex + 1) % g_samples.length;
  
  Heading currentRaw = g_headingSensor.getCurrentRaw();
  g_samplesSum.add(currentRaw);
  g_samplesSquaredSum.addSquared(currentRaw);
  g_statSamples++;
  if (g_statSamples == 32768)
  {
    FloatHeading mean = new FloatHeading(g_samplesSum.m_accelX / g_statSamples,
                                         g_samplesSum.m_accelY / g_statSamples,
                                         g_samplesSum.m_accelZ / g_statSamples,
                                         g_samplesSum.m_magX / g_statSamples,
                                         g_samplesSum.m_magY / g_statSamples,
                                         g_samplesSum.m_magZ / g_statSamples,
                                         g_samplesSum.m_gyroX / g_statSamples,
                                         g_samplesSum.m_gyroY / g_statSamples,
                                         g_samplesSum.m_gyroZ / g_statSamples);
    FloatHeading variance = new FloatHeading((g_samplesSquaredSum.m_accelX - ((g_samplesSum.m_accelX * g_samplesSum.m_accelX) / g_statSamples)) / (g_statSamples - 1),
                                             (g_samplesSquaredSum.m_accelY - ((g_samplesSum.m_accelY * g_samplesSum.m_accelY) / g_statSamples)) / (g_statSamples - 1),
                                             (g_samplesSquaredSum.m_accelZ - ((g_samplesSum.m_accelZ * g_samplesSum.m_accelZ) / g_statSamples)) / (g_statSamples - 1),
                                             (g_samplesSquaredSum.m_magX - ((g_samplesSum.m_magX * g_samplesSum.m_magX) / g_statSamples)) / (g_statSamples - 1),
                                             (g_samplesSquaredSum.m_magY - ((g_samplesSum.m_magY * g_samplesSum.m_magY) / g_statSamples)) / (g_statSamples - 1),
                                             (g_samplesSquaredSum.m_magZ - ((g_samplesSum.m_magZ * g_samplesSum.m_magZ) / g_statSamples)) / (g_statSamples - 1),                                         
                                             (g_samplesSquaredSum.m_gyroX - ((g_samplesSum.m_gyroX * g_samplesSum.m_gyroX) / g_statSamples)) / (g_statSamples - 1),
                                             (g_samplesSquaredSum.m_gyroY - ((g_samplesSum.m_gyroY * g_samplesSum.m_gyroY) / g_statSamples)) / (g_statSamples - 1),
                                             (g_samplesSquaredSum.m_gyroZ - ((g_samplesSum.m_gyroZ * g_samplesSum.m_gyroZ) / g_statSamples)) / (g_statSamples - 1));
    print("Mean: ");
    mean.print();
    println();
    print("Variance: ");
    variance.print();
    println();
    
    g_samplesSum = new FloatHeading(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    g_samplesSquaredSum = new FloatHeading(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    g_statSamples = 0;
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


