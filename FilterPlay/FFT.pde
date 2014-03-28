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
Complex[] calculateFFT(Complex[] samples)
{
  // Size of sample array must be a power of 2.
  assert(0 == (samples.length & (samples.length - 1)));

  decomposeSamples(samples);
  
  int sampleCount = samples.length;
  int levels = ceil(log(sampleCount) / log(2));
  for (int level = 1 ; level <= levels ; level++)
  {
    int count = 1 << level;
    int halfCount = count / 2;
    Complex U = new Complex(1.0, 0.0f);
    Complex S = new Complex(cos(PI/halfCount), -sin(PI/halfCount));
    for (int j = 1 ; j <= halfCount ; j++)
    {
      for (int i = j - 1 ; i < sampleCount - 1 ; i+= count)
      {
        int pairIndex = i + halfCount;
        Complex T = Complex_multiply(samples[pairIndex], U);
        samples[pairIndex] = Complex_subtract(samples[i], T);
        samples[i] = Complex_add(samples[i], T);
      }
      U = Complex_multiply(U, S);
    }
  }
  
  return samples;
}

void decomposeSamples(Complex[] samples)
{
  int sampleCount = samples.length;
  int bits = ceil(log(sampleCount) / log(2));
  
  for (int i = 1 ; i < samples.length ; i++)
  {
      int j = flipBits(i, bits);
      if (i < j)
      {
        // Only need to swap when current index is lower than bit flipped version of index is higher.
        // If it is higher then the flip has already taken place in a previous iteration of this loop.
        Complex temp = samples[j];
        samples[j] = samples[i];
        samples[i] = temp;
      }
  }
}

int flipBits(int value, int bitCount)
{
  int result = 0;
  for (int i = 0 ; i < bitCount ; i++)
  {
    result <<= 1;
    if ((value & 1) == 1)
      result |= 1;
    value >>= 1;
  }
  return result;
}

Complex[] calculateInverseFFT(Complex[] fftData)
{
  for (int i = 0 ; i < fftData.length ; i++)
  {
    fftData[i].imaginary = -fftData[i].imaginary;
  }
  
  calculateFFT(fftData);
  
  for (int i = 0 ; i < fftData.length ; i++)
  {
    fftData[i].real = fftData[i].real / fftData.length;
    fftData[i].imaginary = -fftData[i].imaginary / fftData.length;
  }
  
  return fftData;
}

Float[] calculateMagnitudes(Complex[] fftData)
{
  Float[] results = new Float[fftData.length];
  for (int i = 0 ; i < fftData.length ; i++)
  {
    results[i] = new Float(sqrt(fftData[i].real * fftData[i].real + fftData[i].imaginary * fftData[i].imaginary));
  }
  return results;
}
