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

    /** Errors raised by {@link History}. */
    public errordomain HistoryError {
        NOTHING_TO_UNDO
    }

    /** Action signature accepted by {@link History.commit}. */
    public delegate void HistoryMutator () throws Error;

    /**
     * Frozen snapshot of a {@link Stack}'s contents (bottom to top).
     * Used as the unit of history and persistence.
     */
    public class Snapshot : Object {
        public Number[] items;

        public Snapshot (Number[] items) {
            this.items = items;
        }
    }

    /**
     * Undo-only history over a {@link Stack}, capped at
     * {@link MAX_ENTRIES} per session to bound memory.
     *
     * Every stack-mutating action must go through {@link commit}, which
     * snapshots the stack before the action runs. If the action throws,
     * the snapshot is restored and the exception is re-raised — no
     * history entry is recorded. Otherwise the snapshot becomes a new
     * undo entry.
     */
    public class History : Object {

        public const int MAX_ENTRIES = 1000;

        private Stack target;
        private GLib.Queue<Snapshot> undo_q;

        public History (Stack target) {
            this.target = target;
            this.undo_q = new GLib.Queue<Snapshot> ();
        }

        public bool can_undo {
            get { return this.undo_q.length > 0; }
        }

        public int undo_depth {
            get { return (int) this.undo_q.length; }
        }

        /**
         * Run {@code action} as a single mutating transaction.
         *
         * On success, the pre-action stack contents are pushed onto the
         * undo queue. On exception, the stack is restored and the
         * exception is re-raised; no history entry is recorded.
         */
        public void commit (HistoryMutator action) throws Error {
            Number[] before = this.target.to_array ();
            try {
                action ();
            } catch (Error e) {
                this.target.restore_from_array (before);
                throw e;
            }
            this.push_undo (new Snapshot (before));
        }

        public void undo () throws HistoryError {
            if (this.undo_q.length == 0) {
                throw new HistoryError.NOTHING_TO_UNDO (_("nothing to undo"));
            }
            var previous = this.undo_q.pop_tail ();
            this.target.restore_from_array (previous.items);
        }

        /**
         * Returns the undo queue's snapshots, oldest first. Each
         * snapshot is the stack state immediately before a committed
         * action. Intended for serialization.
         */
        public Snapshot[] undo_snapshots () {
            Snapshot[] result = {};
            for (unowned GLib.List<Snapshot> link = this.undo_q.head;
                    link != null;
                    link = link.next) {
                result += link.data;
            }
            return result;
        }

        /**
         * Replace the undo queue with the given snapshot list, oldest
         * first. Intended for deserialization. Caps the result at
         * {@link MAX_ENTRIES}.
         */
        public void restore (Snapshot[] undo_snapshots) {
            this.undo_q = new GLib.Queue<Snapshot> ();
            foreach (unowned Snapshot s in undo_snapshots) {
                this.undo_q.push_tail (s);
            }
            while ((int) this.undo_q.length > MAX_ENTRIES) {
                this.undo_q.pop_head ();
            }
        }

        private void push_undo (Snapshot s) {
            this.undo_q.push_tail (s);
            while ((int) this.undo_q.length > MAX_ENTRIES) {
                this.undo_q.pop_head ();
            }
        }
    }
}
