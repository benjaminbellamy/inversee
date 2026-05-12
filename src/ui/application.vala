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
    public class Application : Adw.Application {
        public Application() {
            Object(
                application_id: Config.APP_ID,
                flags: ApplicationFlags.DEFAULT_FLAGS,
                resource_base_path: "/fr/benjaminbellamy/Inversee"
            );
        }

        protected override void startup () {
            base.startup ();

            // Make the source-tree icon discoverable so the app icon
            // (and About logo) resolve when running uninstalled from
            // the build directory. Installed builds and Flatpak already
            // have the icon on the standard hicolor path; adding this
            // extra search path is a no-op there.
            var display = Gdk.Display.get_default ();
            if (display != null) {
                var icon_theme = Gtk.IconTheme.get_for_display (display);
                icon_theme.add_search_path (Config.SOURCE_ICONS_DIR);
            }
        }

        protected override void activate() {
            var window = this.active_window;
            if (window == null) {
                window = new Window(this);
            }
            window.present();
        }
    }
}
