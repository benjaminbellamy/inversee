desktop_file = i18n.merge_file(
    input: '@0@.desktop.in'.format(app_id),
    output: '@0@.desktop'.format(app_id),
    type: 'desktop',
    po_dir: meson.project_source_root() / 'po',
    install: true,
    install_dir: datadir / 'applications',
)

desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
    test(
        'desktop-file-validate',
        desktop_file_validate,
        args: [desktop_file],
    )
endif

metainfo_file = i18n.merge_file(
    input: '@0@.metainfo.xml.in'.format(app_id),
    output: '@0@.metainfo.xml'.format(app_id),
    type: 'xml',
    po_dir: meson.project_source_root() / 'po',
    install: true,
    install_dir: datadir / 'metainfo',
)

appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
    test(
        'appstream-validate',
        appstreamcli,
        args: ['validate', '--no-net', '--explain', metainfo_file],
    )
endif

install_data(
    '@0@.gschema.xml'.format(app_id),
    install_dir: datadir / 'glib-2.0' / 'schemas',
)

# Compile the schema into the build dir so uninstalled runs can find it
# via GSETTINGS_SCHEMA_DIR (wired through Config.SCHEMAS_DIR).
gnome.compile_schemas(
    depend_files: files('@0@.gschema.xml'.format(app_id)),
    build_by_default: true,
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
    test(
        'gschema-validate',
        compile_schemas,
        args: ['--strict', '--dry-run', meson.current_source_dir()],
    )
endif

inversee_gresource = gnome.compile_resources(
    'inversee-resources',
    'inversee.gresource.xml',
    source_dir: meson.current_source_dir(),
    dependencies: files('shortcuts.ui'),
)

install_data(
    'icons' / 'hicolor' / 'scalable' / 'apps' / '@0@.svg'.format(app_id),
    install_dir: datadir / 'icons' / 'hicolor' / 'scalable' / 'apps',
)

install_data(
    'icons' / 'hicolor' / 'symbolic' / 'apps' / '@0@-symbolic.svg'.format(app_id),
    install_dir: datadir / 'icons' / 'hicolor' / 'symbolic' / 'apps',
)
