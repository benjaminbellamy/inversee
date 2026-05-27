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

// Formats are passed explicitly so tests are deterministic and never
// depend on the machine locale.
private static Inversee.NumberFormat auto_us () {
    return Inversee.NumberFormat.from_locale (".", ",", true);
}
private static Inversee.NumberFormat auto_fr () {
    return Inversee.NumberFormat.from_locale (",", "", true);
}

private static void check (string input, Inversee.NumberFormat fmt,
                           string expected) {
    var n = Inversee.Parser.parse_one (input, fmt);
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

private static void check_null (string input, Inversee.NumberFormat fmt) {
    var n = Inversee.Parser.parse_one (input, fmt);
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
    GLib.Test.add_func ("/parser/integer", () => check ("42", auto_us (), "42"));
    GLib.Test.add_func ("/parser/negative",
        () => check ("-3.14", auto_us (), "-3.14"));
    GLib.Test.add_func ("/parser/explicit-positive",
        () => check ("+3.14", auto_us (), "3.14"));
    GLib.Test.add_func ("/parser/zero", () => check ("0", auto_us (), "0"));

    // === Decimal separators ===
    GLib.Test.add_func ("/parser/period-decimal",
        () => check ("1.5", auto_us (), "1.5"));
    GLib.Test.add_func ("/parser/comma-decimal",
        () => check ("1,5", auto_fr (), "1.5"));

    // === Scientific notation ===
    GLib.Test.add_func ("/parser/period-scientific",
        () => check ("1.5e3", auto_us (), "1500"));
    GLib.Test.add_func ("/parser/comma-scientific",
        () => check ("1,5e3", auto_fr (), "1500"));
    GLib.Test.add_func ("/parser/uppercase-E",
        () => check ("2E2", auto_us (), "200"));
    GLib.Test.add_func ("/parser/negative-exponent",
        () => check ("1.5e-2", auto_us (), "0.015"));

    // === Thousands separators ===
    GLib.Test.add_func ("/parser/nbsp-thousands",
        () => check ("1 234,56", auto_fr (), "1234.56"));
    GLib.Test.add_func ("/parser/nnbsp-thousands",
        () => check ("1 234,56", auto_fr (), "1234.56"));
    GLib.Test.add_func ("/parser/ascii-space-thousands",
        () => check ("1 234,56", auto_fr (), "1234.56"));
    GLib.Test.add_func ("/parser/comma-thousands-period-decimal",
        () => check ("1,234.56", auto_us (), "1234.56"));
    GLib.Test.add_func ("/parser/period-thousands-comma-decimal",
        () => check ("1.234,56", auto_us (), "1234.56"));
    GLib.Test.add_func ("/parser/multiple-commas-thousands",
        () => check ("1,234,567", auto_us (), "1234567"));
    GLib.Test.add_func ("/parser/multiple-periods-thousands",
        () => check ("1.234.567", auto_us (), "1234567"));

    // === Whitespace trimming ===
    GLib.Test.add_func ("/parser/leading-whitespace",
        () => check ("  42", auto_us (), "42"));
    GLib.Test.add_func ("/parser/trailing-whitespace",
        () => check ("42  ", auto_us (), "42"));

    // === Currency / unit symbols (ignored) ===
    GLib.Test.add_func ("/parser/euro-suffix",
        () => check ("42 €", auto_us (), "42"));
    GLib.Test.add_func ("/parser/euro-prefix",
        () => check ("€42", auto_us (), "42"));
    GLib.Test.add_func ("/parser/dollar-prefix",
        () => check ("$1,000.5", auto_us (), "1000.5"));
    GLib.Test.add_func ("/parser/pound-prefix",
        () => check ("£50", auto_us (), "50"));
    GLib.Test.add_func ("/parser/euro-nnbsp-thousands",
        () => check ("304 650,00 €", auto_fr (), "304650"));
    GLib.Test.add_func ("/parser/label-prefix",
        () => check ("Total: 1,234.56", auto_us (), "1234.56"));

    // === Leading/trailing non-numerics ignored, interior kept ===
    GLib.Test.add_func ("/parser/trailing-letters-ignored",
        () => check ("1.5xyz", auto_us (), "1.5"));
    GLib.Test.add_func ("/parser/lone-currency-is-null",
        () => check_null ("€", auto_us ()));
    GLib.Test.add_func ("/parser/interior-junk-is-null",
        () => check_null ("12x34", auto_us ()));

    // === parse_one treats every space as grouping (single value) ===
    GLib.Test.add_func ("/parser/one-spaces-are-grouping",
        () => check ("1 2 3", auto_us (), "123"));

    // === Strict presets ===
    GLib.Test.add_func ("/parser/strict-us",
        () => check ("1,234.56", Inversee.NumberFormat.us (), "1234.56"));
    GLib.Test.add_func ("/parser/strict-french",
        () => check ("1.234,56", Inversee.NumberFormat.french (), "1234.56"));
    GLib.Test.add_func ("/parser/strict-european",
        () => check ("1.234,56", Inversee.NumberFormat.european (), "1234.56"));
    GLib.Test.add_func ("/parser/strict-us-comma-is-thousands",
        () => check ("1,5", Inversee.NumberFormat.us (), "15"));
    GLib.Test.add_func ("/parser/strict-french-comma-is-decimal",
        () => check ("1,5", Inversee.NumberFormat.french (), "1.5"));

    // === Invalid / empty input ===
    GLib.Test.add_func ("/parser/empty", () => check_null ("", auto_us ()));
    GLib.Test.add_func ("/parser/whitespace-only",
        () => check_null ("   ", auto_us ()));
    GLib.Test.add_func ("/parser/garbage", () => check_null ("abc", auto_us ()));

    // === parse_multiple ===
    GLib.Test.add_func ("/parser/multi-empty", () => {
        try {
            var arr = Inversee.Parser.parse_multiple ("", auto_us ());
            assert (arr.length == 0);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-semicolon-values", () => {
        try {
            var arr = Inversee.Parser.parse_multiple ("1;2;3", auto_us ());
            assert (arr.length == 3);
            assert (arr[0].to_display_string () == "1");
            assert (arr[1].to_display_string () == "2");
            assert (arr[2].to_display_string () == "3");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-space-singletons-split", () => {
        try {
            // Single digits separated by spaces are NOT a grouped number.
            var arr = Inversee.Parser.parse_multiple ("1 2 3", auto_us ());
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
            // Automatic-French reads both a dot-decimal and a comma-decimal
            // value in the same paste.
            var arr = Inversee.Parser.parse_multiple ("1.5 2,5 3", auto_fr ());
            assert (arr.length == 3);
            assert (arr[0].to_display_string () == "1.5");
            assert (arr[1].to_display_string () == "2.5");
            assert (arr[2].to_display_string () == "3");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-tabs-and-newlines", () => {
        try {
            var arr = Inversee.Parser.parse_multiple ("1\t2\n3", auto_us ());
            assert (arr.length == 3);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-interior-junk-throws", () => {
        try {
            Inversee.Parser.parse_multiple ("12x34", auto_us ());
            assert_not_reached ();
        } catch (Inversee.ParserError e) {
            // expected
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-skips-digitless-tokens", () => {
        try {
            // A digit-free token (label, stray unit) is skipped, not an error.
            var arr = Inversee.Parser.parse_multiple ("1 abc 3", auto_us ());
            assert (arr.length == 2);
            assert (arr[0].to_display_string () == "1");
            assert (arr[1].to_display_string () == "3");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-grouped-thousands", () => {
        try {
            // "304 650,00" is one grouped value; the trailing unit is dropped.
            var arr = Inversee.Parser.parse_multiple (
                "304 650,00 €", auto_fr ());
            assert (arr.length == 1);
            assert (arr[0].to_display_string () == "304650");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-fractional-grouping", () => {
        try {
            // Fractional digits grouped in threes from the left, last
            // group one digit; the trailing unit is dropped.
            var arr = Inversee.Parser.parse_multiple (
                "-1,945 940 6 €", auto_fr ());
            assert (arr.length == 1);
            assert (arr[0].to_display_string () == "-1.9459406");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-fractional-then-value", () => {
        try {
            // A 1-2 digit fractional group ends the number; the next
            // grouped value stands on its own.
            var arr = Inversee.Parser.parse_multiple (
                "1,5 234", auto_fr ());
            assert (arr.length == 2);
            assert (arr[0].to_display_string () == "1.5");
            assert (arr[1].to_display_string () == "234");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-two-grouped-values", () => {
        try {
            // Two grouped values, ASCII space inside each (3-digit groups),
            // separated where a space cannot be grouping.
            var arr = Inversee.Parser.parse_multiple (
                "1 234,56 7 890,12", auto_fr ());
            assert (arr.length == 2);
            assert (arr[0].to_display_string () == "1234.56");
            assert (arr[1].to_display_string () == "7890.12");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-strips-currency", () => {
        try {
            var arr = Inversee.Parser.parse_multiple ("12€ 34$", auto_us ());
            assert (arr.length == 2);
            assert (arr[0].to_display_string () == "12");
            assert (arr[1].to_display_string () == "34");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/parser/multi-skips-lone-currency", () => {
        try {
            var arr = Inversee.Parser.parse_multiple ("12 € 34", auto_us ());
            assert (arr.length == 2);
            assert (arr[0].to_display_string () == "12");
            assert (arr[1].to_display_string () == "34");
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    return GLib.Test.run ();
}
