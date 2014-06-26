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
class FilteredCompass
{
  public FilteredCompass()
  {
    ConfigFile configFile = new ConfigFile(System.getenv("USER") + ".config");
  
    IntVector minAccel = configFile.vectorParam("compass.accelerometer.min");
    IntVector minMag = configFile.vectorParam("compass.magnetometer.min");
    IntVector maxAccel = configFile.vectorParam("compass.accelerometer.max");
    IntVector maxMag = configFile.vectorParam("compass.magnetometer.max");
    Heading min = new Heading(minAccel.x, minAccel.y, minAccel.z, minMag.x, minMag.y, minMag.z);
    Heading max = new Heading(maxAccel.x, maxAccel.y, maxAccel.z, maxMag.x, maxMag.y, maxMag.z);
    Heading filterWidths = new Heading(16, 16, 16, 16, 16, 16);
    m_headingSensor = new HeadingSensor(configFile.param("compass.port"), min, max, filterWidths);
    m_smoothed = true;
  }

  public float getHeading()
  {
    FloatHeading heading;
    if (m_smoothed)
      heading = m_headingSensor.getCurrentFiltered();
    else
      heading = m_headingSensor.getCurrent();
    
    // The magnetometer output represents the north vector.
    // Swizzling magnetometer axis to match the accelerometer.
    PVector north = new PVector(heading.m_magY, -heading.m_magX, heading.m_magZ);
    
    // The accelerometer represents the gravity vector.
    // The gravity vector is the normal of the plane representing the surface of the earth.
    PVector gravity = new PVector(heading.m_accelX, heading.m_accelY, heading.m_accelZ);
    gravity.normalize();

    // Project the north vector onto the earth surface plane.
    north.sub(PVector.mult(gravity, north.dot(gravity)));
  
    float headingAngle = atan2(-north.y, north.x);
    return headingAngle;
  }
  
  public boolean isSmoothed()
  {
    return m_smoothed;
  }
  
  public void setSmoothed(boolean smoothed)
  {
    m_smoothed = smoothed;
  }
  
  protected HeadingSensor m_headingSensor;
  protected boolean       m_smoothed;
}

