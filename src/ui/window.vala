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

    public class Window : Adw.ApplicationWindow {

        private Calculator calc;
        private Settings settings;
        private SessionStore session_store;
        private Adw.ToastOverlay toast_overlay;
        private StackView stack_view;
        private EntryView entry_view;
        private Keypad keypad;

        public Window (Adw.Application app) {
            Object (application: app);

            set_title (_("Inversée"));

            this.calc = new Calculator ();
            this.settings = new Settings (Config.APP_ID);

            // Two-way bind the window geometry to GSettings — initial
            // values are pulled from the schema, and any resize /
            // maximize change is written back automatically.
            this.settings.bind ("window-width",     this,
                                "default-width",    SettingsBindFlags.DEFAULT);
            this.settings.bind ("window-height",    this,
                                "default-height",   SettingsBindFlags.DEFAULT);
            this.settings.bind ("window-maximized", this,
                                "maximized",        SettingsBindFlags.DEFAULT);

            // Restore the previous session BEFORE constructing the
            // views so their initial refresh sees the loaded stack.
            this.session_store = new SessionStore (this.calc);
            this.session_store.load ();

            // Flush any pending save synchronously on close so a
            // change made in the last 500 ms isn't lost.
            this.close_request.connect (() => {
                this.session_store.flush ();
                return false;
            });

            this.install_actions ();

            var header = this.build_header_bar ();

            this.stack_view = new StackView (this.calc);
            this.entry_view = new EntryView (this.calc);
            this.keypad     = new Keypad (this.calc);

            this.stack_view.copy_requested.connect (this.on_copy_value);
            this.keypad.error_occurred.connect (this.show_error);

            var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            content.append (header);
            content.append (this.stack_view);
            content.append (this.entry_view);
            content.append (sep);
            content.append (this.keypad);

            this.toast_overlay = new Adw.ToastOverlay ();
            this.toast_overlay.set_child (content);

            set_content (this.toast_overlay);

            this.install_keyboard_shortcuts ();
        }

        // === Header bar ===

        private Adw.HeaderBar build_header_bar () {
            var header = new Adw.HeaderBar ();

            var undo_b = new Gtk.Button.from_icon_name ("edit-undo-symbolic");
            undo_b.tooltip_text = _("Undo (Ctrl+Z)");
            undo_b.clicked.connect (
                () => this.run_op (() => this.calc.undo ())
            );
            header.pack_start (undo_b);

            var clipboard_button = new Gtk.MenuButton ();
            clipboard_button.icon_name = "edit-copy-symbolic";
            clipboard_button.tooltip_text = _("Clipboard");
            clipboard_button.menu_model = this.build_clipboard_menu ();
            header.pack_start (clipboard_button);

            var menu_button = new Gtk.MenuButton ();
            menu_button.icon_name = "open-menu-symbolic";
            menu_button.tooltip_text = _("Main Menu");
            menu_button.menu_model = this.build_menu_model ();
            header.pack_end (menu_button);

            return header;
        }

        private GLib.MenuModel build_clipboard_menu () {
            var menu = new GLib.Menu ();
            menu.append (_("Paste"),      "win.paste");
            menu.append (_("Copy"),       "win.copy_x");
            menu.append (_("Copy stack"), "win.copy_stack");
            return menu;
        }

        private GLib.MenuModel build_menu_model () {
            var lang_menu = new GLib.Menu ();
            lang_menu.append (_("Auto (system)"), "win.language::auto");
            lang_menu.append ("English",          "win.language::en");
            lang_menu.append ("Français",         "win.language::fr");
            lang_menu.append ("Deutsch",          "win.language::de");
            lang_menu.append ("Italiano",         "win.language::it");
            lang_menu.append ("Español",          "win.language::es");
            lang_menu.append ("Polski",           "win.language::pl");

            var section_top = new GLib.Menu ();
            section_top.append_submenu (_("Language"), lang_menu);

            var section_bottom = new GLib.Menu ();
            section_bottom.append (_("Keyboard Shortcuts"), "win.shortcuts");
            section_bottom.append (_("About Inversée"),     "win.about");

            var section_reset = new GLib.Menu ();
            section_reset.append (_("Quit and reset"), "win.reset");

            var menu = new GLib.Menu ();
            menu.append_section (null, section_top);
            menu.append_section (null, section_bottom);
            menu.append_section (null, section_reset);
            return menu;
        }

        // === Actions ===

        private void install_actions () {
            var paste_action = new SimpleAction ("paste", null);
            paste_action.activate.connect (
                () => this.paste_from_clipboard.begin ()
            );
            this.add_action (paste_action);

            var copy_x_action = new SimpleAction ("copy_x", null);
            copy_x_action.activate.connect (this.on_copy_x);
            this.add_action (copy_x_action);

            var copy_stack_action = new SimpleAction ("copy_stack", null);
            copy_stack_action.activate.connect (this.on_copy_stack);
            this.add_action (copy_stack_action);

            var about_action = new SimpleAction ("about", null);
            about_action.activate.connect (this.show_about);
            this.add_action (about_action);

            var shortcuts_action = new SimpleAction ("shortcuts", null);
            shortcuts_action.activate.connect (this.show_shortcuts);
            this.add_action (shortcuts_action);

            var reset_action = new SimpleAction ("reset", null);
            reset_action.activate.connect (this.confirm_reset);
            this.add_action (reset_action);

            string current_lang = this.settings.get_string ("language");
            var language_action = new SimpleAction.stateful (
                "language",
                GLib.VariantType.STRING,
                new Variant.string (current_lang)
            );
            language_action.activate.connect ((param) => {
                if (param == null) return;
                string code = param.get_string ();
                language_action.set_state (param);
                this.settings.set_string ("language", code);
                this.show_info (
                    _("Restart Inversée to apply the language change.")
                );
            });
            this.add_action (language_action);
        }

        private void confirm_reset () {
            var dialog = new Adw.MessageDialog (
                this,
                _("Quit and reset?"),
                _("Inversée will quit. The stack, undo history, saved"
                  + " language, and window size will all be cleared.")
            );
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("reset",  _("Quit and reset"));
            dialog.set_response_appearance (
                "reset", Adw.ResponseAppearance.DESTRUCTIVE
            );
            dialog.set_default_response ("cancel");
            dialog.set_close_response ("cancel");
            dialog.response.connect ((response) => {
                if (response == "reset") {
                    this.perform_reset_and_quit ();
                }
            });
            dialog.present ();
        }

        private void perform_reset_and_quit () {
            // Detach the two-way geometry bindings BEFORE we touch
            // anything — otherwise GTK will happily write the current
            // window size back to GSettings on its way out and undo
            // the reset.
            Settings.unbind (this, "default-width");
            Settings.unbind (this, "default-height");
            Settings.unbind (this, "maximized");

            // Stop the session saver and remove the state file. Any
            // pending debounced save is cancelled.
            this.session_store.dismiss ();

            // Reset GSettings keys to their schema defaults.
            this.settings.reset ("language");
            this.settings.reset ("window-width");
            this.settings.reset ("window-height");
            this.settings.reset ("window-maximized");

            // Close the window — SessionStore is dismissed so the
            // close-request handler's flush() is a no-op. The
            // unbound geometry properties can no longer touch
            // settings either.
            this.close ();
        }

        private void show_about () {
            var about = new Adw.AboutWindow ();
            about.application_name = "Inversée";
            about.application_icon = Config.APP_ID;
            about.developer_name = "Benjamin Bellamy";
            about.version = Config.VERSION;
            about.website = "https://github.com/benjaminbellamy/inversee";
            about.issue_url =
                "https://github.com/benjaminbellamy/inversee/issues";
            about.copyright = "© 2026 Benjamin Bellamy";
            about.license_type = Gtk.License.GPL_3_0;
            about.comments = _("A Reverse Polish Notation calculator");
            about.transient_for = this;
            about.modal = true;
            about.present ();
        }

        private void show_shortcuts () {
            var dialog = new Adw.Window ();
            dialog.transient_for = this;
            dialog.modal = true;
            dialog.set_default_size (420, 560);
            dialog.title = _("Keyboard Shortcuts");

            var header = new Adw.HeaderBar ();

            var grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 24;
            grid.margin_top = 18;
            grid.margin_bottom = 18;
            grid.margin_start = 18;
            grid.margin_end = 18;

            int row = 0;
            this.add_shortcut_row (grid, ref row, "0–9",          _("Digit entry"));
            this.add_shortcut_row (grid, ref row, ". / ,",        _("Decimal separator"));
            this.add_shortcut_row (grid, ref row, _("Enter"),     _("Push entry / duplicate X"));
            this.add_shortcut_row (grid, ref row, _("Backspace"), _("Delete last char / drop X"));
            this.add_shortcut_row (grid, ref row, "+ − × ÷",      _("Arithmetic"));
            this.add_shortcut_row (grid, ref row, "%",            _("Percent of"));
            this.add_shortcut_row (grid, ref row, "^",            _("Power (x^y)"));
            this.add_shortcut_row (grid, ref row, "r",            _("Square root"));
            this.add_shortcut_row (grid, ref row, "i",            _("Inverse (1/x)"));
            this.add_shortcut_row (grid, ref row, "n",            _("Negate (+/−)"));
            this.add_shortcut_row (grid, ref row, "m",            _("Modulo"));
            this.add_shortcut_row (grid, ref row, "s",            _("Swap"));
            this.add_shortcut_row (grid, ref row, "d",            _("Drop"));
            this.add_shortcut_row (grid, ref row, "t",            _("Rotate"));
            this.add_shortcut_row (grid, ref row, _("Escape"),    _("Clear stack"));
            this.add_shortcut_row (grid, ref row, "Ctrl+Z",       _("Undo"));
            this.add_shortcut_row (grid, ref row, "Ctrl+C",       _("Copy X"));
            this.add_shortcut_row (grid, ref row, "Ctrl+V",       _("Paste"));

            var scrolled = new Gtk.ScrolledWindow ();
            scrolled.hexpand = true;
            scrolled.vexpand = true;
            scrolled.set_child (grid);

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.append (header);
            box.append (scrolled);
            dialog.set_content (box);
            dialog.present ();
        }

        private void add_shortcut_row (Gtk.Grid grid,
                                       ref int row,
                                       string key,
                                       string description) {
            var key_label = new Gtk.Label (key);
            key_label.add_css_class ("numeric");
            key_label.add_css_class ("monospace");
            key_label.xalign = 0;

            var desc_label = new Gtk.Label (description);
            desc_label.xalign = 0;
            desc_label.hexpand = true;
            desc_label.wrap = true;

            grid.attach (key_label, 0, row, 1, 1);
            grid.attach (desc_label, 1, row, 1, 1);
            row++;
        }

        // === Keyboard shortcuts (window-wide) ===

        private void install_keyboard_shortcuts () {
            var ctrl = new Gtk.EventControllerKey ();
            // CAPTURE so we intercept BEFORE any focused button can
            // activate on Enter or letter keys.
            ctrl.propagation_phase = Gtk.PropagationPhase.CAPTURE;
            ctrl.key_pressed.connect (this.on_key_pressed);
            ((Gtk.Widget) this).add_controller (ctrl);
        }

        private bool on_key_pressed (uint keyval,
                                     uint keycode,
                                     Gdk.ModifierType state) {
            bool ctrl_held = (state & Gdk.ModifierType.CONTROL_MASK) != 0;

            uint lkv = Gdk.keyval_to_lower (keyval);

            // Let Tab / Space / arrows through so focus and button
            // activation still work normally.
            if (keyval == Gdk.Key.Tab
                    || keyval == Gdk.Key.ISO_Left_Tab
                    || keyval == Gdk.Key.space
                    || keyval == Gdk.Key.Up
                    || keyval == Gdk.Key.Down
                    || keyval == Gdk.Key.Left
                    || keyval == Gdk.Key.Right) {
                return false;
            }

            if (lkv == Gdk.Key.z && ctrl_held) {
                this.run_op (() => this.calc.undo ());
                return true;
            }
            if (lkv == Gdk.Key.c && ctrl_held) {
                this.on_copy_x ();
                return true;
            }
            if (lkv == Gdk.Key.v && ctrl_held) {
                this.paste_from_clipboard.begin ();
                return true;
            }

            if (keyval >= Gdk.Key.@0 && keyval <= Gdk.Key.@9) {
                this.calc.append_digit ((char) ('0' + (keyval - Gdk.Key.@0)));
                return true;
            }
            if (keyval >= Gdk.Key.KP_0 && keyval <= Gdk.Key.KP_9) {
                this.calc.append_digit ((char) ('0' + (keyval - Gdk.Key.KP_0)));
                return true;
            }

            switch (keyval) {
                case Gdk.Key.period:
                case Gdk.Key.comma:
                case Gdk.Key.KP_Decimal:
                    this.calc.append_decimal ();
                    return true;
                case Gdk.Key.Return:
                case Gdk.Key.KP_Enter:
                    // Project convention: Enter always validates the
                    // entry / dups X, never activates a focused button.
                    this.run_op (() => this.calc.enter ());
                    return true;
                case Gdk.Key.BackSpace:
                    this.run_op (() => this.calc.backspace ());
                    return true;
                case Gdk.Key.plus:
                case Gdk.Key.KP_Add:
                    this.run_op (() => this.calc.apply_binary (BinaryOp.ADD));
                    return true;
                case Gdk.Key.minus:
                case Gdk.Key.KP_Subtract:
                    this.run_op (() => this.calc.apply_binary (BinaryOp.SUB));
                    return true;
                case Gdk.Key.asterisk:
                case Gdk.Key.KP_Multiply:
                    this.run_op (() => this.calc.apply_binary (BinaryOp.MUL));
                    return true;
                case Gdk.Key.slash:
                case Gdk.Key.KP_Divide:
                    this.run_op (() => this.calc.apply_binary (BinaryOp.DIV));
                    return true;
                case Gdk.Key.percent:
                    this.run_op (() => this.calc.apply_binary (BinaryOp.PERCENT));
                    return true;
                case Gdk.Key.asciicircum:
                    this.run_op (() => this.calc.apply_binary (BinaryOp.POW));
                    return true;
                case Gdk.Key.Escape:
                    this.run_op (() => this.calc.clear_stack ());
                    return true;
                default:
                    break;
            }

            switch (lkv) {
                case Gdk.Key.r:
                    this.run_op (() => this.calc.apply_unary (UnaryOp.SQRT));
                    return true;
                case Gdk.Key.i:
                    this.run_op (() => this.calc.apply_unary (UnaryOp.INVERSE));
                    return true;
                case Gdk.Key.n:
                    this.run_op (() => this.calc.toggle_sign ());
                    return true;
                case Gdk.Key.m:
                    this.run_op (() => this.calc.apply_binary (BinaryOp.MOD));
                    return true;
                case Gdk.Key.s:
                    this.run_op (() => this.calc.swap ());
                    return true;
                case Gdk.Key.d:
                    this.run_op (() => this.calc.drop ());
                    return true;
                case Gdk.Key.t:
                    this.run_op (() => this.calc.rot ());
                    return true;
                default:
                    break;
            }

            return false;
        }

        // === Error / clipboard helpers ===

        private delegate void ThrowingAction () throws Error;

        private void run_op (ThrowingAction action) {
            try {
                action ();
            } catch (Error e) {
                this.show_error (e.message);
            }
        }

        private void show_error (string message) {
            var toast = new Adw.Toast (message);
            toast.timeout = 3;
            this.toast_overlay.add_toast (toast);
        }

        private void show_info (string message) {
            var toast = new Adw.Toast (message);
            toast.timeout = 2;
            this.toast_overlay.add_toast (toast);
        }

        private void on_copy_value (string display_value) {
            this.get_clipboard ().set_text (
                Localize.format_number (display_value)
            );
            var toast = new Adw.Toast (_("Copied"));
            toast.timeout = 1;
            this.toast_overlay.add_toast (toast);
        }

        private void on_copy_x () {
            if (this.calc.stack.is_empty) {
                this.show_error (_("Nothing to copy"));
                return;
            }
            try {
                var x = this.calc.stack.peek (0);
                this.on_copy_value (x.to_display_string ());
            } catch (Error e) {
                this.show_error (e.message);
            }
        }

        private void on_copy_stack () {
            if (this.calc.stack.is_empty) {
                this.show_error (_("Nothing to copy"));
                return;
            }
            var builder = new StringBuilder ();
            int size = this.calc.stack.size;
            // Bottom to top — matches how paste pushes whitespace-
            // separated values.
            for (int i = size - 1; i >= 0; i--) {
                try {
                    var v = this.calc.stack.peek (i);
                    builder.append (Localize.format_number (v.to_display_string ()));
                    if (i > 0) {
                        builder.append_c ('\n');
                    }
                } catch (Error e) {
                    // unreachable
                }
            }
            this.get_clipboard ().set_text (builder.str);
            var toast = new Adw.Toast (_("Stack copied"));
            toast.timeout = 1;
            this.toast_overlay.add_toast (toast);
        }

        private async void paste_from_clipboard () {
            var clipboard = this.get_clipboard ();
            try {
                string? text = yield clipboard.read_text_async (null);
                if (text == null || text.length == 0) {
                    return;
                }
                var values = Parser.parse_multiple (text);
                this.calc.push_values (values);
            } catch (Error e) {
                this.show_error (e.message);
            }
        }
    }
}
