/*
 * This file is part of moss-format.
 *
 * Copyright © 2020-2021 Serpent OS Developers
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

module moss.format.binary.legacy.index;

public import std.stdint;

import moss.format.binary.endianness;

/**
 * An IndexEntry identifies a unique file within the file payload.
 * It records the size of the file - along with the number of times
 * the file is used within the package (deduplication statistics).
 *
 * The length refers to the *value* length of the IndexEntry, i.e. how
 * long the name is.
 */
extern (C) struct IndexEntry
{
align(1):

    /** 8-bytes, endian aware, size of the file */
    @AutoEndian uint64_t size;

    /** 8-bytes, endian aware, start offset to the file */
    @AutoEndian uint64_t start;

    /** 8-bytes, endian aware, end offset of the file */
    @AutoEndian uint64_t end; /* 8 bytes */

    /** 2-bytes, endian aware, length of the file name */
    @AutoEndian uint16_t length; /* 2 bytes */

    /** 4-bytes, endian aware, how many times this unique file is referenced */
    @AutoEndian uint32_t refcount; /* 4 bytes */

    /** 2-byte array for reserved padding */
    ubyte[2] padding;

    /**
     * Encode the IndexEntry to the underlying byte buffer
     */
    void encode(ref ubyte[] p) @trusted nothrow
    {
        this.toNetworkOrder();
        p ~= (cast(ubyte*)&size)[0 .. size.sizeof];
        p ~= (cast(ubyte*)&start)[0 .. start.sizeof];
        p ~= (cast(ubyte*)&end)[0 .. end.sizeof];
        p ~= (cast(ubyte*)&length)[0 .. length.sizeof];
        p ~= (cast(ubyte*)&refcount)[0 .. refcount.sizeof];
        p ~= padding;
        this.toHostOrder();
    }
}

static assert(IndexEntry.sizeof == 32,
        "IndexEntry size must be 32 bytes, not " ~ IndexEntry.sizeof.stringof ~ " bytes");