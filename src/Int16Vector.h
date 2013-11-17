/*  Copyright (C) 2013  Adam Green (https://github.com/adamgreen)

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
*/
#ifndef INT16_VECTOR_H_
#define INT16_VECTOR_H_

#include <stdint.h>


class Int16Vector
{
public:
    Int16Vector(int16_t x, int16_t y, int16_t z)
    {
        m_x = x;
        m_y = y;
        m_z = z;
    }
    Int16Vector()
    {
        m_x = 0;
        m_y = 0;
        m_z = 0;
    }
    
    int16_t m_x;
    int16_t m_y;
    int16_t m_z;
};

#endif /* INT16_VECTOR_H_ */
