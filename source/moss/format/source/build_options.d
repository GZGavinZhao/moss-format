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

module moss.format.source.build_options;

public import moss.format.source.schema;

/**
 * The TuningSelectionType indicates whether we're explicitly
 * enabling, disabling, or enabling and setting to a specific value.
 */
final enum TuningSelectionType
{
    Enable = 0,
    Disable = 1,
    Config = 2,
}

/**
 * A TuningSelection corresponds to a TuningGroup.
 */
struct TuningSelection
{
    /**
     * Name of the tuning group.
     */
    string name;

    /**
     * Type of the Tuning Selection.
     */
    TuningSelectionType type = TuningSelectionType.Enable;

    /**
     * Optional configuration value.
     */
    string configValue = null;
}

/**
 * A set of Build Options set global build configurations, such as the
 * toolchain to be used, what flags to use, etc.
 */
struct BuildOptions
{
    /**
     * The toolchain defaults to LLVM, but can be changed if required
     * to the GNU toolchain, including GCC + binutils.
     */
    @YamlSchema("toolchain", false, YamlType.Single, ["gnu", "llvm"]) string toolchain = "llvm";

    /**
     * Context Sensitive Profile Guided Optimisation
     *
     * Turning this on will result in a multiple stage profiling build of the
     * project and execution of the workload, in the hopes of a finer tuned
     * profile data set.
     */
    @YamlSchema("cspgo") bool cspgo = true;

    /**
     * Sample Profile Guided Optimisation.
     *
     * When enabling samplepgo, parts of the code not run during workload will
     * no longer be optimized for size. This is handy when you have an important
     * workload to tune, but has low coverage overall.
     */
    @YamlSchema("samplepgo") bool samplepgo = false;

    /**
     * Whether to strip ELF files to eliminate unneeded code and reduce file
     * size.
     */
    @YamlSchema("strip") bool strip = true;

    /**
     * A set of tuning selections to apply. Constructed at runtime through
     * parsing.
     */
    TuningSelection[] tuneSelections = [];

    /**
     * Return true if the tuning selection is present.
     */
    pure bool hasTuningSelection(string name) @safe
    {
        foreach (ref sel; tuneSelections)
        {
            if (sel.name == name)
            {
                return true;
            }
        }
        return false;
    }
}
