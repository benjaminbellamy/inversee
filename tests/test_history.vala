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

    GLib.Test.add_func ("/history/initial-state", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        assert (!h.can_undo);
        assert (h.undo_depth == 0);
    });

    GLib.Test.add_func ("/history/commit-makes-it-undoable", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        try {
            h.commit (() => { s.push (n (42.0)); });
            assert (s.size == 1);
            assert (h.can_undo);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/history/undo-restores-stack", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        try {
            h.commit (() => { s.push (n (42.0)); });
            h.undo ();
            assert (s.size == 0);
            assert (!h.can_undo);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/history/error-restores-stack-no-entry", () => {
        var s = new Inversee.Stack ();
        s.push (n (7.0));
        var h = new Inversee.History (s);

        try {
            h.commit (() => {
                s.pop ();          // OK
                s.pop ();          // UNDERFLOW
            });
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            assert (s.size == 1);
            try {
                assert (s.peek (0).to_display_string () == "7");
            } catch (Error inner) {
                assert_not_reached ();
            }
            assert (!h.can_undo);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/history/cap-at-max-entries", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        try {
            for (int i = 0; i < Inversee.History.MAX_ENTRIES + 5; i++) {
                int v = i;
                h.commit (() => { s.push (n ((double) v)); });
            }
            assert (h.undo_depth == Inversee.History.MAX_ENTRIES);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/history/undo-on-empty-throws", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        try {
            h.undo ();
            assert_not_reached ();
        } catch (Inversee.HistoryError e) {
            // expected
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/history/round-trip-all-stack-ops", () => {
        var s = new Inversee.Stack ();
        var h = new Inversee.History (s);
        try {
            h.commit (() => { s.push (n (1.0)); });
            h.commit (() => { s.push (n (2.0)); });
            h.commit (() => { s.push (n (3.0)); });
            h.commit (() => { s.swap (); });       // [1, 3, 2] top=2
            assert (s.peek (0).to_display_string () == "2");

            h.commit (() => { s.drop (); });       // [1, 3]
            assert (s.size == 2);
            assert (s.peek (0).to_display_string () == "3");

            h.commit (() => { s.clear (); });
            assert (s.is_empty);

            // Undo back to start.
            h.undo ();  // un-clear: [1, 3]
            assert (s.size == 2);
            assert (s.peek (0).to_display_string () == "3");

            h.undo ();  // un-drop: [1, 3, 2]
            assert (s.size == 3);
            assert (s.peek (0).to_display_string () == "2");

            h.undo ();  // un-swap: [1, 2, 3]
            assert (s.peek (0).to_display_string () == "3");

            h.undo ();  // un-push 3
            assert (s.size == 2);
            h.undo ();  // un-push 2
            h.undo ();  // un-push 1
            assert (s.is_empty);
            assert (!h.can_undo);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    return GLib.Test.run ();
}
