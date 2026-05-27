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
     * Number parser for clipboard paste and other free-form input,
     * driven by a {@link NumberFormat}.
     *
     * Values are separated by ''";"'', newline, carriage return, or tab —
     * never by a bare space, which is treated as digit grouping. Within
     * each value:
     *
     *  * thin (U+202F) and non-breaking (U+00A0) spaces are always
     *    grouping separators and are stripped;
     *  * an ASCII space is grouping only when it is consistent with
     *    three-digit grouping — integer groups of three after the first
     *    (''304 650'' → ''304650''), or fractional groups of three with a
     *    1–3 digit remainder (''1,945 940 6'' → ''1,9459406''). Spaces
     *    between groups that do not fit (e.g. ''1 2 3'') separate values;
     *  * leading and trailing non-numeric characters (currency symbols,
     *    labels, units) are ignored, so ''Total: 1,234.56 €'' yields
     *    ''1234.56'';
     *  * scientific notation with ''e''/''E'' is accepted.
     *
     * Decimal/grouping disambiguation depends on {@link
     * NumberFormat.tolerant}:
     *
     *  * '''Tolerant''' (Automatic): when both ''.'' and '','' are
     *    present, the rightmost is the decimal point (so US ''1,234.56''
     *    and European ''1.234,56'' both read correctly). A lone comma is
     *    decimal only when the format's decimal separator is a comma;
     *    repeated separators of one kind are grouping.
     *  * '''Strict''' (a fixed preset or the System format): the format's
     *    decimal separator is authoritative and every other separator is
     *    grouping.
     */
    public class Parser : Object {

        /**
         * Parse {@code input} as a single number using {@code fmt}.
         * Every space is treated as grouping (the caller asserts this is
         * one value). Returns {@code null} if the input holds no digits
         * or is not a valid number.
         */
        public static Number? parse_one (string input, NumberFormat fmt) {
            string s = remove_nbsp (input).replace (" ", "");
            string core = numeric_core (s);
            if (core.length == 0) {
                return null;
            }
            return Number.from_string (normalize (core, fmt));
        }

        /**
         * Parse {@code input} as zero or more values using {@code fmt}.
         * An empty or value-free input yields an empty array. Throws
         * {@link ParserError.INVALID} on a chunk that contains digits but
         * cannot be parsed (e.g. interior garbage like ''12x34''); chunks
         * with no digits at all (stray units, labels) are skipped.
         */
        public static Number[] parse_multiple (string input, NumberFormat fmt)
                throws ParserError {
            Number[] result = {};
            string[] tokens = input.split_set (";\n\r\t");
            foreach (unowned string raw in tokens) {
                string token = remove_nbsp (raw);
                foreach (unowned string chunk in resolve_spaces (token)) {
                    string core = numeric_core (chunk);
                    if (core.length == 0) {
                        // No digits: empty token, stray unit, or label.
                        continue;
                    }
                    var num = Number.from_string (normalize (core, fmt));
                    if (num == null) {
                        throw new ParserError.INVALID (
                            _("Invalid number: %s"), chunk.strip ()
                        );
                    }
                    result += num;
                }
            }
            return result;
        }

        /** Strip thin (U+202F) and non-breaking (U+00A0) spaces. */
        private static string remove_nbsp (string s) {
            return s.replace (((unichar) 0x202F).to_string (), "")
                    .replace (((unichar) 0x00A0).to_string (), "");
        }

        /**
         * Split {@code token} into values at ASCII spaces, merging runs
         * that are joined by grouping spaces and splitting where a space
         * separates two values. Runs are merged greedily left to right:
         * a run continues the current value only when the spacing is
         * consistent with three-digit grouping (see {@link groups_with}).
         */
        private static string[] resolve_spaces (string token) {
            string[] runs = token.split (" ");
            string[] chunks = {};
            string? current = null;
            foreach (unowned string r in runs) {
                if (r.length == 0) {
                    // Double space — a hard value boundary.
                    if (current != null) {
                        chunks += current;
                        current = null;
                    }
                    continue;
                }
                if (current == null) {
                    current = r;
                } else if (groups_with (current, r)) {
                    current = current + r;
                } else {
                    chunks += current;
                    current = r;
                }
            }
            if (current != null) {
                chunks += current;
            }
            return chunks;
        }

        /**
         * Should the space-separated run {@code r} continue the
         * value-so-far {@code current} as a grouping group, rather than
         * start a new value? {@code current} must end in a digit and
         * {@code r} must begin with one. Integer groups (no decimal seen
         * yet) must be exactly three digits; fractional groups continue
         * while the preceding group is complete (a multiple of three
         * digits) and the new group is one to three digits.
         */
        private static bool groups_with (string current, string r) {
            int lead = leading_digits (r);
            if (lead == 0 || !ends_with_digit (current)) {
                return false;
            }
            if (has_decimal (current)) {
                return trailing_digits (current) % 3 == 0 && lead <= 3;
            }
            return lead == 3;
        }

        private static int leading_digits (string s) {
            int n = 0;
            while (n < s.length && s[n] >= '0' && s[n] <= '9') {
                n++;
            }
            return n;
        }

        private static int trailing_digits (string s) {
            int count = 0;
            int i = s.length - 1;
            while (i >= 0 && s[i] >= '0' && s[i] <= '9') {
                count++;
                i--;
            }
            return count;
        }

        private static bool ends_with_digit (string s) {
            int n = s.length;
            return n > 0 && s[n - 1] >= '0' && s[n - 1] <= '9';
        }

        private static bool has_decimal (string s) {
            return s.index_of_char ('.') >= 0 || s.index_of_char (',') >= 0;
        }

        /**
         * Extract the numeric core of {@code chunk}: the span from the
         * first ASCII digit (extended left over a run of ''+ - . ,'' that
         * may introduce it) to the last ASCII digit. Returns the empty
         * string when {@code chunk} contains no digit. Interior garbage is
         * preserved so it later fails to parse rather than being silently
         * dropped.
         */
        private static string numeric_core (string chunk) {
            int n = chunk.length;
            int first = -1;
            int last = -1;
            for (int i = 0; i < n; i++) {
                char c = chunk[i];
                if (c >= '0' && c <= '9') {
                    if (first < 0) {
                        first = i;
                    }
                    last = i;
                }
            }
            if (first < 0) {
                return "";
            }
            int start = first;
            while (start > 0) {
                char p = chunk[start - 1];
                if (p == '+' || p == '-' || p == '.' || p == ',') {
                    start--;
                } else {
                    break;
                }
            }
            var sb = new StringBuilder ();
            for (int i = start; i <= last; i++) {
                sb.append_c (chunk[i]);
            }
            return sb.str;
        }

        /**
         * Resolve the decimal and grouping separators of a space-free,
         * trimmed {@code core} to canonical base-10 form (ASCII period
         * decimal, no grouping), per {@code fmt}.
         */
        private static string normalize (string core, NumberFormat fmt) {
            int last_period = core.last_index_of_char ('.');
            int last_comma  = core.last_index_of_char (',');

            if (last_period < 0 && last_comma < 0) {
                return core;
            }

            if (!fmt.tolerant) {
                // Strict: the format's decimal separator wins; the other
                // kind is grouping.
                if (fmt.decimal_sep == ",") {
                    return core.replace (".", "").replace (",", ".");
                }
                return core.replace (",", "");
            }

            // Tolerant (Automatic).
            if (last_period >= 0 && last_comma >= 0) {
                // Both present — the rightmost is the decimal point.
                if (last_period > last_comma) {
                    return core.replace (",", "");
                }
                return core.replace (".", "").replace (",", ".");
            }
            if (last_comma >= 0) {
                // Only commas: a single comma is decimal iff the locale's
                // decimal separator is a comma; otherwise it groups.
                if (count_char (core, ',') == 1 && fmt.decimal_sep == ",") {
                    return core.replace (",", ".");
                }
                return core.replace (",", "");
            }
            // Only periods: a single period is decimal; repeats group.
            if (count_char (core, '.') == 1) {
                return core;
            }
            return core.replace (".", "");
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
