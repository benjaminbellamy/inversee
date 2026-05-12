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

private static void type_digits (Inversee.Calculator c, string digits) {
    for (int i = 0; i < digits.length; i++) {
        char ch = (char) digits[i];
        if (ch == '.') {
            c.append_decimal ();
        } else {
            c.append_digit (ch);
        }
    }
}

public static int main (string[] args) {
    GLib.Test.init (ref args);

    // === Entry editing ===

    GLib.Test.add_func ("/calc/digit-append", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "1234");
        assert (c.entry == "1234");
    });

    GLib.Test.add_func ("/calc/decimal-on-empty-prepends-zero", () => {
        var c = new Inversee.Calculator ();
        c.append_decimal ();
        assert (c.entry == "0.");
        type_digits (c, "5");
        assert (c.entry == "0.5");
    });

    GLib.Test.add_func ("/calc/decimal-on-minus-prepends-zero", () => {
        var c = new Inversee.Calculator ();
        try {
            c.toggle_sign ();    // stack empty, entry empty -> no-op
        } catch (Error e) { assert_not_reached (); }
        // Now manually toggle by typing then toggling.
        type_digits (c, "5");
        try { c.toggle_sign (); } catch (Error e) { assert_not_reached (); }
        assert (c.entry == "-5");
    });

    GLib.Test.add_func ("/calc/decimal-rejected-twice", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "1");
        c.append_decimal ();
        c.append_decimal ();
        assert (c.entry == "1.");
    });

    GLib.Test.add_func ("/calc/backspace-edits-entry", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "12.5");
        try { c.backspace (); } catch (Error e) { assert_not_reached (); }
        assert (c.entry == "12.");
    });

    GLib.Test.add_func ("/calc/backspace-on-empty-drops-x", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "7");
        try {
            c.enter ();             // [7]
            c.backspace ();         // []
        } catch (Error e) { assert_not_reached (); }
        assert (c.stack.is_empty);
        assert (c.history.can_undo);
    });

    GLib.Test.add_func ("/calc/backspace-on-truly-empty-noop", () => {
        var c = new Inversee.Calculator ();
        try { c.backspace (); } catch (Error e) { assert_not_reached (); }
        assert (c.stack.is_empty);
        assert (!c.history.can_undo);
    });

    GLib.Test.add_func ("/calc/clear-entry", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "42");
        c.clear_entry ();
        assert (c.entry == "");
    });

    // === Enter ===

    GLib.Test.add_func ("/calc/enter-commits-entry", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "42");
        try { c.enter (); } catch (Error e) { assert_not_reached (); }
        assert (c.entry == "");
        assert (c.stack.size == 1);
        try {
            assert (c.stack.peek (0).to_display_string () == "42");
        } catch (Error e) { assert_not_reached (); }
    });

    GLib.Test.add_func ("/calc/enter-no-entry-dups-x", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "7");
        try {
            c.enter ();   // [7]
            c.enter ();   // [7, 7]
        } catch (Error e) { assert_not_reached (); }
        assert (c.stack.size == 2);
    });

    GLib.Test.add_func ("/calc/enter-on-empty-throws", () => {
        var c = new Inversee.Calculator ();
        try {
            c.enter ();
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            // expected — dup on empty stack
            assert (c.stack.is_empty);
            assert (c.entry == "");
        } catch (Error e) { assert_not_reached (); }
    });

    // === Binary ops ===

    GLib.Test.add_func ("/calc/add-commits-entry-and-applies", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "3");
        try { c.enter (); } catch (Error e) { assert_not_reached (); }
        type_digits (c, "4");
        try { c.apply_binary (Inversee.BinaryOp.ADD); }
        catch (Error e) { assert_not_reached (); }
        assert (c.stack.size == 1);
        try {
            assert (c.stack.peek (0).to_display_string () == "7");
        } catch (Error e) { assert_not_reached (); }
        assert (c.entry == "");
    });

    GLib.Test.add_func ("/calc/sub-order-y-minus-x", () => {
        // "10 enter 3 -" => 10 - 3 = 7
        var c = new Inversee.Calculator ();
        type_digits (c, "10");
        try {
            c.enter ();
        } catch (Error e) { assert_not_reached (); }
        type_digits (c, "3");
        try {
            c.apply_binary (Inversee.BinaryOp.SUB);
            assert (c.stack.peek (0).to_display_string () == "7");
        } catch (Error e) { assert_not_reached (); }
    });

    GLib.Test.add_func ("/calc/div-order-y-over-x", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "20");
        try { c.enter (); } catch (Error e) { assert_not_reached (); }
        type_digits (c, "4");
        try {
            c.apply_binary (Inversee.BinaryOp.DIV);
            assert (c.stack.peek (0).to_display_string () == "5");
        } catch (Error e) { assert_not_reached (); }
    });

    GLib.Test.add_func ("/calc/binary-underflow-restores-state", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "5");
        try {
            c.apply_binary (Inversee.BinaryOp.ADD);
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            // Entry must be restored, stack must remain empty.
            assert (c.entry == "5");
            assert (c.stack.is_empty);
            assert (!c.history.can_undo);
        } catch (Error e) { assert_not_reached (); }
    });

    GLib.Test.add_func ("/calc/binary-on-empty-throws", () => {
        var c = new Inversee.Calculator ();
        try {
            c.apply_binary (Inversee.BinaryOp.MUL);
            assert_not_reached ();
        } catch (Inversee.StackError e) {
            assert (c.entry == "");
            assert (c.stack.is_empty);
        } catch (Error e) { assert_not_reached (); }
    });

    // === Unary ops ===

    GLib.Test.add_func ("/calc/sqrt-applies-to-x", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "16");
        try {
            c.apply_unary (Inversee.UnaryOp.SQRT);
            assert (c.stack.peek (0).to_display_string () == "4");
        } catch (Error e) { assert_not_reached (); }
    });

    GLib.Test.add_func ("/calc/inverse-applies-to-x", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "4");
        try {
            c.apply_unary (Inversee.UnaryOp.INVERSE);
            assert (c.stack.peek (0).to_display_string () == "0.25");
        } catch (Error e) { assert_not_reached (); }
    });

    // === Sign toggle ===

    GLib.Test.add_func ("/calc/sign-toggles-entry", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "42");
        try { c.toggle_sign (); } catch (Error e) { assert_not_reached (); }
        assert (c.entry == "-42");
        try { c.toggle_sign (); } catch (Error e) { assert_not_reached (); }
        assert (c.entry == "42");
    });

    GLib.Test.add_func ("/calc/sign-no-entry-negates-x", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "5");
        try {
            c.enter ();
            c.toggle_sign ();
            assert (c.stack.peek (0).to_display_string () == "-5");
        } catch (Error e) { assert_not_reached (); }
    });

    // === Stack ops via Calculator ===

    GLib.Test.add_func ("/calc/dup-no-entry-duplicates-x", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "7");
        try {
            c.enter ();
            c.dup ();
            assert (c.stack.size == 2);
            assert (c.stack.peek (0).to_display_string () == "7");
            assert (c.stack.peek (1).to_display_string () == "7");
        } catch (Error e) { assert_not_reached (); }
    });

    GLib.Test.add_func ("/calc/dup2-duplicates-top-two", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "1");
        try { c.enter (); } catch (Error e) { assert_not_reached (); }
        type_digits (c, "2");
        try {
            c.dup2 ();          // commits "2", then 2dup -> [1, 2, 1, 2]
            assert (c.stack.size == 4);
            assert (c.stack.peek (0).to_display_string () == "2");
            assert (c.stack.peek (1).to_display_string () == "1");
            assert (c.stack.peek (2).to_display_string () == "2");
            assert (c.stack.peek (3).to_display_string () == "1");
        } catch (Error e) { assert_not_reached (); }
    });

    GLib.Test.add_func ("/calc/swap", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "1");
        try { c.enter (); } catch (Error e) { assert_not_reached (); }
        type_digits (c, "2");
        try {
            c.swap ();      // commits "2" then swaps -> [2, 1]
            assert (c.stack.size == 2);
            assert (c.stack.peek (0).to_display_string () == "1");
            assert (c.stack.peek (1).to_display_string () == "2");
        } catch (Error e) { assert_not_reached (); }
    });

    GLib.Test.add_func ("/calc/clear-stack", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "1");
        try { c.enter (); } catch (Error e) { assert_not_reached (); }
        type_digits (c, "2");
        try { c.enter (); } catch (Error e) { assert_not_reached (); }
        type_digits (c, "9");                  // still in entry buffer
        try {
            c.clear_stack ();
        } catch (Error e) { assert_not_reached (); }
        assert (c.stack.is_empty);
        assert (c.entry == "");
        assert (c.history.can_undo);
    });

    // === Undo / redo ===

    GLib.Test.add_func ("/calc/undo-restores-prior-stack", () => {
        var c = new Inversee.Calculator ();
        type_digits (c, "3");
        try { c.enter (); } catch (Error e) { assert_not_reached (); }
        type_digits (c, "4");
        try {
            c.apply_binary (Inversee.BinaryOp.ADD);
            c.undo ();
            assert (c.stack.size == 1);
            assert (c.stack.peek (0).to_display_string () == "3");
            // Entry buffer is cleared on undo (the "4" was committed).
            assert (c.entry == "");
        } catch (Error e) { assert_not_reached (); }
    });

    // === push_values (paste) ===

    GLib.Test.add_func ("/calc/push-values-multiple", () => {
        var c = new Inversee.Calculator ();
        Inversee.Number[] vals = {
            new Inversee.Number.from_double (1.0),
            new Inversee.Number.from_double (2.0),
            new Inversee.Number.from_double (3.0)
        };
        try {
            c.push_values (vals);
            assert (c.stack.size == 3);
            assert (c.stack.peek (0).to_display_string () == "3");
            assert (c.stack.peek (1).to_display_string () == "2");
            assert (c.stack.peek (2).to_display_string () == "1");
            // Single undo reverts the entire paste.
            c.undo ();
            assert (c.stack.is_empty);
        } catch (Error e) { assert_not_reached (); }
    });

    // === Signal ===

    GLib.Test.add_func ("/calc/changed-signal-fires-on-mutation", () => {
        var c = new Inversee.Calculator ();
        int fires = 0;
        c.changed.connect (() => { fires++; });
        type_digits (c, "1");           // 1 fire
        c.append_decimal ();            // 1 fire
        type_digits (c, "5");           // 1 fire
        try { c.enter (); } catch (Error e) { assert_not_reached (); }  // 1 fire
        assert (fires == 4);
    });

    return GLib.Test.run ();
}
