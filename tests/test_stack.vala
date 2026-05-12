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

    GLib.Test.add_func ("/stack/empty", () => {
        var s = new Inversee.Stack ();
        assert (s.is_empty);
        assert (s.size == 0);
    });

    GLib.Test.add_func ("/stack/push-and-size", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        s.push (n (2.0));
        assert (!s.is_empty);
        assert (s.size == 2);
    });

    GLib.Test.add_func ("/stack/pop-returns-top", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        s.push (n (2.0));
        try {
            var top = s.pop ();
            assert (top.to_display_string () == "2");
            assert (s.size == 1);
            top = s.pop ();
            assert (top.to_display_string () == "1");
            assert (s.is_empty);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/stack/pop-empty-throws", () => {
        var s = new Inversee.Stack ();
        try {
            s.pop ();
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            assert (e is Inversee.StackError.UNDERFLOW);
            assert (s.is_empty);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/stack/peek-by-index-from-top", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));  // Z (deepest of these)
        s.push (n (2.0));  // Y
        s.push (n (3.0));  // X (top)
        try {
            assert (s.peek (0).to_display_string () == "3");
            assert (s.peek (1).to_display_string () == "2");
            assert (s.peek (2).to_display_string () == "1");
            // Peeking does not mutate.
            assert (s.size == 3);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/stack/peek-out-of-range-throws", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        try {
            s.peek (1);
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            // expected
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/stack/peek-negative-throws", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        try {
            s.peek (-1);
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            // expected
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/stack/dup-duplicates-top", () => {
        var s = new Inversee.Stack ();
        s.push (n (42.0));
        try {
            s.dup ();
            assert (s.size == 2);
            assert (s.peek (0).to_display_string () == "42");
            assert (s.peek (1).to_display_string () == "42");
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/stack/dup-empty-throws", () => {
        var s = new Inversee.Stack ();
        try {
            s.dup ();
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            assert (s.is_empty);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/stack/dup2-duplicates-top-two", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        s.push (n (2.0));
        try {
            s.dup2 ();  // ( 1 2 -- 1 2 1 2 )
            assert (s.size == 4);
            assert (s.peek (0).to_display_string () == "2");
            assert (s.peek (1).to_display_string () == "1");
            assert (s.peek (2).to_display_string () == "2");
            assert (s.peek (3).to_display_string () == "1");
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/stack/dup2-underflow-leaves-stack", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        try {
            s.dup2 ();
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            assert (s.size == 1);
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/stack/swap-exchanges-top-two", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        s.push (n (2.0));
        try {
            s.swap ();
            assert (s.peek (0).to_display_string () == "1");
            assert (s.peek (1).to_display_string () == "2");
            assert (s.size == 2);
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/stack/swap-underflow-leaves-stack", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        try {
            s.swap ();
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            assert (s.size == 1);
            try {
                assert (s.peek (0).to_display_string () == "1");
            } catch (Error e2) {
                assert_not_reached ();
            }
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/stack/drop-removes-top", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        s.push (n (2.0));
        try {
            s.drop ();
            assert (s.size == 1);
            assert (s.peek (0).to_display_string () == "1");
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/stack/drop-empty-throws", () => {
        var s = new Inversee.Stack ();
        try {
            s.drop ();
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            // expected
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/stack/rot-rotates-top-three", () => {
        // Push z=1, y=2, x=3 -> stack bottom-to-top is [1, 2, 3].
        // rot: ( z y x -- y x z ) -> bottom-to-top [2, 3, 1].
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        s.push (n (2.0));
        s.push (n (3.0));
        try {
            s.rot ();
            assert (s.size == 3);
            assert (s.peek (0).to_display_string () == "1");
            assert (s.peek (1).to_display_string () == "3");
            assert (s.peek (2).to_display_string () == "2");
        } catch (Error e) {
            GLib.Test.fail_printf ("unexpected error: %s", e.message);
        }
    });

    GLib.Test.add_func ("/stack/rot-underflow-leaves-stack", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        s.push (n (2.0));
        try {
            s.rot ();
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            assert (s.size == 2);
            try {
                assert (s.peek (0).to_display_string () == "2");
                assert (s.peek (1).to_display_string () == "1");
            } catch (Error e2) {
                assert_not_reached ();
            }
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    GLib.Test.add_func ("/stack/clear-empties", () => {
        var s = new Inversee.Stack ();
        s.push (n (1.0));
        s.push (n (2.0));
        s.push (n (3.0));
        s.clear ();
        assert (s.is_empty);
        assert (s.size == 0);
    });

    GLib.Test.add_func ("/stack/clear-on-empty-noop", () => {
        var s = new Inversee.Stack ();
        s.clear ();
        assert (s.is_empty);
    });

    return GLib.Test.run ();
}
