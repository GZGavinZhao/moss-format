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

module moss.format.binary.payload.header;

public import std.stdint;
public import std.stdio : FILE;
public import moss.format.binary.payload : PayloadType;
import moss.format.binary.endianness;

/**
 * A payload may optionally be compressed using some method like zstd.
 * It must be defined before the payload value is accessed. Additionally
 * the used compressionLevel must be stored to ensure third party tools
 * can reassemble the package.
 */
enum PayloadCompression : uint8_t
{
    /**
     * Catch errors: Compression should be known.
     */
    Unknown = 0,

    /**
     * Payload has no compression.
     */
    None = 1,

    /**
     * Payload uses ZSTD compression.
     */
    Zstd = 2,

    /**
     * Payload uses zlib decompression.
     */
    Zlib = 3,
}

/**
 * A 32-byte PayloadHeader is found in the file stream prior to the payload
 * data, and describes the version, type, etc, allowing a Payload implementation
 * to either read or write to the stream.
 *
 * We use the PayloadHeader to associate encoding/decoding by type, and bucketizing
 * the file format.
 */
extern (C) struct PayloadHeader
{
align(1):

    /**
     * 8-bytes, endian aware, length of the Payload data.
     */
    @AutoEndian uint64_t storedSize = 0;

    /**
     * 8-bytes, endian-aware, size of usable Payload data.
     */
    @AutoEndian uint64_t plainSize = 0;

    /**
     * 8-byte array containing the XXHash3!64 checksum.
     */
    ubyte[8] checksum = 0;

    /**
     * 4-bytes, endian aware, number of records within the Payload.
     */
    @AutoEndian uint32_t numRecords = 0;

    /**
     * 2-bytes, endian aware, numeric version of the Payload.
     */
    @AutoEndian uint16_t payloadVersion = 0;

    /**
     * 1 byte denoting the type of this payload.
     */
    PayloadType type = PayloadType.Unknown;

    /**
     * 1 byte denoting the compression of this payload.
     */
    PayloadCompression compression = PayloadCompression.Unknown;

    /**
     * Encode the PayloadHeader to the underlying file stream.
     */
    void encode(scope FILE* fp) @trusted
    {
        import std.stdio : fwrite;
        import std.exception : enforce;

        /* Ensure correct endian encoding */
        PayloadHeader cp = this;
        cp.toNetworkOrder();

        enforce(fwrite(&cp.storedSize, cp.storedSize.sizeof, 1, fp) == 1,
                "Failed to write PayloadHeader.storedSize");
        enforce(fwrite(&cp.plainSize, cp.plainSize.sizeof, 1, fp) == 1,
                "Failed to write PayloadHeader.plainSize");
        enforce(fwrite(cp.checksum.ptr, cp.checksum[0].sizeof,
                cp.checksum.length, fp) == cp.checksum.length,
                "Failed to write PayloadHeader.checksum");
        enforce(fwrite(&cp.numRecords, cp.numRecords.sizeof, 1, fp) == 1,
                "Failed to write PayloadHeader.numRecords");
        enforce(fwrite(&cp.payloadVersion, cp.payloadVersion.sizeof, 1,
                fp) == 1, "Failed to write PayloadHeader.payloadVersion");
        enforce(fwrite(&cp.type, cp.type.sizeof, 1, fp) == 1, "Failed to write PayloadHeader.type");
        enforce(fwrite(&cp.compression, cp.compression.sizeof, 1, fp) == 1,
                "Failed to write PayloadHeader.compression");
    }

    /**
     * Decode this PayloadHeader from the underlying file stream.
     */
    uint64_t decode(scope ubyte[] byteStream) @trusted
    {
        import std.exception : enforce;

        enforce(byteStream.length >= PayloadHeader.sizeof,
                "PayloadHeader.decode(): Insufficient storage for PayloadHeader");
        PayloadHeader cp;
        PayloadHeader* inp = cast(PayloadHeader*) byteStream[0 .. PayloadHeader.sizeof];
        cp = *inp;
        cp.toHostOrder();

        this = cp;

        /* Skip readPointer on */
        return PayloadHeader.sizeof;
    }
}

static assert(PayloadHeader.sizeof == 32,
        "Payload size must be 32 bytes, not " ~ PayloadHeader.sizeof.stringof ~ " bytes");
