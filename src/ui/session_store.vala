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
     * Persists a {@link Calculator}'s stack + history to disk between
     * sessions.
     *
     * Reads {@code $XDG_DATA_HOME/inversee/state.json} on {@link load}
     * and writes back on a 500 ms debounce off every {@code changed}
     * signal. A corrupt file is renamed to {@code state.json.bak.<ts>}
     * and the app starts with an empty stack — we never refuse to
     * launch because of a bad state file (per the project spec).
     */
    public class SessionStore : Object {

        private const uint SAVE_DEBOUNCE_MS = 500;

        private Calculator calc;
        private File state_file;
        private uint save_timeout_id = 0;
        private bool loading = false;
        private bool dismissed = false;

        public SessionStore (Calculator calc) {
            this.calc = calc;
            string dir = Environment.get_user_data_dir ();
            this.state_file = File.new_for_path (
                Path.build_filename (dir, "inversee", "state.json")
            );
            this.calc.changed.connect (this.schedule_save);
        }

        /**
         * Read the state file (if any) and populate the calculator.
         * Returns true if a usable state was loaded; false on missing
         * or corrupt files (in which case the corrupt file is moved
         * aside).
         */
        public bool load () {
            if (!this.state_file.query_exists ()) {
                return false;
            }

            uint8[] contents;
            try {
                this.state_file.load_contents (null, out contents, null);
            } catch (Error e) {
                warning ("could not read state file: %s", e.message);
                return false;
            }

            this.loading = true;
            try {
                Persistence.deserialize (
                    (string) contents,
                    this.calc.stack,
                    this.calc.history
                );
                this.loading = false;
                this.calc.changed ();
                return true;
            } catch (Error e) {
                this.loading = false;
                warning ("corrupted state file: %s", e.message);
                this.rename_corrupted ();
                return false;
            }
        }

        /**
         * Force any pending debounced save to happen now and write
         * the current state synchronously. Call from
         * {@code close-request} so changes aren't lost on quit. No-op
         * if {@link dismiss} has been called.
         */
        public void flush () {
            if (this.save_timeout_id != 0) {
                Source.remove (this.save_timeout_id);
                this.save_timeout_id = 0;
            }
            if (this.dismissed) {
                return;
            }
            this.save_now ();
        }

        /**
         * Disable all further saves, cancel any pending one, and
         * delete the saved state file. Used by the "Reset and quit"
         * action so the imminent close does not write current state
         * back to disk.
         */
        public void dismiss () {
            this.dismissed = true;
            if (this.save_timeout_id != 0) {
                Source.remove (this.save_timeout_id);
                this.save_timeout_id = 0;
            }
            try {
                if (this.state_file.query_exists ()) {
                    this.state_file.delete ();
                }
            } catch (Error e) {
                warning ("could not delete state file: %s", e.message);
            }
        }

        private void schedule_save () {
            if (this.loading || this.dismissed) {
                return;
            }
            if (this.save_timeout_id != 0) {
                Source.remove (this.save_timeout_id);
            }
            this.save_timeout_id = Timeout.add (
                SAVE_DEBOUNCE_MS,
                () => {
                    this.save_timeout_id = 0;
                    this.save_now ();
                    return Source.REMOVE;
                }
            );
        }

        private void save_now () {
            try {
                this.ensure_dir ();
                string json = Persistence.serialize (
                    this.calc.stack, this.calc.history
                );
                // replace_contents is atomic: writes to a temp file
                // and renames over the destination, so we don't end
                // up with a partial file if we crash mid-write.
                this.state_file.replace_contents (
                    json.data, null, false,
                    FileCreateFlags.REPLACE_DESTINATION,
                    null, null
                );
            } catch (Error e) {
                warning ("could not write state file: %s", e.message);
            }
        }

        private void ensure_dir () throws Error {
            var parent = this.state_file.get_parent ();
            if (parent == null) {
                return;
            }
            if (!parent.query_exists ()) {
                parent.make_directory_with_parents (null);
            }
        }

        private void rename_corrupted () {
            var ts = new DateTime.now_utc ().format ("%Y%m%dT%H%M%SZ");
            string backup_path =
                this.state_file.get_path () + ".bak." + ts;
            var backup = File.new_for_path (backup_path);
            try {
                this.state_file.move (
                    backup, FileCopyFlags.NONE, null, null
                );
            } catch (Error e) {
                warning ("could not back up corrupted state: %s", e.message);
            }
        }
    }
}
