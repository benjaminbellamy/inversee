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
     * Visual representation of a {@link Calculator}'s stack. The bottom
     * of the visible list is the top of the stack (X register). Each
     * row is left-labeled with its index from the top — "1:" for X,
     * "2:" for Y, etc., de-emphasized via the {@code dim-label} class.
     *
     * Activating a row emits {@link copy_requested} with the row's
     * value in canonical form; the window handles clipboard interaction.
     */
    public class StackView : Gtk.Box {

        private Calculator calc;
        private Gtk.Stack inner_stack;
        private Gtk.ListBox list_box;
        private Gtk.ScrolledWindow scrolled;

        /**
         * Emitted when the user activates a stack row. The argument is
         * the row's display string (ASCII period decimal, 12 sig figs
         * trimmed). The window converts to locale form on copy.
         */
        public signal void copy_requested (string display_value);

        public StackView (Calculator calc) {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            this.calc = calc;

            this.list_box = new Gtk.ListBox ();
            this.list_box.selection_mode = Gtk.SelectionMode.NONE;
            this.list_box.row_activated.connect (this.on_row_activated);

            this.scrolled = new Gtk.ScrolledWindow ();
            this.scrolled.hexpand = true;
            this.scrolled.vexpand = true;
            this.scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
            this.scrolled.set_child (this.list_box);

            var empty_label = new Gtk.Label (_("Stack empty"));
            empty_label.add_css_class ("dim-label");
            empty_label.valign = Gtk.Align.CENTER;
            empty_label.halign = Gtk.Align.CENTER;

            this.inner_stack = new Gtk.Stack ();
            this.inner_stack.hexpand = true;
            this.inner_stack.vexpand = true;
            this.inner_stack.add_named (empty_label, "empty");
            this.inner_stack.add_named (this.scrolled, "populated");

            this.append (this.inner_stack);

            this.calc.changed.connect (this.refresh);
            this.refresh ();
        }

        private void refresh () {
            Gtk.Widget? child = this.list_box.get_first_child ();
            while (child != null) {
                Gtk.Widget? next = child.get_next_sibling ();
                this.list_box.remove (child);
                child = next;
            }

            int size = this.calc.stack.size;
            if (size == 0) {
                this.inner_stack.set_visible_child_name ("empty");
                return;
            }
            this.inner_stack.set_visible_child_name ("populated");

            // Deepest first, X last — UI shows X at the bottom of the
            // visible list per the spec.
            for (int i = size - 1; i >= 0; i--) {
                try {
                    var value = this.calc.stack.peek (i);
                    string display = value.to_display_string ();
                    var row = this.make_row (i + 1, display);
                    this.list_box.append (row);
                } catch (Error e) {
                    // unreachable: size was just read
                }
            }

            // Scroll to bottom (X register) after layout.
            Idle.add (() => {
                var adj = this.scrolled.vadjustment;
                adj.value = adj.upper - adj.page_size;
                return false;
            });
        }

        private Gtk.ListBoxRow make_row (int index_from_top,
                                         string display) {
            var row = new Gtk.ListBoxRow ();
            row.activatable = true;
            row.set_data<string> ("display", display);

            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            hbox.margin_start = 12;
            hbox.margin_end = 12;
            hbox.margin_top = 6;
            hbox.margin_bottom = 6;

            var idx = new Gtk.Label ("%d:".printf (index_from_top));
            idx.add_css_class ("dim-label");
            idx.add_css_class ("numeric");
            idx.xalign = 0;
            idx.width_chars = 3;

            var val = new Gtk.Label (Localize.format_number (display));
            val.add_css_class ("numeric");
            val.add_css_class ("title-3");
            val.xalign = 1;
            val.hexpand = true;
            val.ellipsize = Pango.EllipsizeMode.START;
            val.selectable = false;

            hbox.append (idx);
            hbox.append (val);
            row.set_child (hbox);
            return row;
        }

        private void on_row_activated (Gtk.ListBoxRow row) {
            string? display = row.get_data<string> ("display");
            if (display != null) {
                this.copy_requested (display);
            }
        }
    }
}
