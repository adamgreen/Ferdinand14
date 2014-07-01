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
#ifndef INT_VECTOR_H_
#define INT_VECTOR_H_

#include <stdint.h>


template <class T>
class IntVector
{
public:
    IntVector(T x, T y, T z)
    {
        m_x = x;
        m_y = y;
        m_z = z;
    }
    IntVector()
    {
        clear();
    }

    template <class S>
    void add(IntVector<S>* p)
    {
        m_x += p->m_x;
        m_y += p->m_y;
        m_z += p->m_z;
    }

    void clear()
    {
        m_x = 0;
        m_y = 0;
        m_z = 0;
    }

    T m_x;
    T m_y;
    T m_z;
};

#endif /* INT_VECTOR_H_ */
