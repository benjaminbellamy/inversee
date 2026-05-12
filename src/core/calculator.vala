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

    public errordomain CalculatorError {
        /** The current entry buffer is not a parseable number. */
        INVALID_ENTRY
    }

    public enum BinaryOp {
        ADD,
        SUB,
        MUL,
        DIV,
        MOD,
        POW,
        PERCENT
    }

    public enum UnaryOp {
        NEGATE,
        INVERSE,
        SQRT
    }

    /**
     * High-level RPN engine: owns a {@link Stack}, a {@link History},
     * and a single in-progress entry buffer.
     *
     * Every state-mutating method emits {@link changed} on success and
     * runs inside a single history transaction. If anything inside the
     * transaction throws, both the stack and the entry buffer are
     * restored — the UI can surface the error without worrying about
     * partial-success state.
     */
    public class Calculator : Object {

        public Stack stack { get; private set; }
        public History history { get; private set; }

        /**
         * The in-progress entry, in canonical form (ASCII period as
         * decimal separator). Empty when no entry is in progress. The
         * UI layer is responsible for locale conversion on display.
         */
        public string entry { get; private set; default = ""; }

        /** Emitted after any state mutation. */
        public signal void changed ();

        public Calculator () {
            this.stack = new Stack ();
            this.history = new History (this.stack);
        }

        // === Entry editing ===

        public void append_digit (char digit) {
            if (digit < '0' || digit > '9') {
                return;
            }
            this.entry += digit.to_string ();
            this.changed ();
        }

        public void append_decimal () {
            if (this.entry.contains (".")) {
                return;
            }
            if (this.entry.length == 0) {
                this.entry = "0.";
            } else if (this.entry == "-") {
                this.entry = "-0.";
            } else {
                this.entry += ".";
            }
            this.changed ();
        }

        /**
         * Toggle the sign of the in-progress entry. With no entry and
         * a non-empty stack, negates X via an undoable transaction.
         * Silent no-op when entry and stack are both empty.
         */
        public void toggle_sign () throws Error {
            if (this.entry.length > 0) {
                if (this.entry.has_prefix ("-")) {
                    this.entry = this.entry.substring (1);
                } else {
                    this.entry = "-" + this.entry;
                }
                this.changed ();
                return;
            }
            if (this.stack.is_empty) {
                return;
            }
            this.transact (() => {
                var x = this.stack.pop ();
                this.stack.push (x.negate ());
            });
            this.changed ();
        }

        /**
         * Delete the last character of the entry. With no entry and a
         * non-empty stack, drops X. Silent no-op when both are empty.
         */
        public void backspace () throws Error {
            if (this.entry.length > 0) {
                this.entry = this.entry.substring (0, this.entry.length - 1);
                this.changed ();
                return;
            }
            if (this.stack.is_empty) {
                return;
            }
            this.transact (() => { this.stack.drop (); });
            this.changed ();
        }

        public void clear_entry () {
            if (this.entry.length == 0) {
                return;
            }
            this.entry = "";
            this.changed ();
        }

        // === Actions ===

        /**
         * Commit the in-progress entry (if any) to the stack. With no
         * entry, duplicates X.
         */
        public void enter () throws Error {
            this.transact (() => {
                if (this.entry.length > 0) {
                    this.commit_entry_unsafe ();
                } else {
                    this.stack.dup ();
                }
            });
            this.changed ();
        }

        public void apply_binary (BinaryOp op) throws Error {
            this.transact (() => {
                if (this.entry.length > 0) {
                    this.commit_entry_unsafe ();
                }
                if (this.stack.size < 2) {
                    throw new StackError.UNDERFLOW (_("Needs 2 operands"));
                }
                var x = this.stack.pop ();
                var y = this.stack.pop ();
                Number result;
                switch (op) {
                    case BinaryOp.ADD:     result = y.add (x);          break;
                    case BinaryOp.SUB:     result = y.sub (x);          break;
                    case BinaryOp.MUL:     result = y.mul (x);          break;
                    case BinaryOp.DIV:     result = y.div (x);          break;
                    case BinaryOp.MOD:     result = y.mod (x);          break;
                    case BinaryOp.POW:     result = y.pow (x);          break;
                    case BinaryOp.PERCENT: result = x.percent_of (y);   break;
                    default: assert_not_reached ();
                }
                this.stack.push (result);
            });
            this.changed ();
        }

        public void apply_unary (UnaryOp op) throws Error {
            this.transact (() => {
                if (this.entry.length > 0) {
                    this.commit_entry_unsafe ();
                }
                if (this.stack.size < 1) {
                    throw new StackError.UNDERFLOW (_("Needs 1 operand"));
                }
                var x = this.stack.pop ();
                Number result;
                switch (op) {
                    case UnaryOp.NEGATE:  result = x.negate ();  break;
                    case UnaryOp.INVERSE: result = x.inverse (); break;
                    case UnaryOp.SQRT:    result = x.sqrt ();    break;
                    default: assert_not_reached ();
                }
                this.stack.push (result);
            });
            this.changed ();
        }

        public void swap () throws Error {
            this.transact (() => {
                if (this.entry.length > 0) this.commit_entry_unsafe ();
                this.stack.swap ();
            });
            this.changed ();
        }

        /** Duplicate X (committing any pending entry first). */
        public void dup () throws Error {
            this.transact (() => {
                if (this.entry.length > 0) this.commit_entry_unsafe ();
                this.stack.dup ();
            });
            this.changed ();
        }

        /** Duplicate the top two stack items (committing entry first). */
        public void dup2 () throws Error {
            this.transact (() => {
                if (this.entry.length > 0) this.commit_entry_unsafe ();
                this.stack.dup2 ();
            });
            this.changed ();
        }

        public void drop () throws Error {
            this.transact (() => {
                if (this.entry.length > 0) {
                    // A pending entry "absorbs" the drop: just clear it,
                    // don't pop from the stack.
                    this.entry = "";
                    return;
                }
                this.stack.drop ();
            });
            this.changed ();
        }

        public void rot () throws Error {
            this.transact (() => {
                if (this.entry.length > 0) this.commit_entry_unsafe ();
                this.stack.rot ();
            });
            this.changed ();
        }

        public void clear_stack () throws Error {
            this.transact (() => {
                this.entry = "";
                this.stack.clear ();
            });
            this.changed ();
        }

        // === Undo ===

        public void undo () throws Error {
            string saved_entry = this.entry;
            try {
                this.history.undo ();
            } catch (Error e) {
                this.entry = saved_entry;
                throw e;
            }
            this.entry = "";
            this.changed ();
        }

        // === Programmatic push (clipboard paste etc.) ===

        public void push_values (Number[] values) throws Error {
            if (values.length == 0) {
                return;
            }
            this.transact (() => {
                if (this.entry.length > 0) this.commit_entry_unsafe ();
                foreach (unowned Number n in values) {
                    this.stack.push (n);
                }
            });
            this.changed ();
        }

        // === Internal ===

        /**
         * Run {@code action} as a single transaction over the stack
         * AND the entry buffer. On failure both are restored before
         * the exception is re-raised.
         */
        private void transact (HistoryMutator action) throws Error {
            string saved_entry = this.entry;
            try {
                this.history.commit (action);
            } catch (Error e) {
                this.entry = saved_entry;
                throw e;
            }
        }

        /**
         * Push the current entry onto the stack and clear it. Caller
         * MUST be running inside a {@link transact} closure so that a
         * later failure restores both stack and entry.
         */
        private void commit_entry_unsafe () throws Error {
            var n = Number.from_string (this.entry);
            if (n == null) {
                throw new CalculatorError.INVALID_ENTRY (
                    _("Invalid entry: %s"), this.entry
                );
            }
            this.stack.push (n);
            this.entry = "";
        }
    }
}
