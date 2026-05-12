/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Inversée - Reverse Polish Notation calculator
 * Copyright (C) 2026 Benjamin Bellamy <benjamin@castopod.org>
 *
 * Minimal Vala bindings for the surface of MPFR used by libinversee-core.
 * MPFR's mpfr_t is a typedef for __mpfr_struct[1]; binding the underlying
 * struct as a Vala compact class — with alloc/free wrapped in tiny C
 * helpers — avoids the array-typedef awkwardness.
 *
 * This binding file is part of Inversée and licensed under GPL-3.0-or-later;
 * MPFR itself is LGPLv3 and is used as an external library.
 */

[CCode (cheader_filename = "mpfr.h,inversee_mpfr_helpers.h")]
namespace MPFR {

    [CCode (cname = "mpfr_rnd_t", cprefix = "MPFR_RND", has_type_id = false)]
    public enum Round {
        N,
        Z,
        U,
        D,
        A,
        F
    }

    [Compact]
    [CCode (cname = "__mpfr_struct", free_function = "inversee_mpfr_free")]
    public class MPFloat {
        [CCode (cname = "inversee_mpfr_new")]
        public MPFloat (long precision);

        [CCode (cname = "mpfr_set_d")]
        public int set_d (double op, MPFR.Round rnd);

        [CCode (cname = "mpfr_set_str")]
        public int set_str (string s, int radix, MPFR.Round rnd);

        [CCode (cname = "mpfr_set")]
        public int set (MPFR.MPFloat op, MPFR.Round rnd);

        [CCode (cname = "mpfr_get_d")]
        public double get_d (MPFR.Round rnd);

        [CCode (cname = "mpfr_add")]
        public int add (MPFR.MPFloat op1, MPFR.MPFloat op2, MPFR.Round rnd);

        [CCode (cname = "mpfr_sub")]
        public int sub (MPFR.MPFloat op1, MPFR.MPFloat op2, MPFR.Round rnd);

        [CCode (cname = "mpfr_mul")]
        public int mul (MPFR.MPFloat op1, MPFR.MPFloat op2, MPFR.Round rnd);

        [CCode (cname = "mpfr_div")]
        public int div (MPFR.MPFloat op1, MPFR.MPFloat op2, MPFR.Round rnd);

        [CCode (cname = "mpfr_pow")]
        public int pow (MPFR.MPFloat op1, MPFR.MPFloat op2, MPFR.Round rnd);

        [CCode (cname = "mpfr_sqrt")]
        public int sqrt (MPFR.MPFloat op, MPFR.Round rnd);

        [CCode (cname = "mpfr_fmod")]
        public int fmod (MPFR.MPFloat x, MPFR.MPFloat y, MPFR.Round rnd);

        [CCode (cname = "mpfr_neg")]
        public int neg (MPFR.MPFloat op, MPFR.Round rnd);

        [CCode (cname = "mpfr_si_div")]
        public int si_div (long op1, MPFR.MPFloat op2, MPFR.Round rnd);

        [CCode (cname = "mpfr_cmp")]
        public int cmp (MPFR.MPFloat op);

        [CCode (cname = "mpfr_zero_p")]
        public int zero_p ();

        [CCode (cname = "mpfr_nan_p")]
        public int nan_p ();

        [CCode (cname = "mpfr_inf_p")]
        public int inf_p ();

        [CCode (cname = "mpfr_regular_p")]
        public int regular_p ();

        [CCode (cname = "mpfr_sgn")]
        public int sgn ();

        [CCode (cname = "inversee_mpfr_format")]
        public int format (int digits, [CCode (array_length_type = "size_t")] char[] buf);
    }
}
