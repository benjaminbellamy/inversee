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

private static void check (string input, string expected) {
    var n = Inversee.Parser.parse_one (input);
    if (n == null) {
        GLib.Test.fail_printf ("parse_one(\"%s\") returned null", input);
        return;
    }
    if (n.to_display_string () != expected) {
        GLib.Test.fail_printf (
            "parse_one(\"%s\"): expected \"%s\", got \"%s\"",
            input, expected, n.to_display_string ()
        );
    }
}

private static void check_null (string input) {
    var n = Inversee.Parser.parse_one (input);
    if (n != null) {
        GLib.Test.fail_printf (
            "parse_one(\"%s\") expected null, got \"%s\"",
            input, n.to_display_string ()
        );
    }
}

public static int main (string[] args) {
    GLib.Test.init (ref args);

    // === Plain numbers ===
    GLib.Test.add_func ("/parser/integer", () => check ("42", "42"));
    GLib.Test.add_func ("/parser/negative", () => check ("-3.14", "-3.14"));
    GLib.Test.add_func ("/parser/explicit-positive", () => check ("+3.14", "3.14"));
    GLib.Test.add_func ("/parser/zero", () => check ("0", "0"));

    // === Decimal separators ===
    GLib.Test.add_func ("/parser/period-decimal", () => check ("1.5", "1.5"));
    GLib.Test.add_func ("/parser/comma-decimal", () => check ("1,5", "1.5"));

    // === Scientific notation ===
    GLib.Test.add_func ("/parser/period-scientific", () => check ("1.5e3", "1500"));
    GLib.Test.add_func ("/parser/comma-scientific", () => check ("1,5e3", "1500"));
    GLib.Test.add_func ("/parser/uppercase-E", () => check ("2E2", "200"));
    GLib.Test.add_func ("/parser/negative-exponent", () => check ("1.5e-2", "0.015"));

    // === Thousands separators ===
    GLib.Test.add_func ("/parser/nbsp-thousands",
        () => check ("1 234,56", "1234.56"));
    GLib.Test.add_func ("/parser/nnbsp-thousands",
        () => check ("1 234,56", "1234.56"));
    GLib.Test.add_func ("/parser/comma-thousands-period-decimal",
        () => check ("1,234.56", "1234.56"));
    GLib.Test.add_func ("/parser/period-thousands-comma-decimal",
        () => check ("1.234,56", "1234.56"));
    GLib.Test.add_func ("/parser/multiple-commas-thousands",
        () => check ("1,234,567", "1234567"));
    GLib.Test.add_func ("/parser/multiple-periods-thousands",
        () => check ("1.234.567", "1234567"));

    // === Whitespace trimming ===
    GLib.Test.add_func ("/parser/leading-whitespace",
        () => check ("  42", "42"));
    GLib.Test.add_func ("/parser/trailing-whitespace",
        () => check ("42  ", "42"));

    // === Invalid / empty input ===
    GLib.Test.add_func ("/parser/empty", () => check_null (""));
    GLib.Test.add_func ("/parser/whitespace-only", () => check_null ("   "));
    GLib.Test.add_func ("/parser/garbage", () => check_null ("abc"));
    GLib.Test.add_func ("/parser/trailing-garbage", () => check_null ("1.5xyz"));

    // === parse_multiple ===
    GLib.Test.add_func ("/parser/multi-empty", () => {
        try {
            var arr = Inversee.Parser.parse_multiple ("");
            assert (arr.length == 0);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-three-values", () => {
        try {
            var arr = Inversee.Parser.parse_multiple ("1 2 3");
            assert (arr.length == 3);
            assert (arr[0].to_display_string () == "1");
            assert (arr[1].to_display_string () == "2");
            assert (arr[2].to_display_string () == "3");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-mixed-locales", () => {
        try {
            var arr = Inversee.Parser.parse_multiple ("1.5 2,5 3");
            assert (arr.length == 3);
            assert (arr[0].to_display_string () == "1.5");
            assert (arr[1].to_display_string () == "2.5");
            assert (arr[2].to_display_string () == "3");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-extra-whitespace", () => {
        try {
            var arr = Inversee.Parser.parse_multiple ("  1\t2\n3  ");
            assert (arr.length == 3);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-invalid-throws", () => {
        try {
            Inversee.Parser.parse_multiple ("1 abc 3");
            assert_not_reached ();
        } catch (Inversee.ParserError e) {
            // expected
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-tolerates-nbsp-thousands", () => {
        try {
            // Two values, each with NBSP thousands separator.
            var arr = Inversee.Parser.parse_multiple ("1 234,56 7 890,12");
            assert (arr.length == 2);
            assert (arr[0].to_display_string () == "1234.56");
            assert (arr[1].to_display_string () == "7890.12");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    return GLib.Test.run ();
}
