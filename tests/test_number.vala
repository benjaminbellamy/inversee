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

public static int main (string[] args) {
    GLib.Test.init (ref args);

    GLib.Test.add_func ("/number/zero", () => {
        var n = new Inversee.Number ();
        assert (n.is_zero ());
        assert (n.to_display_string () == "0");
    });

    GLib.Test.add_func ("/number/from-double", () => {
        var n = new Inversee.Number.from_double (3.14);
        assert (n.to_display_string () == "3.14");
    });

    GLib.Test.add_func ("/number/from-string-valid", () => {
        var n = Inversee.Number.from_string ("1.5");
        assert (n != null);
        assert (n.to_display_string () == "1.5");
    });

    GLib.Test.add_func ("/number/from-string-invalid", () => {
        var n = Inversee.Number.from_string ("not a number");
        assert (n == null);
    });

    GLib.Test.add_func ("/number/from-string-negative", () => {
        var n = Inversee.Number.from_string ("-42");
        assert (n != null);
        assert (n.to_display_string () == "-42");
    });

    GLib.Test.add_func ("/number/from-string-scientific", () => {
        var n = Inversee.Number.from_string ("1.5e3");
        assert (n != null);
        assert (n.to_display_string () == "1500");
    });

    GLib.Test.add_func ("/number/decimal-precision-0.1+0.2", () => {
        var a = Inversee.Number.from_string ("0.1");
        var b = Inversee.Number.from_string ("0.2");
        assert (a != null && b != null);
        var sum = a.add (b);
        assert (sum.to_display_string () == "0.3");
    });

    GLib.Test.add_func ("/number/add-sub-mul-div", () => {
        var a = new Inversee.Number.from_double (6.0);
        var b = new Inversee.Number.from_double (2.0);
        assert (a.add (b).to_display_string () == "8");
        assert (a.sub (b).to_display_string () == "4");
        assert (a.mul (b).to_display_string () == "12");
        assert (a.div (b).to_display_string () == "3");
    });

    GLib.Test.add_func ("/number/sqrt", () => {
        var two = new Inversee.Number.from_double (2.0);
        var r = two.sqrt ();
        assert (r.to_display_string () == "1.41421356237");
    });

    GLib.Test.add_func ("/number/pow", () => {
        var two = new Inversee.Number.from_double (2.0);
        var ten = new Inversee.Number.from_double (10.0);
        assert (two.pow (ten).to_display_string () == "1024");
    });

    GLib.Test.add_func ("/number/mod", () => {
        var a = new Inversee.Number.from_double (17.0);
        var b = new Inversee.Number.from_double (5.0);
        assert (a.mod (b).to_display_string () == "2");
    });

    GLib.Test.add_func ("/number/negate", () => {
        var a = new Inversee.Number.from_double (3.0);
        assert (a.negate ().to_display_string () == "-3");
    });

    GLib.Test.add_func ("/number/inverse", () => {
        var a = new Inversee.Number.from_double (4.0);
        assert (a.inverse ().to_display_string () == "0.25");
    });

    GLib.Test.add_func ("/number/percent-of", () => {
        // "20% of 50" => 10
        var twenty = new Inversee.Number.from_double (20.0);
        var fifty = new Inversee.Number.from_double (50.0);
        assert (twenty.percent_of (fifty).to_display_string () == "10");
    });

    GLib.Test.add_func ("/number/div-by-zero", () => {
        var a = new Inversee.Number.from_double (1.0);
        var zero = new Inversee.Number ();
        var r = a.div (zero);
        assert (r.is_inf ());
    });

    GLib.Test.add_func ("/number/sqrt-of-negative-is-nan", () => {
        var neg = new Inversee.Number.from_double (-1.0);
        var r = neg.sqrt ();
        assert (r.is_nan ());
    });

    GLib.Test.add_func ("/number/canonical-roundtrip", () => {
        var orig = Inversee.Number.from_string ("3.141592653589793238462643");
        assert (orig != null);
        var canonical = orig.to_canonical_string ();
        var roundtrip = Inversee.Number.from_string (canonical);
        assert (roundtrip != null);
        assert (orig.equals (roundtrip));
    });

    GLib.Test.add_func ("/number/compare", () => {
        var a = new Inversee.Number.from_double (1.0);
        var b = new Inversee.Number.from_double (2.0);
        assert (a.compare (b) < 0);
        assert (b.compare (a) > 0);
        assert (a.compare (a) == 0);
    });

    GLib.Test.add_func ("/number/copy-is-independent", () => {
        var orig = new Inversee.Number.from_double (7.0);
        var clone = new Inversee.Number.copy (orig);
        assert (orig.equals (clone));
        // Mutating the result of an op on the clone must not touch orig.
        var two = new Inversee.Number.from_double (2.0);
        var doubled = clone.mul (two);
        assert (doubled.to_display_string () == "14");
        assert (orig.to_display_string () == "7");
        assert (clone.to_display_string () == "7");
    });

    return GLib.Test.run ();
}
