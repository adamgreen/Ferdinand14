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
class Complex
{
  Complex(float r, float i)
  {
    real = r;
    imaginary = i;
  }
  
  float real;
  float imaginary;
};

Complex Complex_multiply(Complex c1, Complex c2)
{
  return new Complex(c1.real * c2.real - c1.imaginary * c2.imaginary, c1.imaginary * c2.real + c1.real * c2.imaginary);
}

Complex Complex_subtract(Complex c1, Complex c2)
{
  return new Complex(c1.real - c2.real, c1.imaginary - c2.imaginary);
}

Complex Complex_add(Complex c1, Complex c2)
{
  return new Complex(c1.real + c2.real, c1.imaginary + c2.imaginary);
}

