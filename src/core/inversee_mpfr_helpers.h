/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
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

#ifndef INVERSEE_MPFR_HELPERS_H
#define INVERSEE_MPFR_HELPERS_H

#include <mpfr.h>
#include <stddef.h>

/* Allocate and mpfr_init2() a fresh __mpfr_struct. Result must be freed
 * with inversee_mpfr_free(). */
__mpfr_struct *inversee_mpfr_new (long precision);

/* mpfr_clear() and free the struct. NULL-safe. */
void inversee_mpfr_free (__mpfr_struct *p);

/* Format op into buf via mpfr_snprintf("%.*Rg", digits, op).
 * Returns the number of bytes written (excluding NUL), or a negative
 * value on error. The buffer is always NUL-terminated when buflen > 0. */
int inversee_mpfr_format (const __mpfr_struct *op,
                          int digits,
                          char *buf,
                          size_t buflen);

#endif /* INVERSEE_MPFR_HELPERS_H */
