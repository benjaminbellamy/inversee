subdir('core')

inversee_sources = files(
    'main.vala',
    'ui/application.vala',
    'ui/window.vala',
    'ui/stack_view.vala',
    'ui/entry_view.vala',
    'ui/keypad.vala',
    'ui/formatting.vala',
    'ui/session_store.vala',
)

inversee_deps = [
    glib_dep,
    gio_dep,
    gobject_dep,
    gtk_dep,
    adw_dep,
    inversee_core_dep,
]

executable(
    'inversee',
    inversee_sources + [config_vala],
    dependencies: inversee_deps,
    install: true,
    install_dir: bindir,
)
