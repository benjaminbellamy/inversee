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
     *
     * The active {@link NumberFormat} (selected from the Format menu and
     * persisted in GSettings) is cached here and consulted by {@link
     * format_number}, the keypad decimal key, and the clipboard parser,
     * so display, copy, and paste all agree.
     */
    public class Localize {

        private static NumberFormat _active = null;

        /**
         * The format currently in effect. Defaults to an Automatic format
         * derived from the OS locale until {@link apply_format_code} runs.
         */
        public static NumberFormat active_format () {
            if (_active == null) {
                _active = os_locale_format (true);
            }
            return _active;
        }

        /**
         * The format derived from the running OS locale (its decimal and
         * grouping separators), tolerant or strict on paste per {@code
         * tolerant}. Used for the Automatic and System choices.
         */
        private static NumberFormat os_locale_format (bool tolerant) {
            return NumberFormat.from_locale (
                decimal_separator (), thousands_separator (), tolerant);
        }

        /**
         * Rebuild the cached active format from a stored format code
         * (''auto'', ''os'', ''us'', ''fr'', ''eu''). Called once at
         * startup and again whenever the user changes the Format menu.
         */
        public static void apply_format_code (string code) {
            switch (code) {
                case "us":
                    _active = NumberFormat.us ();
                    break;
                case "fr":
                    _active = NumberFormat.french ();
                    break;
                case "eu":
                    _active = NumberFormat.european ();
                    break;
                case "os":
                    _active = os_locale_format (false);
                    break;
                case "auto":
                default:
                    _active = os_locale_format (true);
                    break;
            }
        }

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
         * Returns the current locale's digit-grouping (thousands)
         * separator, e.g. "," for en, U+202F for fr/de. Returns the empty
         * string for locales that do not group (C/POSIX).
         */
        public static string thousands_separator () {
            // The first run of non-digit bytes in a grouped integer is the
            // grouping separator. Handles multi-byte separators such as
            // U+202F (narrow no-break space) used by most European locales.
            string sample = "%'d".printf (1000);
            var sb = new StringBuilder ();
            int index = 0;
            unichar c;
            bool started = false;
            while (sample.get_next_char (ref index, out c)) {
                bool is_digit = (c >= '0' && c <= '9');
                if (!started) {
                    if (!is_digit) {
                        started = true;
                        sb.append_unichar (c);
                    }
                } else {
                    if (is_digit) {
                        break;
                    }
                    sb.append_unichar (c);
                }
            }
            return sb.str;
        }

        /**
         * Convert a canonical-form number string (ASCII period decimal,
         * no grouping) into the current-locale display form: locale
         * decimal separator and digit grouping on the integer part.
         *
         * Scientific-notation values are passed through without grouping
         * (the mantissa is short and the exponent must stay intact); only
         * the decimal separator is localized.
         */
        public static string format_number (string canonical) {
            NumberFormat fmt = active_format ();
            string sep = fmt.decimal_sep;
            string thou = fmt.group_sep;

            bool scientific = canonical.index_of ("e") >= 0
                           || canonical.index_of ("E") >= 0;

            // Split off an optional leading sign.
            string sign = "";
            string body = canonical;
            if (body.has_prefix ("-")) {
                sign = "-";
                body = body.substring (1);
            } else if (body.has_prefix ("+")) {
                body = body.substring (1);
            }

            // Split integer and fractional parts on the canonical period.
            string int_part = body;
            string frac_part = null;
            int dot = body.index_of (".");
            if (dot >= 0) {
                int_part = body.substring (0, dot);
                frac_part = body.substring (dot + 1);
            }

            if (!scientific && thou != "") {
                if (int_part.length > 3) {
                    int_part = group_integer (int_part, thou);
                }
                // Group the fractional digits too (in threes from the
                // left), but only when the separator is a space — comma
                // or period grouping there would read as a second decimal
                // point and break clipboard round-trips, and US/European
                // conventions don't group the fractional part anyway.
                if (frac_part != null && frac_part.length > 3
                    && is_space (thou)) {
                    frac_part = group_fraction (frac_part, thou);
                }
            }

            string result = sign + int_part;
            if (dot >= 0) {
                result += sep + frac_part;
            }
            return result;
        }

        /** Whether {@code sep} is a (possibly non-breaking) space. */
        private static bool is_space (string sep) {
            if (sep.length == 0) {
                return false;
            }
            unichar c = sep.get_char (0);
            return c == ' ' || c == 0x00A0 || c == 0x202F;
        }

        /**
         * Insert {@code sep} between groups of three digits of {@code
         * digits} (counted from the right). {@code digits} must be ASCII
         * decimal digits only. Groups of three cover every locale Inversée
         * ships translations for.
         */
        private static string group_integer (string digits, string sep) {
            var sb = new StringBuilder ();
            int n = digits.length;
            for (int i = 0; i < n; i++) {
                if (i > 0 && (n - i) % 3 == 0) {
                    sb.append (sep);
                }
                sb.append_c (digits[i]);
            }
            return sb.str;
        }

        /**
         * Insert {@code sep} between groups of three fractional digits
         * (counted from the left, so the final group may be shorter).
         * {@code digits} must be ASCII decimal digits only.
         */
        private static string group_fraction (string digits, string sep) {
            var sb = new StringBuilder ();
            int n = digits.length;
            for (int i = 0; i < n; i++) {
                if (i > 0 && i % 3 == 0) {
                    sb.append (sep);
                }
                sb.append_c (digits[i]);
            }
            return sb.str;
        }
    }
}
