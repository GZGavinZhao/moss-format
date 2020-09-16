/*
 * This file is part of moss.
 *
 * Copyright © 2020 Serpent OS Developers
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

module moss.format.binary.writer;

import std.stdio : File;

import moss.format.binary : MossFormatVersionNumber;
import moss.format.binary.header;

import moss.format.binary.endianness;

/**
 * This class is responsible for writing binary moss packages to disk,
 * setting relevant meta-information and merging a payload.
 */
class Writer
{

private:

    string _filename;
    File _file;
    Header _header;

public:
    @disable this();

    /**
     * Construct a new Writer for the given filename
     */
    this(string filename, uint32_t versionNumber = MossFormatVersionNumber) @trusted
    {
        _filename = filename;

        _file = File(filename, "wb");
        _header = Header(versionNumber);
        _header.numRecords = 0;
        _header.toNetworkOrder();

        /* Insert the header now, we'll rewind and fix number of records */
        _file.rawWrite((&_header)[0 .. Header.sizeof]);
    }

    ~this() @safe
    {
        close();
    }

    /**
     * Return the filename for the Writer
     */
    pure final @property const(string) filename() @safe @nogc nothrow
    {
        return _filename;
    }

    /**
     * Flush and close the underying file.
     */
    final void close() @safe
    {
        if (_file.isOpen())
        {
            _file.flush();
            _file.close();
            _file = File();
        }
    }
}