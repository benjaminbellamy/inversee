project(
    'inversee',
    ['vala', 'c'],
    version: '1.0.2',
    license: 'GPL-3.0-or-later',
    meson_version: '>= 1.1.0',
    default_options: [
        'warning_level=2',
        'buildtype=debugoptimized',
    ],
)

i18n = import('i18n')
gnome = import('gnome')

vala = meson.get_compiler('vala')

vapi_dir = meson.project_source_root() / 'vapi'

add_project_arguments(
    ['--vapidir', vapi_dir],
    language: 'vala',
)

app_id = 'fr.benjaminbellamy.Inversee'
app_path = '/fr/benjaminbellamy/Inversee/'
gettext_package = 'inversee'

prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')
localedir = prefix / get_option('localedir')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_package),
    language: 'c',
)

glib_dep = dependency('glib-2.0', version: '>= 2.74')
gio_dep = dependency('gio-2.0', version: '>= 2.74')
gobject_dep = dependency('gobject-2.0', version: '>= 2.74')
gtk_dep = dependency('gtk4', version: '>= 4.10')
adw_dep = dependency('libadwaita-1', version: '>= 1.4')
gmp_dep = dependency('gmp')
mpfr_dep = dependency('mpfr')
mpfr_vapi_dep = vala.find_library('mpfr', dirs: vapi_dir)
json_dep = dependency('json-glib-1.0', version: '>= 1.6')

config_data = configuration_data()
config_data.set_quoted('APP_ID', app_id)
config_data.set_quoted('GETTEXT_PACKAGE', gettext_package)
config_data.set_quoted('LOCALEDIR', localedir)
config_data.set_quoted('VERSION', meson.project_version())
config_data.set_quoted('PROFILE', get_option('profile'))
config_data.set_quoted('SOURCE_ICONS_DIR',
                       meson.project_source_root() / 'data' / 'icons')
config_data.set_quoted('SCHEMAS_DIR',
                       meson.project_build_root() / 'data')
config_data.set_quoted('BUILD_LOCALEDIR',
                       meson.project_build_root() / 'po')

config_vala = configure_file(
    input: 'src/config.vala.in',
    output: 'config.vala',
    configuration: config_data,
)

subdir('po')
subdir('data')
subdir('src')

if get_option('tests')
    subdir('tests')
endif

# Flathub requires the source license to be shipped inside the
# bundle at $FLATPAK_DEST/share/licenses/$FLATPAK_ID/.
install_data(
    'LICENSE',
    install_dir: datadir / 'licenses' / app_id,
)

gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true,
    update_desktop_database: true,
)
