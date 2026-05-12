# SPDX-License-Identifier: GPL-3.0-or-later
# libinversee-core: pure-logic engine (no GTK dependency).

inversee_core_vala_sources = files(
    'number.vala',
    'stack.vala',
    'parser.vala',
    'history.vala',
    'persistence.vala',
    'calculator.vala',
)

inversee_core_c_sources = files(
    'inversee_mpfr_helpers.c',
)

inversee_core_inc = include_directories('.')

inversee_core_lib = static_library(
    'inversee-core',
    inversee_core_vala_sources,
    inversee_core_c_sources,
    include_directories: inversee_core_inc,
    dependencies: [glib_dep, gobject_dep, mpfr_dep, mpfr_vapi_dep, json_dep],
    vala_vapi: 'inversee-core.vapi',
    vala_header: 'inversee-core.h',
    install: false,
)

inversee_core_dep = declare_dependency(
    link_with: inversee_core_lib,
    include_directories: inversee_core_inc,
    dependencies: [glib_dep, gobject_dep, mpfr_dep, mpfr_vapi_dep, json_dep],
)
