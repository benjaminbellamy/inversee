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
     * The in-progress entry buffer, rendered as a right-aligned label
     * sitting between the stack view and the keypad. Displayed in the
     * current locale's decimal-separator form.
     */
    public class EntryView : Gtk.Box {

        private Calculator calc;
        private Gtk.Label label;

        public EntryView (Calculator calc) {
            Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 0);
            this.calc = calc;

            this.label = new Gtk.Label ("");
            this.label.add_css_class ("numeric");
            this.label.add_css_class ("title-1");
            this.label.xalign = 1;
            this.label.hexpand = true;
            this.label.margin_start = 12;
            this.label.margin_end = 12;
            this.label.margin_top = 8;
            this.label.margin_bottom = 8;
            this.label.ellipsize = Pango.EllipsizeMode.START;

            this.append (this.label);

            this.calc.changed.connect (this.refresh);
            this.refresh ();
        }

        private void refresh () {
            if (this.calc.entry.length == 0) {
                this.label.label = "";
                return;
            }
            this.label.label = Localize.format_number (this.calc.entry);
        }
    }
}
