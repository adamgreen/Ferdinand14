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
  public Blob      prev;
  public Blob      equivalent;
  public int       minX;
  public int       minY;
  public int       maxX;
  public int       maxY;
  public int       width;
  public int       height;
  public int       label;
  public boolean[] pixels;
  
  public Blob(Blob prev)
  {
    minX = Integer.MAX_VALUE;
    minY = Integer.MAX_VALUE;
    maxX = Integer.MIN_VALUE;
    maxY = Integer.MIN_VALUE;
    width = 0;
    height = 0;
    this.prev = prev;
    if (prev == null)
      label = 1;
    else
      label = prev.label + 1;
  }
  
  public void addPixel(int pointX, int pointY)
  {
    minX = min(minX, pointX);
    minY = min(minY, pointY);
    maxX = max(maxX, pointX);
    maxY = max(maxY, pointY);
  }
  
  public void merge(Blob other)
  {
    minX = min(minX, other.minX);
    minY = min(minY, other.minY);
    maxX = max(maxX, other.maxX);
    maxY = max(maxY, other.maxY);
  }
};

class BlobDetector
{
  protected BlobConstraints m_constraints;
  protected Blob            m_blobs;
  protected Blob            m_next;
  protected Blob[]          m_pixelLabels;
  protected int             m_imageWidth;
  protected int             m_imageHeight;
  protected int             m_minNeighbourLabel;
  protected Blob            m_minNeighbour;
  
  public BlobDetector(BlobConstraints constraints)
  {
    m_constraints = constraints;
  }
  
  public void setConstraints(BlobConstraints constraints)
  {
    m_constraints = constraints;
  }
  
  public void update(PImage image)
  {
    image.loadPixels();
    m_imageWidth = image.width;
    m_imageHeight = image.height;
    m_pixelLabels = new Blob[image.pixels.length];
    m_blobs = null;
    
    firstPass(image);
    secondPass(image);
    rewindBlobPointer();
  }
  
  protected void firstPass(PImage image)
  {
    int index = 0;
    for (int y = 0 ; y < m_imageHeight ; y++)
    {
      for (int x = 0 ; x < m_imageWidth ; x++)
      {
        if (matchesConstraints(image.pixels[index++]))
        {
          Blob minNeighbour = findNeighbourWithLowestId(x, y);
          if (minNeighbour == null)
          {
            m_blobs = new Blob(m_blobs);
            m_blobs.addPixel(x, y);
            setPixelLabel(x, y, m_blobs);
          }
          else
          {
            minNeighbour.addPixel(x, y);
            setPixelLabel(x, y, minNeighbour);
            updateNeighbourEquivalences(x, y, minNeighbour);
          }
        }
      }
    }
  }
  
  protected boolean matchesConstraints(int pixel)
  { 
    int h = int(hue(pixel));
    int s = int(saturation(pixel));
    int b = int(brightness(pixel));
    
    // Hue's actually wrap around from 0 to 255.
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
  
  protected Blob findNeighbourWithLowestId(int x, int y)
  {
    m_minNeighbourLabel = Integer.MAX_VALUE;
    m_minNeighbour = null;
    
    checkNeighbourPixel(x - 1, y);
    checkNeighbourPixel(x - 1, y - 1);
    checkNeighbourPixel(x    , y - 1);
    checkNeighbourPixel(x + 1, y - 1);
    
    return m_minNeighbour;
  }
  
  protected void checkNeighbourPixel(int x, int y)
  {
    if (x < 0 || x >= m_imageWidth || y < 0 || y >= m_imageHeight)
      return;
    
    Blob blob = m_pixelLabels[y * m_imageWidth + x];
    if (blob != null && blob.label < m_minNeighbourLabel)
    {
      m_minNeighbourLabel = blob.label;
      m_minNeighbour = blob;
    }
  }
  
  protected void setPixelLabel(int x, int y, Blob labelBlob)
  {
    m_pixelLabels[y * m_imageWidth + x] = labelBlob;
  }
  
  protected void updateNeighbourEquivalences(int x, int y, Blob equiv)
  {
    updateNeighbourLabelEquivalence(x - 1, y    , equiv);
    updateNeighbourLabelEquivalence(x - 1, y - 1, equiv);
    updateNeighbourLabelEquivalence(x    , y - 1, equiv);
    updateNeighbourLabelEquivalence(x + 1, y - 1, equiv);
  }
  
  protected void updateNeighbourLabelEquivalence(int x, int y, Blob equiv)
  {
    if (x < 0 || x >= m_imageWidth || y < 0 || y >= m_imageHeight)
      return;
    
    Blob blob = m_pixelLabels[y * m_imageWidth + x];
    if (blob != null && blob !=  equiv)
    {
      blob.equivalent = equiv;
    }
  }
  
  protected void secondPass(PImage image)
  {
    Blob curr = m_blobs;
    Blob lastRoot = null;
    
    while (curr != null)
    {
      if (curr.equivalent == null)
      {
        // This is a root blob that now contains all pixels for a full blob after merging.
        curr.width = curr.maxX - curr.minX + 1;
        curr.height = curr.maxY - curr.minY + 1;
        setPixels(image, curr);
        
        // Remove all blobs from the list which aren't also roots.
        if (lastRoot == null)
        {
          m_blobs = curr;
        }
        else
        {
          lastRoot.prev = curr;
        }
        lastRoot = curr;
      }
      else
      {
        // This blob should be merged into a lower labelled blob.
        curr.equivalent.merge(curr);
      }
      
      curr = curr.prev;
    }
  } 
  
  protected void setPixels(PImage image, Blob blob)
  {
    int dest = 0;
    int rowStart = blob.minY * image.width + blob.minX;

    blob.pixels = new boolean[blob.width * blob.height];
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
  
  public void rewindBlobPointer()
  {
    m_next = m_blobs;
  }
  
  public Blob getNextBlob()
  {
    Blob next = m_next;
    
    if (m_next != null)
      m_next = m_next.prev;
    
    return next;
  }
};

