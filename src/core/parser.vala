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

    /** Errors raised by {@link Parser}. */
    public errordomain ParserError {
        /** Token could not be parsed as a number. */
        INVALID
    }

    /**
     * Locale-tolerant number parser, used for clipboard paste and any
     * other free-form numeric input.
     *
     * Accepts:
     *  * ''.'' or '','' as the decimal separator (rightmost wins when
     *    both are present in the same token);
     *  * thin (U+202F) and non-breaking (U+00A0) spaces as thousands
     *    separators (stripped before parsing);
     *  * scientific notation with ''e'' or ''E'';
     *  * leading sign;
     *  * leading/trailing ASCII whitespace.
     *
     * Regular ASCII whitespace (space, tab, newline, CR) separates
     * multiple values for {@link parse_multiple}.
     */
    public class Parser : Object {

        /**
         * Parse {@code input} as a single number. Returns {@code null}
         * if the input is empty, all whitespace, or not a valid number.
         */
        public static Number? parse_one (string input) {
            string trimmed = input.strip ();
            if (trimmed.length == 0) {
                return null;
            }
            return Number.from_string (normalize (trimmed));
        }

        /**
         * Parse {@code input} as zero or more whitespace-separated
         * numbers. An empty or all-whitespace input yields an empty
         * array, not an error. Throws {@link ParserError.INVALID} on
         * the first unparseable token.
         */
        public static Number[] parse_multiple (string input) throws ParserError {
            Number[] result = {};
            string[] tokens = input.split_set (" \t\n\r");
            foreach (unowned string t in tokens) {
                if (t.length == 0) {
                    continue;
                }
                var n = parse_one (t);
                if (n == null) {
                    throw new ParserError.INVALID (
                        _("Invalid number: %s"), t
                    );
                }
                result += n;
            }
            return result;
        }

        /**
         * Normalize a trimmed token to canonical base-10 form: ASCII
         * period as decimal separator, no thousands separators.
         */
        private static string normalize (string token) {
            // Strip thousands separators that are spaces.
            string s = token.replace (" ", "").replace (" ", "");

            int last_period = s.last_index_of_char ('.');
            int last_comma  = s.last_index_of_char (',');

            if (last_period < 0 && last_comma < 0) {
                return s;
            }
            if (last_period >= 0 && last_comma >= 0) {
                // Both present — rightmost is decimal.
                if (last_period > last_comma) {
                    return s.replace (",", "");
                }
                return s.replace (".", "").replace (",", ".");
            }
            if (last_comma >= 0) {
                // Only commas: single occurrence is decimal, multiple
                // are thousands separators.
                if (count_char (s, ',') == 1) {
                    return s.replace (",", ".");
                }
                return s.replace (",", "");
            }
            // Only periods, symmetrically.
            if (count_char (s, '.') == 1) {
                return s;
            }
            return s.replace (".", "");
        }

        private static int count_char (string s, char c) {
            int count = 0;
            for (int i = 0; i < s.length; i++) {
                if (s[i] == c) {
                    count++;
                }
            }
            return count;
        }
    }
}
