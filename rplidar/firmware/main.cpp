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
/* This program runs on a mbed and pretends to be a RoboPeak RPLIDAR
   and was used to test my Processing lidar sample code. */
#include <mbed.h>

void expectToReceive(Serial& serial, const char* pData, size_t dataLength);
void sendResponse(Serial& serial, const char* pData, size_t dataLength);

int main()
{
    static Serial serial(USBTX, USBRX);
    serial.baud(115200);

    // Send complete device info response back to Mac.
    expectToReceive(serial, "\xA5\x50", 2);
    sendResponse(serial, "\xA5\x5A\x14\x00\x00\x00\x04", 7);
    sendResponse(serial, "\x12\x34\x56\x78\x9a\xbc\xde\xf0"
                         "\x12\x34\x56\x78\x9a\xbc\xde\xf0"
                         "\x12\x34\x56\x78", 20);

    // Send complete health response back to Mac.
    expectToReceive(serial, "\xA5\x52", 2);
    sendResponse(serial, "\xA5\x5A\x03\x00\x00\x00\x06", 7);
    sendResponse(serial, "\x00\x12\x34", 3);

    // Start a single scan rotation.
    expectToReceive(serial, "\xA5\x25", 2);
    expectToReceive(serial, "\xA5\x20", 2);
    sendResponse(serial, "\xA5\x5A\x05\x00\x00\x40\x81", 7);
    sendResponse(serial, "\x3D\x19\x9C\x7B\x05", 5);
    sendResponse(serial, "\x42\xBB\x9C\x83\x05", 5);
    sendResponse(serial, "\x3A\x2B\x9D\x8B\x05", 5);
    sendResponse(serial, "\x36\xA1\x9D\x91\x05", 5);
    sendResponse(serial, "\x3E\x53\x9E\x99\x05", 5);
    sendResponse(serial, "\x36\x9B\x9E\xA2\x05", 5);
    sendResponse(serial, "\x42\x1B\x9F\xAE\x05", 5);
    sendResponse(serial, "\x3E\xCD\x9F\xBE\x05", 5);
    sendResponse(serial, "\x36\x49\xA0\xCA\x05", 5);
    sendResponse(serial, "\x3A\xBF\xA0\xDE\x05", 5);
    sendResponse(serial, "\x36\x19\xA1\xFA\x05", 5);
    sendResponse(serial, "\x3A\x99\xA1\x13\x06", 5);
    sendResponse(serial, "\x32\x3F\xA2\x33\x06", 5);
    sendResponse(serial, "\x2E\xB3\xA2\x6A\x06", 5);
    sendResponse(serial, "\x2E\x1B\xA3\x9A\x06", 5);
    sendResponse(serial, "\x26\x85\xA3\xFA\x06", 5);
    sendResponse(serial, "\x36\xE7\xA3\x69\x07", 5);
    sendResponse(serial, "\x52\x75\xA4\x4B\x07", 5);
    sendResponse(serial, "\x52\x17\xA5\x2A\x07", 5);
    sendResponse(serial, "\x52\xA7\xA5\x0E\x07", 5);
    sendResponse(serial, "\x5E\x13\xA6\xFA\x06", 5);
    sendResponse(serial, "\x66\xB3\xA6\xEA\x06", 5);
    sendResponse(serial, "\x62\x41\xA7\xDD\x06", 5);
    sendResponse(serial, "\x66\xA7\xA7\xD4\x06", 5);
    sendResponse(serial, "\x62\x4F\xA8\xDF\x06", 5);
    sendResponse(serial, "\x66\xB7\xA8\xD1\x06", 5);
    sendResponse(serial, "\x6E\x55\xA9\xD1\x06", 5);
    sendResponse(serial, "\x66\xBF\xA9\xD6\x06", 5);
    sendResponse(serial, "\x66\x3F\xAA\xD8\x06", 5);
    sendResponse(serial, "\x66\xB7\xAA\xE8\x06", 5);
    sendResponse(serial, "\x52\x47\xAB\xB4\x06", 5);
    sendResponse(serial, "\x66\xDF\xAB\x96\x06", 5);
    sendResponse(serial, "\x62\x67\xAC\x70\x06", 5);
    sendResponse(serial, "\x5E\xEB\xAC\x57\x06", 5);
    sendResponse(serial, "\x5A\x89\xAD\x4E\x06", 5);
    sendResponse(serial, "\x66\x07\xAE\x2F\x06", 5);
    sendResponse(serial, "\x66\x97\xAE\x1D\x06", 5);
    sendResponse(serial, "\x62\x2B\xAF\x0E\x06", 5);
    sendResponse(serial, "\x66\x97\xAF\x02\x06", 5);
    sendResponse(serial, "\x62\x2F\xB0\xF8\x05", 5);
    sendResponse(serial, "\x66\x93\xB0\xF0\x05", 5);
    sendResponse(serial, "\x5E\x3B\xB1\xE1\x05", 5);
    sendResponse(serial, "\x5E\xCB\xB1\xDD\x05", 5);
    sendResponse(serial, "\x62\x53\xB2\xD4\x05", 5);
    sendResponse(serial, "\x62\xD5\xB2\xD1\x05", 5);
    sendResponse(serial, "\x62\x71\xB3\xCC\x05", 5);
    sendResponse(serial, "\x56\xEF\xB3\xD1\x05", 5);
    sendResponse(serial, "\x4A\x4F\x00\xDA\x05", 5);
    sendResponse(serial, "\x41\x4D\x01\x5F\x04", 5);

    // Expect a stop scan command.
    expectToReceive(serial, "\xA5\x25", 2);

    return 0;
}

void expectToReceive(Serial& serial, const char* pData, size_t dataLength)
{
    while (dataLength--)
    {
        char curr = serial.getc();
        if (curr != *pData++)
            error("Character mismatch!");
    }
}

void sendResponse(Serial& serial, const char* pData, size_t dataLength)
{
    while (dataLength--)
        serial.putc(*pData++);
}