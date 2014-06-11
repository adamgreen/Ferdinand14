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
#ifndef INT32_VECTOR_H_
#define INT32_VECTOR_H_

#include <stdint.h>
#include "Int16Vector.h"


class Int32Vector
{
public:
    Int32Vector(int32_t x, int32_t y, int32_t z)
    {
        m_x = x;
        m_y = y;
        m_z = z;
    }
    Int32Vector()
    {
        m_x = 0;
        m_y = 0;
        m_z = 0;
    }

    template <class T>
    void add(T* p)
    {
        m_x += p->m_x;
        m_y += p->m_y;
        m_z += p->m_z;
    }

    int32_t m_x;
    int32_t m_y;
    int32_t m_z;

protected:
};

#endif /* INT32_VECTOR_H_ */
