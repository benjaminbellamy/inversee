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

    // Sets BOTH the hover tooltip and the AT-SPI accessible name on a
    // glyph-only widget. tooltip_text alone reaches sighted users only;
    // the accessible-LABEL property is what screen readers announce.
    internal void describe (Gtk.Widget w, string description) {
        w.tooltip_text = description;
        w.update_property (Gtk.AccessibleProperty.LABEL,
                           description, -1);
    }
}
