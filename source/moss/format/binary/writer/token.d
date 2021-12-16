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

module moss.format.binary.writer.token;

import core.stdc.stdio : FILE;
import xxhash : XXH3_64;

import moss.format.binary.payload.header;

/**
 * A WriterToken implementation knows how to perform various compression
 * techniques, hash/checksum verification, etc.
 */
public abstract class WriterToken
{

    @disable this();

    /**
     * Super constructor for all WriterTokens.
     */
    this(FILE* fp) @trusted
    {
        this._fp = fp;
        checksumHelper = new XXH3_64();
    }

    /**
     * Implementations should simply override encodeData to return the newly
     * compressed data using whatever method is deemed appropriate.
     * For "no compression" we just return the same data.
     */
    abstract ubyte[] encodeData(ref ubyte[] data) @trusted
    {
        return data;
    }

    /**
     * Flush all encodings, returning the remainder.
     */
    abstract ubyte[] flushData() @trusted
    {
        return null;
    }

    /**
     * Append data to the stream, updating the known sizes + checksum.
     */
    final void appendData(ubyte[] data) // FIXME: Return SumType error type?
    {
        import std.exception : enforce;
        import core.stdc.stdio : fwrite;

        _sizePlain += data.length;
        auto encoded = encodeData(data);
        _sizeCompressed += encoded.length;
        checksumHelper.put(encoded);

        enforce(fp !is null, "WriterToken.appendData(): No file pointer!");

        /* Dump what we have to the stream */
        enforce(fwrite(encoded.ptr, ubyte.sizeof, encoded.length,
                fp) == encoded.length, "WriterToken.appendData(): Failed to write data");
    }

    /**
     * Flush any remaining data to the stream.
     */
    final void flush() // FIXME: Return SumType error type?
    {
        import core.stdc.stdio : fwrite;
        import std.exception : enforce;

        auto flushedSet = flushData();
        if (flushedSet is null || flushedSet.length < 1)
        {
            return;
        }

        /* Got something left to write... */
        _sizeCompressed += flushedSet.length;
        checksumHelper.put(flushedSet);

        enforce(fp !is null, "WriterToken.flush(): No file pointer!");

        /* Dump what we have to the stream */
        enforce(fwrite(flushedSet.ptr, ubyte.sizeof, flushedSet.length,
                fp) == flushedSet.length, "WriterToken.end(): Failed to write data");
    }

    /**
     * Append a single byte to the stream.
     */
    final void appendData(ubyte datum) // FIXME: Return SumType error type?
    {
        ubyte[1] data = [datum];
        appendData(data);
    }

package:

    /**
     * Begin encoding by emitting a Dumb header.
     */
    final void begin() @trusted
    {
        /* Forcibly encode a dumb header for this session */
        auto hdr = PayloadHeader();
        hdr.type = PayloadType.Dumb;
        hdr.compression = PayloadCompression.None;
        hdr.encode(fp);

        /* Reset current knowledge. */
        sizePlain = 0;
        sizeCompressed = 0;
        checksum = [0, 0, 0, 0, 0, 0, 0, 0];
    }

    /**
     * End encoding by flushing underlying streams.
     */
    final void end() @trusted
    {
        flush();
        checksum = checksumHelper.finish();
    }

    /**
     * Return the file pointer property.
     */
    pragma(inline, true) pure final @property FILE* fp() @safe @nogc nothrow
    {
        return _fp;
    }

    /**
     * Return the total size when decompressed.
     */
    pragma(inline, true) pure final @property uint64_t sizePlain() @safe @nogc nothrow
    {
        return _sizePlain;
    }

    /**
     * Return the total size when compressed.
     */
    pragma(inline, true) pure final @property uint64_t sizeCompressed() @safe @nogc nothrow
    {
        return _sizeCompressed;
    }

    /**
     * Return the calculated XXHash3!64 value.
     */
    pragma(inline, true) pure final @property ubyte[8] checksum() @safe @nogc nothrow
    {
        return _checksum;
    }

private:

    /**
     * Update the file pointer property.
     */
    pragma(inline, true) pure @property void fp(FILE* fp) @safe @nogc nothrow
    {
        _fp = fp;
    }

    /**
     * Set the compressed size.
     */
    pragma(inline, true) pure @property void sizeCompressed(uint64_t newSize) @safe @nogc nothrow
    {
        _sizeCompressed = newSize;
    }

    /**
     * Set the plain size.
     */
    pragma(inline, true) pure @property void sizePlain(uint64_t newSize) @safe @nogc nothrow
    {
        _sizePlain = newSize;
    }

    /**
     * Set the known checksum value.
     */
    pragma(inline, true) pure @property void checksum(ubyte[8] newChecksum) @safe @nogc nothrow
    {
        _checksum = newChecksum;
    }

    FILE* _fp = null;
    XXH3_64 checksumHelper;
    uint64_t _sizeCompressed = 0;
    uint64_t _sizePlain = 0;
    ubyte[8] _checksum = [0, 0, 0, 0, 0, 0, 0, 0];
}

/**
 * A PlainWriterToken encodes directly to the stream without any compression.
 */
final class PlainWriterToken : WriterToken
{

    @disable this();

    /**
     * Construct new PlainWriterToken from the given file pointer.
     */
    this(FILE* fp) @safe
    {
        super(fp);
    }

    override ubyte[] encodeData(ref ubyte[] data) @safe @nogc nothrow
    {
        return data;
    }

    override ubyte[] flushData() @safe @nogc nothrow
    {
        return null;
    }
}
