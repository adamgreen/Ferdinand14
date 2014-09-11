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
class ConfigFile
{
  public ConfigFile(String configFilename)
  {
    m_lines = loadStrings(configFilename);
  }
  
  public String getString(String paramName)
  {
    String paramValue = findParam(paramName);
    if (paramValue != null)
      return paramValue;
    return null;
  }
  
  public int getInt(String paramName)
  {
    String paramValue = findParam(paramName);
    if (paramValue != null)
      return int(paramValue);
    throw new RuntimeException("Parameter " + paramName + " not found");
  }
  
  public IntVector getIntVector(String paramName)
  {
    String paramValue = findParam(paramName);
    if (paramValue != null)
    {
      String fields[] = splitTokens(paramValue, ", ");
      if (fields.length < 3)
        return null;
      return new IntVector(int(fields[0]), int(fields[1]), int(fields[2]));
    }
    return null;
  }
  
  public FloatVector getFloatVector(String paramName)
  {
    String paramValue = findParam(paramName);
    if (paramValue != null)
    {
      String fields[] = splitTokens(paramValue, ", ");
      if (fields.length < 3)
        return null;
      return new FloatVector(float(fields[0]), float(fields[1]), float(fields[2]));
    }
    return null;
  }
  
  protected String findParam(String paramName)
  {
    for (int i = 0 ; i < m_lines.length ; i++)
    {
      String tokens[] = splitTokens(m_lines[i], "=\n");
      if (tokens.length > 1 && tokens[0].charAt(0) != '#' && tokens[0].equals(paramName))
        return m_lines[i].substring(tokens[0].length() + 1);
    }
    return null;
  }
  
  String m_lines[];
};


class FloatVector
{
  public FloatVector(float x, float y, float z)
  {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  
  public FloatVector()
  {
    this.x = 0.0f;
    this.y = 0.0f;
    this.z = 0.0f;
  }
  
  public float x;
  public float y;
  public float z;
};


class IntVector
{
  public IntVector(int x, int y, int z)
  {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  
  public IntVector()
  {
    this.x = 0;
    this.y = 0;
    this.z = 0;
  }
  
  public int x;
  public int y;
  public int z;
};

