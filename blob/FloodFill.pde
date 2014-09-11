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
class FillResults
{
  public PImage          highlightedImage;
  public BlobConstraints constraints;
  public int             filledPixels;
  
  public FillResults(int hue, int saturation, int brightness, int hueThreshold, int saturationThreshold, int brightnessThreshold, int filledPixels, PImage highlightedImage)
  {
    constraints = new BlobConstraints(hue, saturation, brightness, hueThreshold, saturationThreshold, brightnessThreshold);
    this.filledPixels = filledPixels;
    this.highlightedImage = highlightedImage;
    this.highlightedImage.updatePixels();
  }
};

class FloodFill
{
  protected class PixelData
  {
    int       x;
    int       y;
    int       otherHue;
    int       otherSaturation;
    int       otherBrightness;
    PixelData next;
    
    PixelData(int x, int y, int hue, int saturation, int brightness)
    {
      this.x = x;
      this.y = y;
      otherHue = hue;
      otherSaturation = saturation;
      otherBrightness = brightness;
      next = null;
    }
  };
  
  protected PImage          m_image;
  protected PImage          m_highlightedImage;
  protected float           m_threshold;
  protected int             m_highlightColor;
  protected int[]           m_checked;
  protected int             m_filledPixels;
  protected int             m_minHue;
  protected int             m_minSaturation;
  protected int             m_minBrightness;
  protected int             m_maxHue;
  protected int             m_maxSaturation;
  protected int             m_maxBrightness;
  protected PixelData       m_head;
  protected PixelData       m_tail;

  public FillResults findColorThresholds(PImage image, int x, int y, float threshold, int highlightColor)
  {
    int   currPixel = image.pixels[y * image.width + x];
    int   currHue = int(hue(currPixel));
    int   currSaturation = int(saturation(currPixel));
    int   currBrightness = int(brightness(currPixel));
    int   filledPixels = 1;
  
    m_image = image;
    m_threshold = threshold;
    m_highlightColor = highlightColor;
    m_checked = new int[image.pixels.length];
    m_filledPixels = 1;
    m_highlightedImage = createImage(image.width, image.height, RGB);
    m_highlightedImage.copy(image, 0, 0, image.width, image.height, 0, 0, m_highlightedImage.width, m_highlightedImage.height);
    m_highlightedImage.loadPixels();

    m_minHue = currHue;
    m_minSaturation = currSaturation;
    m_minBrightness = currBrightness;
    m_maxHue = currHue;
    m_maxSaturation = currSaturation;
    m_maxBrightness = currBrightness; 
  
    queueNeighbour(x, y, currHue, currSaturation, currBrightness);
  
    while (m_head != null)
    {
      PixelData curr = m_head;
      m_head = m_head.next;
      if (m_head == null)
        m_tail = null;
        
      checkNeighbour(curr);
    }  
    
    // Hue's actually wrap around from 0 to 255.
    int hue;
    int hueThreshold;
    if (m_maxHue - m_minHue > 128)
    {
      m_minHue += 256;
      hue = (m_minHue + m_maxHue) / 2;
      hueThreshold = (m_minHue - m_maxHue) / 2;
      if (hue >= 256)
        hue -= 256;
    }
    else
    {
      hue = (m_minHue + m_maxHue) / 2;
      hueThreshold = (m_maxHue - m_minHue) / 2;
    }
    
    int saturation = (m_minSaturation + m_maxSaturation) / 2;
    int brightness = (m_minBrightness + m_maxBrightness) / 2;
    int saturationThreshold = (m_maxSaturation - m_minSaturation) / 2;
    int brightnessThreshold = (m_maxBrightness - m_minBrightness) / 2;
    
    return new FillResults(hue, saturation, brightness, hueThreshold, saturationThreshold, brightnessThreshold, m_filledPixels, m_highlightedImage);
  }
  
  protected void queueNeighbours(int x, int y, int hue, int saturation, int brightness)
  {
    queueNeighbour(x - 1, y - 1, hue, saturation, brightness);
    queueNeighbour(x    , y - 1, hue, saturation, brightness);
    queueNeighbour(x + 1, y - 1, hue, saturation, brightness);
    queueNeighbour(x - 1, y    , hue, saturation, brightness);
    queueNeighbour(x + 1, y    , hue, saturation, brightness);
    queueNeighbour(x - 1, y + 1, hue, saturation, brightness);
    queueNeighbour(x    , y + 1, hue, saturation, brightness);
    queueNeighbour(x + 1, y + 1, hue, saturation, brightness);
  }
  
  protected void queueNeighbour(int x, int y, int otherHue, int otherSaturation, int otherBrightness)
  {
    if (x < 0 || y < 0 || x >= m_image.width || y >= m_image.height || m_checked[y * m_image.width + x] != 0)
      return;
    m_checked[y * m_image.width + x] = 1;
    
    PixelData data = new PixelData(x, y, otherHue, otherSaturation, otherBrightness);
    if (m_tail == null)
    {
      m_tail = m_head = data;
    }
    else
    {
      m_tail.next = data;
      m_tail = data;
    }
  }
  
  protected void checkNeighbour(PixelData curr)
  {
    int currPixel = m_image.pixels[curr.y * m_image.width + curr.x];
    int hue = int(hue(currPixel));
    int saturation = int(saturation(currPixel));
    int brightness = int(brightness(currPixel));
    int hueDiff = hue - curr.otherHue;
    int saturationDiff = saturation - curr.otherSaturation;
    int brightnessDiff = brightness - curr.otherBrightness;
    
    // Hue's actually wrap around from 0 to 255.
    if (hueDiff > 128)
      hueDiff = 256 - hueDiff;

    float diffMagnitude = sqrt(hueDiff * hueDiff + saturationDiff * saturationDiff + brightnessDiff * brightnessDiff);
    if (diffMagnitude > m_threshold)
      return;
  
    m_highlightedImage.pixels[curr.y * m_highlightedImage.width + curr.x] = m_highlightColor;
    m_minHue = min(m_minHue, hue);
    m_minSaturation = min(m_minSaturation, saturation);
    m_minBrightness = min(m_minBrightness, brightness);
    m_maxHue = max(m_maxHue, hue);
    m_maxSaturation = max(m_maxSaturation, saturation);
    m_maxBrightness = max(m_maxBrightness, brightness);
  
    m_filledPixels++;
    
    queueNeighbours(curr.x, curr.y, hue, saturation, brightness);  
  }
};

