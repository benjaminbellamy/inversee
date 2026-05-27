/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Inversée - Reverse Polish Notation calculator
 * Copyright (C) 2026 Benjamin Bellamy <benjamin@castopod.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

namespace Inversee {

    /**
     * A number-presentation convention: which character separates the
     * decimal part, which one groups thousands, and how tolerant the
     * clipboard parser should be when reading values in other
     * conventions.
     *
     * The same value drives display, clipboard copy, and clipboard
     * paste, so that what the user sees, copies, and pastes all agree.
     * The core engine stays locale-agnostic: callers build a {@link
     * NumberFormat} (from the OS locale or a fixed preset) and pass it to
     * {@link Parser} and to the UI formatter.
     *
     * Stored stack values are always canonical (ASCII period, no
     * grouping); a format only affects rendering and parsing.
     */
    public class NumberFormat : Object {

        /** Decimal separator used for display and (in strict mode) paste. */
        public string decimal_sep { get; construct; }

        /** Thousands/grouping separator used for display. */
        public string group_sep { get; construct; }

        /**
         * Paste strategy. When {@code true} (Automatic), the parser is
         * maximally tolerant of foreign-formatted input — useful for
         * values copied from a PDF or web page that ignore the locale.
         * When {@code false} (a fixed preset or the strict OS format),
         * {@link decimal_sep} is authoritative and every other separator
         * is treated as grouping.
         */
        public bool tolerant { get; construct; }

        public NumberFormat (string decimal_sep, string group_sep,
                             bool tolerant) {
            Object (decimal_sep: decimal_sep, group_sep: group_sep,
                    tolerant: tolerant);
        }

        /** US/UK convention: ''1,234.56''. */
        public static NumberFormat us () {
            return new NumberFormat (".", ",", false);
        }

        /** French convention: ''1 234,56'' (U+202F narrow no-break space). */
        public static NumberFormat french () {
            return new NumberFormat (",", ((unichar) 0x202F).to_string (),
                                     false);
        }

        /**
         * Continental-European convention: ''1.234,56'' (comma decimal,
         * period grouping). Covers German, Spanish, Italian, Dutch,
         * Polish, and Portuguese.
         */
        public static NumberFormat european () {
            return new NumberFormat (",", ".", false);
        }

        /**
         * Build a format from explicit separators, e.g. ones derived from
         * the running OS locale. {@code tolerant} selects Automatic
         * (best-effort) versus strict System behaviour for paste.
         */
        public static NumberFormat from_locale (string decimal_sep,
                                                string group_sep,
                                                bool tolerant) {
            return new NumberFormat (decimal_sep, group_sep, tolerant);
        }
    }
}
