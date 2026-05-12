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

    /** Errors raised by {@link Persistence}. */
    public errordomain PersistenceError {
        /** Input was not valid JSON. */
        INVALID_JSON,
        /** JSON parsed but the {@code version} field is not supported. */
        UNSUPPORTED_VERSION,
        /** A required field is missing or has the wrong shape. */
        MALFORMED_VALUE
    }

    /**
     * Lossless JSON round-trip for a {@link Stack} and its associated
     * {@link History}. Pure in-memory string ↔ state conversion — file
     * I/O, debouncing, and corruption recovery are the UI layer's job.
     *
     * Each number is encoded as its 40-digit canonical-form string,
     * which round-trips through {@link Number.from_string} losslessly.
     */
    public class Persistence : Object {

        public const int CURRENT_VERSION = 1;

        /**
         * Serialize {@code stack} and {@code history} into a pretty-
         * printed JSON document.
         */
        public static string serialize (Stack stack, History history) {
            var builder = new Json.Builder ();
            builder.begin_object ();

            builder.set_member_name ("version");
            builder.add_int_value (CURRENT_VERSION);

            builder.set_member_name ("stack");
            write_number_array (builder, stack.to_array ());

            builder.set_member_name ("undo");
            write_snapshots (builder, history.undo_snapshots ());

            builder.end_object ();

            var gen = new Json.Generator ();
            gen.set_root (builder.get_root ());
            gen.pretty = true;
            return gen.to_data (null);
        }

        /**
         * Parse {@code json} and replace {@code stack} and
         * {@code history}'s contents with the decoded state.
         */
        public static void deserialize (string json,
                                        Stack stack,
                                        History history)
                throws PersistenceError {
            var parser = new Json.Parser ();
            try {
                parser.load_from_data (json, -1);
            } catch (Error e) {
                throw new PersistenceError.INVALID_JSON (
                    _("Could not parse state: %s"), e.message
                );
            }

            var root = parser.get_root ();
            if (root == null
                    || root.get_node_type () != Json.NodeType.OBJECT) {
                throw new PersistenceError.INVALID_JSON (
                    _("State root must be a JSON object")
                );
            }
            var obj = root.get_object ();

            if (!obj.has_member ("version")) {
                throw new PersistenceError.MALFORMED_VALUE (
                    _("Missing 'version' field")
                );
            }
            int64 version = obj.get_int_member ("version");
            if (version != CURRENT_VERSION) {
                throw new PersistenceError.UNSUPPORTED_VERSION (
                    _("State version %s is not supported"),
                    version.to_string ()
                );
            }

            Number[]   stack_items = read_number_array (obj, "stack");
            Snapshot[] undo_snaps  = read_snapshots (obj, "undo");

            stack.restore_from_array (stack_items);
            history.restore (undo_snaps);
        }

        private static void write_number_array (Json.Builder b,
                                                Number[] items) {
            b.begin_array ();
            foreach (unowned Number n in items) {
                b.add_string_value (n.to_canonical_string ());
            }
            b.end_array ();
        }

        private static void write_snapshots (Json.Builder b,
                                             Snapshot[] snapshots) {
            b.begin_array ();
            foreach (unowned Snapshot s in snapshots) {
                write_number_array (b, s.items);
            }
            b.end_array ();
        }

        private static Number[] read_number_array (Json.Object obj,
                                                   string key)
                throws PersistenceError {
            var node = obj.get_member (key);
            if (node == null
                    || node.get_node_type () != Json.NodeType.ARRAY) {
                throw new PersistenceError.MALFORMED_VALUE (
                    _("Field '%s' must be an array"), key
                );
            }
            var arr = node.get_array ();
            uint len = arr.get_length ();
            Number[] result = new Number[len];
            for (uint i = 0; i < len; i++) {
                var item = arr.get_element (i);
                if (item.get_node_type () != Json.NodeType.VALUE) {
                    throw new PersistenceError.MALFORMED_VALUE (
                        _("Element '%s'[%u] must be a string"), key, i
                    );
                }
                string canonical = item.get_string ();
                var n = Number.from_string (canonical);
                if (n == null) {
                    throw new PersistenceError.MALFORMED_VALUE (
                        _("Element '%s'[%u] is not a valid number: %s"),
                        key, i, canonical
                    );
                }
                result[i] = n;
            }
            return result;
        }

        private static Snapshot[] read_snapshots (Json.Object obj,
                                                  string key)
                throws PersistenceError {
            var node = obj.get_member (key);
            if (node == null
                    || node.get_node_type () != Json.NodeType.ARRAY) {
                throw new PersistenceError.MALFORMED_VALUE (
                    _("Field '%s' must be an array"), key
                );
            }
            var arr = node.get_array ();
            uint len = arr.get_length ();
            Snapshot[] result = {};
            for (uint i = 0; i < len; i++) {
                var sub_node = arr.get_element (i);
                if (sub_node.get_node_type () != Json.NodeType.ARRAY) {
                    throw new PersistenceError.MALFORMED_VALUE (
                        _("Element '%s'[%u] must be an array"), key, i
                    );
                }
                var sub_arr = sub_node.get_array ();
                uint sub_len = sub_arr.get_length ();
                Number[] snap_items = new Number[sub_len];
                for (uint j = 0; j < sub_len; j++) {
                    var item = sub_arr.get_element (j);
                    if (item.get_node_type () != Json.NodeType.VALUE) {
                        throw new PersistenceError.MALFORMED_VALUE (
                            _("Element '%s'[%u][%u] must be a string"),
                            key, i, j
                        );
                    }
                    string canonical = item.get_string ();
                    var n = Number.from_string (canonical);
                    if (n == null) {
                        throw new PersistenceError.MALFORMED_VALUE (
                            _("Element '%s'[%u][%u] is not a valid number: %s"),
                            key, i, j, canonical
                        );
                    }
                    snap_items[j] = n;
                }
                result += new Snapshot (snap_items);
            }
            return result;
        }
    }
}
