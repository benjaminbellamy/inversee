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
     * Locale conversion for display strings. The core engine works
     * entirely in canonical ASCII-period form; everything user-visible
     * passes through here.
     */
    public class Localize {

        /**
         * Returns the current locale's decimal separator, e.g. "." for
         * en/POSIX, "," for fr/de. Falls back to "." if {@code
         * localeconv} returns nothing usable.
         */
        public static string decimal_separator () {
            // Format a one-digit fractional via the locale-aware printf
            // and extract whatever bytes sit between the two digits.
            // Works for multi-byte separators (e.g. some Arabic locales)
            // because Vala strings are UTF-8 byte sequences and
            // substring honours that.
            string sample = "%.1f".printf (1.0);
            if (sample.length < 3) {
                return ".";
            }
            return sample.substring (1, sample.length - 2);
        }

        /**
         * Convert a canonical-form number string (ASCII period decimal)
         * into the current-locale display form.
         */
        public static string format_number (string canonical) {
            string sep = decimal_separator ();
            if (sep == ".") {
                return canonical;
            }
            return canonical.replace (".", sep);
        }
    }
}
