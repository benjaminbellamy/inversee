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

private static Inversee.Number n (double d) {
    return new Inversee.Number.from_double (d);
}

public static int main (string[] args) {
    GLib.Test.init (ref args);

    GLib.Test.add_func ("/persistence/round-trip-empty", () => {
        var s1 = new Inversee.Stack ();
        var h1 = new Inversee.History (s1);
        string json = Inversee.Persistence.serialize (s1, h1);

        var s2 = new Inversee.Stack ();
        var h2 = new Inversee.History (s2);
        try {
            Inversee.Persistence.deserialize (json, s2, h2);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
            return;
        }
        assert (s2.is_empty);
        assert (!h2.can_undo);
    });

    GLib.Test.add_func ("/persistence/round-trip-stack-only", () => {
        var s1 = new Inversee.Stack ();
        s1.push (n (3.14));
        s1.push (n (-2.5));
        s1.push (Inversee.Number.from_string ("1.234567890123456789"));
        var h1 = new Inversee.History (s1);

        string json = Inversee.Persistence.serialize (s1, h1);

        var s2 = new Inversee.Stack ();
        var h2 = new Inversee.History (s2);
        try {
            Inversee.Persistence.deserialize (json, s2, h2);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
            return;
        }
        assert (s2.size == 3);
        try {
            assert (s2.peek (0).equals (s1.peek (0)));
            assert (s2.peek (1).equals (s1.peek (1)));
            assert (s2.peek (2).equals (s1.peek (2)));
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/persistence/round-trip-with-history", () => {
        var s1 = new Inversee.Stack ();
        var h1 = new Inversee.History (s1);
        try {
            h1.commit (() => { s1.push (n (1.0)); });
            h1.commit (() => { s1.push (n (2.0)); });
            h1.commit (() => { s1.push (n (3.0)); });
            h1.undo ();
        } catch (Error e) {
            assert_not_reached ();
        }

        string json = Inversee.Persistence.serialize (s1, h1);

        var s2 = new Inversee.Stack ();
        var h2 = new Inversee.History (s2);
        try {
            Inversee.Persistence.deserialize (json, s2, h2);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
            return;
        }
        assert (s2.size == s1.size);
        assert (h2.undo_depth == h1.undo_depth);
        // Undoing once more on the deserialized state should still
        // work — proves the undo queue round-tripped.
        try {
            h2.undo ();
            assert (s2.size == 1);
            assert (s2.peek (0).to_display_string () == "1");
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/persistence/double-round-trip-byte-stable", () => {
        // serialize(deserialize(serialize(X))) == serialize(X) on the
        // JSON string level — guards against ordering drift in the
        // generator.
        var s1 = new Inversee.Stack ();
        s1.push (n (1.5));
        s1.push (n (2.5));
        var h1 = new Inversee.History (s1);
        try {
            h1.commit (() => { s1.push (n (3.5)); });
        } catch (Error e) {
            assert_not_reached ();
        }

        string j1 = Inversee.Persistence.serialize (s1, h1);

        var s2 = new Inversee.Stack ();
        var h2 = new Inversee.History (s2);
        try {
            Inversee.Persistence.deserialize (j1, s2, h2);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
            return;
        }

        string j2 = Inversee.Persistence.serialize (s2, h2);
        assert (j1 == j2);
    });

    GLib.Test.add_func ("/persistence/invalid-json-throws", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        try {
            Inversee.Persistence.deserialize ("not json {{{", s, h);
            assert_not_reached ();
        } catch (Inversee.PersistenceError e) {
            assert (e is Inversee.PersistenceError.INVALID_JSON);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/persistence/wrong-version-throws", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        string bad = "{\"version\":99,\"stack\":[],\"undo\":[],\"redo\":[]}";
        try {
            Inversee.Persistence.deserialize (bad, s, h);
            assert_not_reached ();
        } catch (Inversee.PersistenceError e) {
            assert (e is Inversee.PersistenceError.UNSUPPORTED_VERSION);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/persistence/missing-stack-throws", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        string bad = "{\"version\":1,\"undo\":[],\"redo\":[]}";
        try {
            Inversee.Persistence.deserialize (bad, s, h);
            assert_not_reached ();
        } catch (Inversee.PersistenceError e) {
            assert (e is Inversee.PersistenceError.MALFORMED_VALUE);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/persistence/bad-number-string-throws", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        string bad =
            "{\"version\":1,\"stack\":[\"not-a-number\"],\"undo\":[],\"redo\":[]}";
        try {
            Inversee.Persistence.deserialize (bad, s, h);
            assert_not_reached ();
        } catch (Inversee.PersistenceError e) {
            assert (e is Inversee.PersistenceError.MALFORMED_VALUE);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/persistence/extreme-precision-round-trip", () => {
        // 38-digit value at the edge of 128-bit precision.
        var s1 = new Inversee.Stack ();
        var orig = Inversee.Number.from_string ("3.141592653589793238462643383279502884");
        assert (orig != null);
        s1.push (orig);
        var h1 = new Inversee.History (s1);

        string json = Inversee.Persistence.serialize (s1, h1);

        var s2 = new Inversee.Stack ();
        var h2 = new Inversee.History (s2);
        try {
            Inversee.Persistence.deserialize (json, s2, h2);
            assert (s2.peek (0).equals (orig));
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    return GLib.Test.run ();
}
