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

class BlobConstraints
{
  public int hue;
  public int saturation;
  public int brightness;
  public int hueThreshold;
  public int saturationThreshold;
  public int brightnessThreshold;
  
  public BlobConstraints(int hue, int saturation, int brightness, int hueThreshold, int saturationThreshold, int brightnessThreshold)
  {
    this.hue = hue;
    this.saturation = saturation;
    this.brightness = brightness;
    this.hueThreshold = hueThreshold;
    this.saturationThreshold = saturationThreshold;
    this.brightnessThreshold = brightnessThreshold;
  }
};

class Blob
{
  public int       minX;
  public int       minY;
  public int       maxX;
  public int       maxY;
  public int       width;
  public int       height;
  public boolean[] pixels;
  public boolean   valid;
};

class BlobDetector
{
  protected BlobConstraints m_constraints;
  protected Blob            m_blob;
  
  public BlobDetector(BlobConstraints constraints)
  {
    m_constraints = constraints;
    m_blob = new Blob();
  }
  
  public void setConstraints(BlobConstraints constraints)
  {
    m_constraints = constraints;
  }
  
  public void update(PImage image)
  {
    image.loadPixels();
    
    int minX = image.width;
    int minY = image.height;
    int maxX = -1;
    int maxY = -1;
    int index = 0;
    
    for (int y = 0 ; y < image.height ; y++)
    {
      for (int x = 0 ; x < image.width ; x++)
      {
        if (matchesConstraints(image.pixels[index++]))
        {
          minX = min(minX, x);
          minY = min(minY, y);
          maxX = max(maxX, x);
          maxY = max(maxY, y);
        }
      }
    }
    
    if (maxX > -1)
    {
      m_blob.valid = true;
      m_blob.minX = minX;
      m_blob.minY = minY;
      m_blob.maxX = maxX;
      m_blob.maxY = maxY;
      m_blob.width = maxX - minX + 1;
      m_blob.height = maxY - minY + 1;
      setPixels(image, m_blob);
    }
    else
    {
      m_blob.valid = false;
      m_blob.minX = -1;
      m_blob.minY = -1;
      m_blob.maxX = -1;
      m_blob.maxY = -1;
      m_blob.width = -1;
      m_blob.height = -1;
      m_blob.pixels = null;
    }
  }
  
  protected boolean matchesConstraints(int pixel)
  { 
    int h = int(hue(pixel));
    int s = int(saturation(pixel));
    int b = int(brightness(pixel));
    
    // Hue's actually wrap around.
    int hueDelta = abs(h - m_constraints.hue);
    if (hueDelta > 128)
      hueDelta = 256 - hueDelta;
    
    if (hueDelta <= m_constraints.hueThreshold &&
        abs(s - m_constraints.saturation) <= m_constraints.saturationThreshold &&
        abs(b - m_constraints.brightness) <= m_constraints.brightnessThreshold)
    {
      return true;
    }
    else
    {
      return false;
    }
  }
  
  protected void setPixels(PImage image, Blob blob)
  {
    int dest = 0;
    int rowStart = blob.minY * image.width + blob.minX;

    blob.pixels = new boolean[m_blob.width * m_blob.height];
    for (int y = 0 ; y < blob.height ; y++)
    {
      int index = rowStart;
      
      for (int x = 0 ; x < blob.width ; x++)
      {
        if (matchesConstraints(image.pixels[index++]))
        {
          blob.pixels[dest++] = true;
        }
        else
        {
          blob.pixels[dest++] = false;
        }
      }
      
      rowStart += image.width;
    }
  }
  
  public Blob getBlob()
  {
    return m_blob;
  }
};

