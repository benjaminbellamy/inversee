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

public static int main (string[] args) {
    // Tell GIO about the build-tree schemas dir so an uninstalled run
    // from the build directory can find our compiled GSettings schema.
    // overwrite:false lets a deliberately-set env var (e.g. Flatpak)
    // win.
    GLib.Environment.set_variable (
        "GSETTINGS_SCHEMA_DIR", Inversee.Config.SCHEMAS_DIR, false
    );

    // Apply the saved language choice BEFORE setlocale so gettext picks
    // the right catalog on the very first message.
    try {
        var settings = new Settings (Inversee.Config.APP_ID);
        string lang = settings.get_string ("language");
        if (lang != "auto" && lang.length > 0) {
            GLib.Environment.set_variable ("LANGUAGE", lang, true);
        }
    } catch (Error e) {
        // No schema yet (very early dev) — proceed with the system
        // locale rather than refusing to start.
        warning ("could not read language setting: %s", e.message);
    }

    Intl.setlocale (LocaleCategory.ALL, "");

    // Dev convenience: if the build-tree .mo files exist, prefer them
    // over the install-prefix LOCALEDIR. This lets ./build/src/inversee
    // pick up freshly-built translations without `meson install`.
    string locale_dir = Inversee.Config.LOCALEDIR;
    if (FileUtils.test (
            Inversee.Config.BUILD_LOCALEDIR + "/fr/LC_MESSAGES/inversee.mo",
            FileTest.EXISTS)) {
        locale_dir = Inversee.Config.BUILD_LOCALEDIR;
    }
    Intl.bindtextdomain (Inversee.Config.GETTEXT_PACKAGE, locale_dir);
    Intl.bind_textdomain_codeset (
        Inversee.Config.GETTEXT_PACKAGE, "UTF-8"
    );
    Intl.textdomain (Inversee.Config.GETTEXT_PACKAGE);

    GLib.Environment.set_application_name ("Inversée");

    var app = new Inversee.Application ();
    return app.run (args);
}
