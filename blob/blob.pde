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
import processing.video.*;
import SimpleOpenNI.*;

final int       highlightDelay = 2000; // milliseconds     
final int       downSample = 1;

final int       HUE_MINUS_BUTTON = 0;
final int       HUE_PLUS_BUTTON = 1;
final int       SATURATION_MINUS_BUTTON = 2;
final int       SATURATION_PLUS_BUTTON = 3;
final int       BRIGHTNESS_MINUS_BUTTON = 4;
final int       BRIGHTNESS_PLUS_BUTTON = 5;
final int       HUE_THRESHOLD_MINUS_BUTTON = 6;
final int       HUE_THRESHOLD_PLUS_BUTTON = 7;
final int       SATURATION_THRESHOLD_MINUS_BUTTON = 8;
final int       SATURATION_THRESHOLD_PLUS_BUTTON = 9;
final int       BRIGHTNESS_THRESHOLD_MINUS_BUTTON = 10;
final int       BRIGHTNESS_THRESHOLD_PLUS_BUTTON = 11;
final int       FILL_THRESHOLD_MINUS_BUTTON = 12;
final int       FILL_THRESHOLD_PLUS_BUTTON = 13;
final int       BUTTON_COUNT = 14;

SimpleOpenNI  kinect1;

int             g_fontHeight;
int             g_fontWidth;
BlobConstraints g_constraints;
//Capture         rgbImage1;
PImage          rgbImage1;
PImage          g_snapshot;
PImage          g_savedImage;
PFont           g_font;
int             g_highlightStartTime;
Button[]        g_buttons;
BlobDetector    g_detector;
FloodFill       g_floodFill;
float           g_fillThreshold = 7.5f;
boolean         g_highlightBlobPixels = true;

void setup() 
{
  size(1280,555);

  g_font = loadFont("Monaco-14.vlw");
  textFont(g_font);
  g_fontHeight = int(textAscent() + textDescent() + 0.5f);
  g_fontWidth = int(textWidth(' ') + 0.5f);
  
  initCamera();
  g_detector = new BlobDetector(g_constraints, downSample);
  g_floodFill = new FloodFill();
}

protected void initCamera()
{
  
  kinect1 = new SimpleOpenNI(this);
      if (kinect1.isInit() == false)
      {
        println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
        exit();
        return;
      }
        kinect1.setMirror(false);
        //kinect1.enableDepth();
        kinect1.enableRGB();
        
        
  String cameraName = "foo";

  try
  {
    ConfigFile configFile = new ConfigFile(System.getenv("USER") + ".config");
    if (configFile != null)
    {
      cameraName = configFile.getString("blob.camera");
      IntVector hsb = configFile.getIntVector("blob.hsb");
      IntVector thresholds = configFile.getIntVector("blob.thresholds");
      int minBlobDimension = configFile.getInt("blob.minDimension");
      g_constraints = new BlobConstraints(hsb.x, hsb.y, hsb.z, thresholds.x, thresholds.y, thresholds.z, minBlobDimension);
    }
  }
  catch (Exception e)
  {
    cameraName = null;
    g_constraints = new BlobConstraints(0, 0, 0, 0, 0, 0, 0);
  }
  
  if (cameraName == null)
  {
    String[] cameras = Capture.list();
    if (cameras.length == 0)
    {
      println("There are no cameras available for capture.");
    } else 
    {
      println("Available cameras:");
      for (int i = 0; i < cameras.length; i++) 
      {
        println(cameras[i]);
      }
    }
    exit();
    return;
  }

  //rgbImage1 = new Capture(this, cameraName);
  //if (rgbImage1 == null)
  //  println("Failed to create video object.");
  //rgbImage1.start();
}

