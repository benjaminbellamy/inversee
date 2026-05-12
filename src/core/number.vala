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
     * An arbitrary-precision real number backed by MPFR.
     *
     * Internal precision is 128 bits (~38 decimal digits). All arithmetic
     * uses round-to-nearest, ties-to-even (MPFR_RNDN). The class is
     * effectively immutable: every operation returns a fresh instance and
     * the underlying MPFR value is set exactly once.
     */
    public class Number : Object {

        /** Internal precision in bits. */
        public const long PRECISION = 128;

        /** Default display precision in significant decimal digits. */
        public const int DISPLAY_DIGITS = 12;

        /**
         * Canonical-form precision: enough digits to losslessly round-trip
         * a 128-bit MPFR value through a base-10 string.
         */
        public const int CANONICAL_DIGITS = 40;

        private MPFR.MPFloat value;

        /** Constructs a Number equal to zero. */
        public Number () {
            this.value = new MPFR.MPFloat (PRECISION);
            this.value.set_d (0.0, MPFR.Round.N);
        }

        /** Constructs a Number from a finite C double. */
        public Number.from_double (double d) {
            this.value = new MPFR.MPFloat (PRECISION);
            this.value.set_d (d, MPFR.Round.N);
        }

        /** Constructs a deep copy of another Number. */
        public Number.copy (Number other) {
            this.value = new MPFR.MPFloat (PRECISION);
            this.value.set (other.value, MPFR.Round.N);
        }

        /**
         * Parses {@code s} as a canonical base-10 number (period as decimal
         * separator, optional sign, optional ''e''-style exponent). Returns
         * {@code null} if {@code s} is not a valid MPFR base-10 number.
         *
         * Locale-tolerant input (commas, thousands separators) belongs in
         * the Parser module; this constructor is strict.
         */
        public static Number? from_string (string s) {
            var n = new Number ();
            int r = n.value.set_str (s, 10, MPFR.Round.N);
            if (r != 0) {
                return null;
            }
            return n;
        }

        public Number add (Number other) {
            var r = new Number ();
            r.value.add (this.value, other.value, MPFR.Round.N);
            return r;
        }

        public Number sub (Number other) {
            var r = new Number ();
            r.value.sub (this.value, other.value, MPFR.Round.N);
            return r;
        }

        public Number mul (Number other) {
            var r = new Number ();
            r.value.mul (this.value, other.value, MPFR.Round.N);
            return r;
        }

        public Number div (Number other) {
            var r = new Number ();
            r.value.div (this.value, other.value, MPFR.Round.N);
            return r;
        }

        public Number mod (Number other) {
            var r = new Number ();
            r.value.fmod (this.value, other.value, MPFR.Round.N);
            return r;
        }

        public Number pow (Number other) {
            var r = new Number ();
            r.value.pow (this.value, other.value, MPFR.Round.N);
            return r;
        }

        public Number sqrt () {
            var r = new Number ();
            r.value.sqrt (this.value, MPFR.Round.N);
            return r;
        }

        public Number negate () {
            var r = new Number ();
            r.value.neg (this.value, MPFR.Round.N);
            return r;
        }

        /** Returns {@code 1 / this}. */
        public Number inverse () {
            var r = new Number ();
            r.value.si_div (1, this.value, MPFR.Round.N);
            return r;
        }

        /**
         * Returns {@code other * this / 100}, i.e. "this percent of other".
         * Mirrors GNOME Calculator's `%` semantics.
         */
        public Number percent_of (Number other) {
            var hundred = new Number.from_double (100.0);
            return this.mul (other).div (hundred);
        }

        /** Returns <0, 0, or >0 if this is less than, equal to, or greater. */
        public int compare (Number other) {
            return this.value.cmp (other.value);
        }

        public bool equals (Number other) {
            return this.compare (other) == 0;
        }

        public bool is_zero () { return this.value.zero_p () != 0; }
        public bool is_nan ()  { return this.value.nan_p () != 0; }
        public bool is_inf ()  { return this.value.inf_p () != 0; }

        public int sign () { return this.value.sgn (); }

        /** Lossy conversion to a C double; intended for debugging and tests. */
        public double to_double () {
            return this.value.get_d (MPFR.Round.N);
        }

        /**
         * Canonical base-10 representation with enough digits to round-trip
         * the internal value losslessly. ASCII period as decimal separator;
         * no locale conversion.
         */
        public string to_canonical_string () {
            return format_with_digits (CANONICAL_DIGITS);
        }

        /**
         * Display-rounded representation. ASCII period as decimal separator;
         * locale conversion is the UI layer's responsibility.
         */
        public string to_display_string (int digits = DISPLAY_DIGITS) {
            return format_with_digits (digits);
        }

        private string format_with_digits (int digits) {
            var buf = new char[64];
            int len = this.value.format (digits, buf);
            if (len < 0) {
                return "";
            }
            return (string) buf;
        }
    }
}
