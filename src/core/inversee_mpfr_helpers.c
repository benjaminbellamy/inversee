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

/* uselocale(), newlocale() are POSIX.1-2008; ask for the GNU feature set. */
#define _GNU_SOURCE

#include "inversee_mpfr_helpers.h"

#include <glib.h>
#include <locale.h>
#include <mpfr.h>

__mpfr_struct *
inversee_mpfr_new (long precision)
{
    __mpfr_struct *p = g_new0 (__mpfr_struct, 1);
    mpfr_init2 (p, (mpfr_prec_t) precision);
    return p;
}

void
inversee_mpfr_free (__mpfr_struct *p)
{
    if (p != NULL) {
        mpfr_clear (p);
        g_free (p);
    }
}

/*
 * A cached C locale used to keep numeric formatting locale-independent.
 * mpfr_snprintf() honours LC_NUMERIC, so without this it would emit the
 * locale's decimal separator (e.g. a comma under fr_FR). The engine's
 * canonical form must always use an ASCII period; locale-aware display
 * is the UI's job (Inversee.Localize).
 */
static locale_t
inversee_c_numeric_locale (void)
{
    static locale_t loc = (locale_t) 0;
    if (loc == (locale_t) 0) {
        loc = newlocale (LC_NUMERIC_MASK, "C", (locale_t) 0);
    }
    return loc;
}

int
inversee_mpfr_format (const __mpfr_struct *op,
                      int digits,
                      char *buf,
                      size_t buflen)
{
    locale_t c_loc = inversee_c_numeric_locale ();
    locale_t saved = (locale_t) 0;
    int r;

    if (c_loc != (locale_t) 0) {
        saved = uselocale (c_loc);
    }
    r = mpfr_snprintf (buf, buflen, "%.*Rg", digits, op);
    if (saved != (locale_t) 0) {
        uselocale (saved);
    }
    return r;
}