void draw() 
{
  //if (!rgbImage1.available())
  //  return;
  //rgbImage1.read();

    kinect1.update();
    rgbImage1 = kinect1.rgbImage(); 
   
    
  if (g_snapshot == null)
  {
    g_snapshot = createImage(rgbImage1.width, rgbImage1.height, RGB);
    g_snapshot.loadPixels();
    createButtons();
  }
  if (g_savedImage != null && millis() - g_highlightStartTime >= highlightDelay)
  {
    g_snapshot = g_savedImage;
    g_savedImage = null;
  }
  
  background(0, 0, 0);
  image(g_snapshot, rgbImage1.width, 0, g_snapshot.width, g_snapshot.height);
  
  int textX = 20;
  int line = 1;
  fill(255);
  text("H:   " + g_constraints.hue, textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
  text("S:   " + g_constraints.saturation, textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
  text("B:   " + g_constraints.brightness, textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
  
  textX += g_fontWidth * 13;
  line = 1;
  text(g_constraints.hueThreshold, textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
  text(g_constraints.saturationThreshold, textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
  text(g_constraints.brightnessThreshold, textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
  text(nf(g_fillThreshold, 3, 2), textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
  
  for (int i = 0 ; i < g_buttons.length ; i++)
  {
    g_buttons[i].update();
    g_buttons[i].display();
  }
  
  if (g_buttons[HUE_MINUS_BUTTON].isPressed())
    g_constraints.hue = max(0, g_constraints.hue - 1);
  if (g_buttons[HUE_PLUS_BUTTON].isPressed())
    g_constraints.hue = min(255, g_constraints.hue + 1);
  if (g_buttons[SATURATION_MINUS_BUTTON].isPressed())
    g_constraints.saturation = max(0, g_constraints.saturation - 1);
  if (g_buttons[SATURATION_PLUS_BUTTON].isPressed())
    g_constraints.saturation = min(255, g_constraints.saturation + 1);
  if (g_buttons[BRIGHTNESS_MINUS_BUTTON].isPressed())
    g_constraints.brightness = max(0, g_constraints.brightness - 1);
  if (g_buttons[BRIGHTNESS_PLUS_BUTTON].isPressed())
    g_constraints.brightness = min(255, g_constraints.brightness + 1);
  if (g_buttons[HUE_THRESHOLD_MINUS_BUTTON].isPressed())
    g_constraints.hueThreshold = max(0, g_constraints.hueThreshold - 1);
  if (g_buttons[HUE_THRESHOLD_PLUS_BUTTON].isPressed())
    g_constraints.hueThreshold = min(255, g_constraints.hueThreshold + 1);
  if (g_buttons[SATURATION_THRESHOLD_MINUS_BUTTON].isPressed())
    g_constraints.saturationThreshold = max(0, g_constraints.saturationThreshold - 1);
  if (g_buttons[SATURATION_THRESHOLD_PLUS_BUTTON].isPressed())
    g_constraints.saturationThreshold = min(255, g_constraints.saturationThreshold + 1);
  if (g_buttons[BRIGHTNESS_THRESHOLD_MINUS_BUTTON].isPressed())
    g_constraints.brightnessThreshold = max(0, g_constraints.brightnessThreshold - 1);
  if (g_buttons[BRIGHTNESS_THRESHOLD_PLUS_BUTTON].isPressed())
    g_constraints.brightnessThreshold = min(255, g_constraints.brightnessThreshold + 1);
  if (g_buttons[FILL_THRESHOLD_MINUS_BUTTON].isPressed())
    g_fillThreshold = max(0.0f, g_fillThreshold - 0.25f);
  if (g_buttons[FILL_THRESHOLD_PLUS_BUTTON].isPressed())
    g_fillThreshold = min(255.0f, g_fillThreshold + 0.25f);
  
  if (mouseX >= rgbImage1.width && mouseY < rgbImage1.height)
  {
    stroke(255, 255, 0);    
    line(rgbImage1.width, mouseY, width - 1, mouseY);
    line(mouseX, 0, mouseX, g_snapshot.height - 1);
    
    int imageX = mouseX - rgbImage1.width;
    int imageY = mouseY;
    int pixelValue = g_snapshot.pixels[imageY * g_snapshot.width + imageX];
    textX += g_fontWidth * 10;
    line = 1;
    text(int(hue(pixelValue)), textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
    text(int(saturation(pixelValue)), textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
    text(int(brightness(pixelValue)), textX, rgbImage1.height + (g_fontHeight / 2) + (line++ * g_fontHeight));
    
    if (mousePressed && g_savedImage == null)
    {
      FillResults results = g_floodFill.findColorThresholds(g_snapshot, imageX, imageY, g_fillThreshold, color(255, 255, 0));
      results.constraints.minBlobDimension = g_constraints.minBlobDimension;
      g_constraints = results.constraints;
      g_savedImage = g_snapshot;
      g_highlightStartTime = millis();
      g_snapshot = results.highlightedImage;
    }
    
    fill(pixelValue);
    noStroke();
    rect(20 + g_fontWidth * 21, rgbImage1.height + g_fontHeight * 1.5, g_fontWidth, g_fontHeight);
  }
  
  g_detector.setConstraints(g_constraints);
  g_detector.update(rgbImage1);
  drawBlobHighlights();
  drawBlobBoundingBoxes();
}

protected void createButtons()
{
  g_buttons = new Button[BUTTON_COUNT];
  g_buttons[HUE_MINUS_BUTTON] = new Button(20 + g_fontWidth * 3, rgbImage1.height + int(g_fontHeight * 0.5), g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[HUE_PLUS_BUTTON] = new Button(20 + g_fontWidth * 9, rgbImage1.height + int(g_fontHeight * 0.5), g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[SATURATION_MINUS_BUTTON] = new Button(20 + g_fontWidth * 3, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[SATURATION_PLUS_BUTTON] = new Button(20 + g_fontWidth * 9, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[BRIGHTNESS_MINUS_BUTTON] = new Button(20 + g_fontWidth * 3, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight * 2, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[BRIGHTNESS_PLUS_BUTTON] = new Button(20 + g_fontWidth * 9, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight * 2, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[HUE_THRESHOLD_MINUS_BUTTON] = new Button(20 + g_fontWidth * 11, rgbImage1.height + int(g_fontHeight * 0.5), g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[HUE_THRESHOLD_PLUS_BUTTON] = new Button(20 + g_fontWidth * 17, rgbImage1.height + int(g_fontHeight * 0.5), g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[SATURATION_THRESHOLD_MINUS_BUTTON] = new Button(20 + g_fontWidth * 11, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[SATURATION_THRESHOLD_PLUS_BUTTON] = new Button(20 + g_fontWidth * 17, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[BRIGHTNESS_THRESHOLD_MINUS_BUTTON] = new Button(20 + g_fontWidth * 11, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight * 2, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[BRIGHTNESS_THRESHOLD_PLUS_BUTTON] = new Button(20 + g_fontWidth * 17, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight * 2, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[FILL_THRESHOLD_MINUS_BUTTON] = new Button(20 + g_fontWidth * 11, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight * 3, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
  g_buttons[FILL_THRESHOLD_PLUS_BUTTON] = new Button(20 + g_fontWidth * 20, rgbImage1.height + int(g_fontHeight * 0.5) + g_fontHeight * 3, g_fontWidth, g_fontHeight, color(204), color(255), color(0));
}

protected void drawBlobHighlights()
{
  PImage copy = createImage(rgbImage1.width, rgbImage1.height, RGB);
  copy.copy(rgbImage1, 0, 0, rgbImage1.width, rgbImage1.height, 0, 0, copy.width, copy.height);

  if (g_highlightBlobPixels)
  {
    Blob   blob;
    while (null != (blob = g_detector.getNextBlob()))
    {
      int src = 0;
      for (int y = blob.minY ; y <= blob.maxY ; y++)
      {
        for (int x = blob.minX ; x <= blob.maxX ; x++)
        {
          if (blob.pixels[src++])
            copy.pixels[y * rgbImage1.width + x] = color(255, 255, 0);
        }
      }
    }
  }
  
  copy.updatePixels();
  image(copy, 0, 0, copy.width, copy.height);
}

void drawBlobBoundingBoxes()
{
  Blob blob;
  
  stroke(255, 255, 0);
  noFill();
  
  g_detector.rewindBlobPointer();
  while (null != (blob = g_detector.getNextBlob()))
  {
    rect(blob.minX, blob.minY, blob.width, blob.height);
  }
}

void keyPressed()
{
  switch (Character.toLowerCase(key))
  {
  case ' ':
    if (g_snapshot != null && g_savedImage == null)
    {
      g_snapshot.copy(rgbImage1, 0, 0, rgbImage1.width, rgbImage1.height, 0, 0, g_snapshot.width, g_snapshot.height);
      g_snapshot.loadPixels();
    }
    break;
  case 'h':
    g_highlightBlobPixels = !g_highlightBlobPixels;
    break;
  }
}

void mousePressed()
{
  for (int i = 0 ; i < g_buttons.length ; i++)
  {
    g_buttons[i].press();
  }
}

void mouseReleased()
{
  for (int i = 0 ; i < g_buttons.length ; i++)
  {
    g_buttons[i].release();
  }
}

