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

module moss.format.binary.reader.zstd_token;

public import moss.format.binary.reader.token;

import zstd : Decompressor;

/**
 * The ZstdReaderToken provides a zstd-stream-decompression aware ReaderToken
 * implementation.
 */
public final class ZstdReaderToken : ReaderToken
{
    @disable this();

    /**
     * Construct a new ZstdReaderToken with the range of data made available
     * from the memory mapped file.
     */
    this(ref ubyte[] rangedData)
    {
        super(rangedData);
        decompressor = new Decompressor();
    }

    /**
     * Decode up to LENGTH bytes from the stream and pass it back.
     */
    override ubyte[] decodeData(uint64_t length) @trusted
    {
        while (availableStorage < length)
        {
            /* How much can we currently read? */
            auto readableSize = remainingBytes <= chunkSize ? remainingBytes : chunkSize;
            auto bytesRead = decompressor.decompress(readRaw(readableSize));
            bufferStorage ~= bytesRead;
            availableStorage += bytesRead.length;
        }

        auto retStore = bufferStorage[0 .. length];
        scope (exit)
        {
            bufferStorage = bufferStorage[length .. $];
            availableStorage -= length;
        }
        return retStore;
    }

private:

    Decompressor decompressor;

    /* Saved bytes from decompression runs */
    ubyte[] bufferStorage;

    /* How many bytes to bulk process */
    static const uint chunkSize = 128 * 1024;

    ulong availableStorage = 0;
}
