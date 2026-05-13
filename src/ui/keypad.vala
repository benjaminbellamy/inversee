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
     * On-screen keypad. All RPN operations are visible at once.
     *
     * Undo and clipboard ops live on the header bar; the keypad covers
     * entry, stack manipulation, and arithmetic. The Enter button sits
     * at the bottom-right and spans two rows, drawn in the accent
     * colour. Backspace and Clear are stacked above it in the same
     * column.
     */
    public class Keypad : Gtk.Grid {

        public delegate void KeypadAction () throws Error;

        private Calculator calc;

        public signal void error_occurred (string message);

        public Keypad (Calculator calc) {
            Object (
                row_spacing: 6,
                column_spacing: 6,
                row_homogeneous: true,
                column_homogeneous: true
            );
            this.calc = calc;

            this.margin_start = 12;
            this.margin_end = 12;
            this.margin_top = 8;
            this.margin_bottom = 12;

            this.build_ui ();
        }

        private void build_ui () {
            // Row 0: stack ops, uppercase, flat (no chrome) for a
            // lighter visual weight than the chunky digit/math buttons.
            this.add_stackop_button (_("SWAP"), 0, 0,
                () => this.calc.swap ());
            this.add_stackop_button (_("ROT"),  1, 0,
                () => this.calc.rot ());
            this.add_stackop_button (_("DUP"),  2, 0,
                () => this.calc.dup ());
            this.add_stackop_button (_("DUP2"), 3, 0,
                () => this.calc.dup2 ());
            this.add_stackop_button (_("DROP"), 4, 0,
                () => this.calc.drop ());

            // Row 1: math functions. Clear takes the rightmost slot
            // that the removed `%` button used to occupy.
            this.add_action_button ("√",   0, 1, 1, 1, {},
                () => this.calc.apply_unary (UnaryOp.SQRT),
                _("Square root"));
            this.add_action_button ("1/x", 1, 1, 1, 1, {},
                () => this.calc.apply_unary (UnaryOp.INVERSE),
                _("Inverse"));
            this.add_action_button ("x^y", 2, 1, 1, 1, {},
                () => this.calc.apply_binary (BinaryOp.POW),
                _("Power"));
            this.add_action_button (_("mod"), 3, 1, 1, 1, {},
                () => this.calc.apply_binary (BinaryOp.MOD),
                _("Modulo"));
            this.add_action_button ("⌫", 4, 1, 1, 1, {},
                () => this.calc.backspace (),
                _("Backspace"));

            // Rows 2-5 cols 0-3: digit pad + ÷ × − +.
            this.add_digit_button (7, 0, 2);
            this.add_digit_button (8, 1, 2);
            this.add_digit_button (9, 2, 2);
            this.add_action_button ("÷", 3, 2, 1, 1, { "numeric" },
                () => this.calc.apply_binary (BinaryOp.DIV),
                _("Divide"));

            this.add_digit_button (4, 0, 3);
            this.add_digit_button (5, 1, 3);
            this.add_digit_button (6, 2, 3);
            this.add_action_button ("×", 3, 3, 1, 1, { "numeric" },
                () => this.calc.apply_binary (BinaryOp.MUL),
                _("Multiply"));

            this.add_digit_button (1, 0, 4);
            this.add_digit_button (2, 1, 4);
            this.add_digit_button (3, 2, 4);
            this.add_action_button ("−", 3, 4, 1, 1, { "numeric" },
                () => this.calc.apply_binary (BinaryOp.SUB),
                _("Subtract"));

            this.add_digit_button (0, 0, 5);
            var decimal_b = this.make_button (Localize.decimal_separator (),
                                              { "numeric" });
            describe (decimal_b, _("Decimal separator"));
            decimal_b.clicked.connect (() => this.calc.append_decimal ());
            this.attach (decimal_b, 1, 5, 1, 1);
            this.add_action_button ("+/−", 2, 5, 1, 1, {},
                () => this.calc.toggle_sign (),
                _("Toggle sign"));
            this.add_action_button ("+", 3, 5, 1, 1, { "numeric" },
                () => this.calc.apply_binary (BinaryOp.ADD),
                _("Add"));

            // Col 4: Clear (row 2), Enter (rows 3-5, tall accent).
            this.add_action_button (_("Clear"), 4, 2, 1, 1,
                                    { "destructive-action" },
                () => this.calc.clear_stack ());

            var enter_b = this.make_button (_("Enter"),
                                            { "suggested-action" });
            enter_b.clicked.connect (() => {
                try {
                    this.calc.enter ();
                } catch (Error e) {
                    this.error_occurred (e.message);
                }
            });
            this.attach (enter_b, 4, 3, 1, 3);
        }

        private void add_digit_button (int digit, int col, int row) {
            var b = this.make_button (digit.to_string (),
                                      { "numeric", "title-2" });
            int captured = digit;
            b.clicked.connect (() => {
                this.calc.append_digit ((char) ('0' + captured));
            });
            this.attach (b, col, row, 1, 1);
        }

        private void add_stackop_button (string label,
                                         int col,
                                         int row,
                                         owned KeypadAction action) {
            var b = this.make_button (label, { "flat", "caption-heading" });
            b.clicked.connect (() => {
                try {
                    action ();
                } catch (Error e) {
                    this.error_occurred (e.message);
                }
            });
            this.attach (b, col, row, 1, 1);
        }

        private void add_action_button (string label,
                                        int col,
                                        int row,
                                        int width,
                                        int height,
                                        string[] css_classes,
                                        owned KeypadAction action,
                                        string? description = null) {
            var b = this.make_button (label, css_classes);
            if (description != null) {
                describe (b, description);
            }
            b.clicked.connect (() => {
                try {
                    action ();
                } catch (Error e) {
                    this.error_occurred (e.message);
                }
            });
            this.attach (b, col, row, width, height);
        }

        private Gtk.Button make_button (string label, string[] css_classes) {
            var b = new Gtk.Button.with_label (label);
            b.hexpand = true;
            b.vexpand = true;
            foreach (unowned string c in css_classes) {
                b.add_css_class (c);
            }
            return b;
        }

        // Sets BOTH the hover tooltip and the AT-SPI accessible name on a
        // glyph-only button. tooltip_text alone reaches sighted users only;
        // the accessible-LABEL property is what screen readers announce.
        private static void describe (Gtk.Widget w, string description) {
            w.tooltip_text = description;
            w.update_property (Gtk.AccessibleProperty.LABEL,
                               description, -1);
        }
    }
}
