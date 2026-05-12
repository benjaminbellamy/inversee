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

    /** Errors raised by {@link Stack} operations. */
    public errordomain StackError {
        /** An operation requires more operands than the stack contains. */
        UNDERFLOW
    }

    /**
     * An unbounded LIFO stack of {@link Number} values.
     *
     * Operations that consume N operands on a stack with fewer than N
     * items raise {@link StackError.UNDERFLOW}. When such an operation
     * throws, the stack is unchanged — callers can rely on this
     * transactional behavior to surface a non-fatal error without
     * having to roll back state themselves.
     */
    public class Stack : Object {

        private GenericArray<Number> storage;

        public Stack () {
            this.storage = new GenericArray<Number> ();
        }

        /** Number of items on the stack. */
        public int size {
            get { return (int) this.storage.length; }
        }

        public bool is_empty {
            get { return this.storage.length == 0; }
        }

        /** Push {@code n} onto the top of the stack. */
        public void push (Number n) {
            this.storage.add (n);
        }

        /** Pop and return the top of the stack. */
        public Number pop () throws StackError {
            if (this.storage.length == 0) {
                throw new StackError.UNDERFLOW (_("Stack is empty"));
            }
            uint last = this.storage.length - 1;
            var top = this.storage[last];
            this.storage.remove_index (last);
            return top;
        }

        /**
         * Returns the item at {@code index_from_top} positions from the
         * top without modifying the stack. Index 0 is X (top), 1 is Y,
         * 2 is Z, etc.
         */
        public Number peek (int index_from_top = 0) throws StackError {
            if (index_from_top < 0
                    || index_from_top >= (int) this.storage.length) {
                throw new StackError.UNDERFLOW (
                    _("Index %d out of range"), index_from_top
                );
            }
            uint idx = this.storage.length - 1 - (uint) index_from_top;
            return this.storage[idx];
        }

        /** Duplicate the top of the stack. */
        public void dup () throws StackError {
            if (this.storage.length == 0) {
                throw new StackError.UNDERFLOW (_("Stack is empty"));
            }
            this.storage.add (this.storage[this.storage.length - 1]);
        }

        /**
         * Duplicate the top two: {@code ( y x -- y x y x )}.
         * Forth's 2DUP.
         */
        public void dup2 () throws StackError {
            if (this.storage.length < 2) {
                throw new StackError.UNDERFLOW (_("dup2 needs 2 operands"));
            }
            uint last = this.storage.length - 1;
            var y = this.storage[last - 1];
            var x = this.storage[last];
            this.storage.add (y);
            this.storage.add (x);
        }

        /** Swap X and Y. */
        public void swap () throws StackError {
            if (this.storage.length < 2) {
                throw new StackError.UNDERFLOW (_("swap needs 2 operands"));
            }
            uint last = this.storage.length - 1;
            var top = this.storage[last];
            this.storage[last] = this.storage[last - 1];
            this.storage[last - 1] = top;
        }

        /** Discard the top of the stack. */
        public void drop () throws StackError {
            if (this.storage.length == 0) {
                throw new StackError.UNDERFLOW (_("Stack is empty"));
            }
            this.storage.remove_index (this.storage.length - 1);
        }

        /**
         * Rotate the top three: {@code ( z y x -- y x z )}.
         * The third element from the top moves to the top; the items
         * that were above it shift down by one.
         */
        public void rot () throws StackError {
            if (this.storage.length < 3) {
                throw new StackError.UNDERFLOW (_("rot needs 3 operands"));
            }
            uint third = this.storage.length - 3;
            var z = this.storage[third];
            this.storage.remove_index (third);
            this.storage.add (z);
        }

        /** Empty the stack. */
        public void clear () {
            this.storage = new GenericArray<Number> ();
        }

        /**
         * Returns a fresh array of the stack's contents, bottom to top.
         * Index 0 is the deepest item; the last element is X.
         */
        public Number[] to_array () {
            Number[] result = new Number[this.storage.length];
            for (uint i = 0; i < this.storage.length; i++) {
                result[i] = this.storage[i];
            }
            return result;
        }

        /**
         * Replace the stack's contents with {@code items}, interpreted
         * bottom to top. Intended for snapshot restore and deserialization.
         */
        public void restore_from_array (Number[] items) {
            this.storage = new GenericArray<Number> ();
            foreach (unowned Number n in items) {
                this.storage.add (n);
            }
        }
    }
}
