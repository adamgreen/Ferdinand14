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
  
  public String param(String paramName)
  {
    String paramValue = findParam(paramName);
    if (paramValue != null)
      return paramValue;
    return null;
  }
  
  protected String findParam(String paramName)
  {
    for (int i = 0 ; i < m_lines.length ; i++)
    {
      String tokens[] = splitTokens(m_lines[i], "=\n");
      if (tokens.length == 2 && tokens[0].charAt(0) != '#' && tokens[0].equals(paramName))
        return tokens[1];
    }
    return null;
  }
  
  String m_lines[];
};

