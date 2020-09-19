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

module moss.format.binary.metaPayload;

import moss.format.binary.payload;
import moss.format.binary.record;

/**
 * The MetaPayload type allows us to encode metadata into a payload
 * trivially.
 */
struct MetaPayload
{

public:

    Payload pt;
    alias pt this;

    static MetaPayload opCall()
    {
        MetaPayload r;
        r.type = PayloadType.Meta;
        r.compression = PayloadCompression.None;
        return r;
    }

    /**
     * Add Records with their associated data.
     */
    final void addRecord(R : RecordTag, T)(R key, auto const ref T datum) @trusted
    {
        numRecords++;
    }

private:

    /* Dynamically allocated storage */
    ubyte[] binary;
}
