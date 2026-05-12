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
     *
     * Also surfaces error messages from {@link show_error}: the label
     * stays the same size, weight, and position — only the colour
     * changes via the {@code error} style class — and the message
     * auto-clears after {@link ERROR_TIMEOUT_S} seconds or on the
     * next successful calculator action.
     */
    public class EntryView : Gtk.Box {

        private const uint ERROR_TIMEOUT_S = 10;

        private Calculator calc;
        private Gtk.Label label;
        private string? error_message = null;
        private uint clear_timeout_id = 0;

        public EntryView (Calculator calc) {
            Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 0);
            this.calc = calc;

            this.label = new Gtk.Label ("");
            // Same font, weight, alignment, and ellipsization in both
            // entry and error states — only the colour changes, so
            // nothing jumps when an error appears or disappears.
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

            this.calc.changed.connect (this.on_calc_changed);
            this.refresh ();
        }

        /**
         * Display {@code message} in place of the entry. The message
         * stays visible until the next successful calculator action
         * or until {@link ERROR_TIMEOUT_S} seconds elapse, whichever
         * comes first.
         */
        public void show_error (string message) {
            this.error_message = message;
            this.label.label = message;
            this.label.tooltip_text = message;
            this.label.add_css_class ("error");

            if (this.clear_timeout_id != 0) {
                Source.remove (this.clear_timeout_id);
            }
            this.clear_timeout_id = Timeout.add_seconds (
                ERROR_TIMEOUT_S,
                () => {
                    this.clear_timeout_id = 0;
                    this.clear_error ();
                    return Source.REMOVE;
                }
            );
        }

        private void clear_error () {
            if (this.error_message == null) {
                return;
            }
            this.error_message = null;
            this.label.remove_css_class ("error");
            this.label.tooltip_text = null;
            this.refresh ();
        }

        private void on_calc_changed () {
            if (this.error_message != null) {
                if (this.clear_timeout_id != 0) {
                    Source.remove (this.clear_timeout_id);
                    this.clear_timeout_id = 0;
                }
                this.clear_error ();
                return;
            }
            this.refresh ();
        }

        private void refresh () {
            if (this.calc.entry.length == 0) {
                this.label.label = "";
            } else {
                this.label.label = Localize.format_number (this.calc.entry);
            }
        }
    }
}
