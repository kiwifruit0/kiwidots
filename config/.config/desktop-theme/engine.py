#!/usr/bin/env python3
"""One palette, native app configs. Python 3.11+, no third-party modules."""
import argparse
import configparser
import copy
import fcntl
import io
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import time
import tomllib

ROOT = Path(__file__).resolve().parent
HOME = Path.home()
CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', HOME / '.config'))
STATE = Path(os.environ.get('XDG_STATE_HOME', HOME / '.local/state')) / 'kiwidots-theme'
CURRENT = ROOT / 'current'
ALIASES = {'catppuccin': 'catppuccin-mocha', 'catpuccin': 'catppuccin-mocha',
           'evergreen': 'everforest', 'tokyonight': 'tokyo-night'}
ROLES = 'bg surface raised muted fg accent secondary red green yellow magenta cyan orange'.split()


def palettes():
    return {p.stem: p for directory in (ROOT / 'palettes', ROOT / 'themes')
            for p in sorted(directory.glob('*.json'))}


def load(slug):
    slug = ALIASES.get(slug, slug)
    if slug not in palettes():
        raise ValueError(f'Unknown theme {slug!r}. Use theme-switch --list.')
    p = json.loads(palettes()[slug].read_text())
    if not isinstance(p, dict):
        raise ValueError('A theme palette must be a JSON object.')
    if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', slug):
        raise ValueError('Theme filenames must use lowercase letters, digits and hyphens.')
    if not isinstance(p.get('name'), str) or any(c in p['name'] for c in '\n\r\0'):
        raise ValueError('Theme needs a single-line name.')
    if p.get('variant') not in ('light', 'dark'):
        raise ValueError('variant must be light or dark.')
    colors = p.get('colors', {})
    if not isinstance(colors, dict) or not isinstance(p.get('ansi'), list):
        raise ValueError('colors must be an object and ansi must be an array.')
    values = [colors.get(k, '') for k in ROLES] + p.get('ansi', [])
    if len(p.get('ansi', [])) != 16 or not all(isinstance(v, str) and re.fullmatch(r'#[0-9a-fA-F]{6}', v) for v in values):
        raise ValueError(f'{slug}: supply all colour roles and exactly 16 ANSI #RRGGBB colours.')
    p['id'] = slug
    return p


def read_json(path, default=None):
    return json.loads(path.read_text()) if path.exists() else ({} if default is None else default)


def selected():
    return read_json(CURRENT / 'theme.json').get('id', 'nord')


def run(*args, check=False):
    if not shutil.which(args[0]):
        if check:
            raise ValueError(f'Missing dependency: {args[0]}')
        return None
    try:
        result = subprocess.run(args, text=True, capture_output=True, timeout=12)
    except subprocess.TimeoutExpired:
        if check:
            raise ValueError(f'{args[0]} timed out.') from None
        warn(f'{args[0]} timed out; reopen the app to load its theme.')
        return None
    if check and result.returncode:
        raise ValueError(result.stderr.strip() or f'{args[0]} failed.')
    return result


def warn(message):
    print(f'theme-switch: {message}', file=sys.stderr)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def atomic_write(path, data):
    # Resolve Stow links: replacing the link itself would silently unmanage it.
    path = path.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix='.' + path.name, dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(data)
        os.chmod(name, path.stat().st_mode & 0o777 if path.exists() else 0o600)
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def point(path, target):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and not path.is_symlink():
        raise ValueError(f'{path} must be a symlink, not an existing file/directory.')
    temporary = path.with_name('.' + path.name + '-' + str(os.getpid()))
    temporary.symlink_to(target)
    try:
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def mix(a, b, amount):
    return '#' + ''.join(f'{round(int(a[i:i+2],16)*(1-amount)+int(b[i:i+2],16)*amount):02x}' for i in (1, 3, 5))


def recolor(text, c):
    """Keep Nordic widget geometry; translate its base colours and derived shades."""
    anchors = {'#2e3440': c['bg'], '#3b4252': c['surface'], '#434c5e': c['raised'],
               '#4c566a': c['muted'], '#d8dee9': c['fg'], '#e5e9f0': c['fg'], '#eceff4': c['fg'],
               '#81a1c1': c['accent'], '#5e81ac': c['accent'], '#8fbcbb': c['secondary'],
               '#88c0d0': c['cyan'], '#bf616a': c['red'], '#a3be8c': c['green'],
               '#ebcb8b': c['yellow'], '#b48ead': c['magenta'], '#d08770': c['orange']}
    def replace(match):
        color = match[0].lower()
        if len(color) == 4:
            color = '#' + ''.join(x * 2 for x in color[1:])
        if color in anchors:
            return anchors[color]
        rgb = [int(color[i:i+2], 16) for i in (1, 3, 5)]
        def distance(base):
            return sum((v-int(base[i:i+2],16))**2 for v,i in zip(rgb,(1,3,5)))
        base = min(anchors, key=distance)
        return anchors[base]
    text = re.sub(r'#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b', replace, text)
    def replace_rgb(match):
        original = '#' + ''.join(f'{int(match[i]):02x}' for i in (2, 3, 4))
        converted = replace(re.match(r'.+', original))
        components = ', '.join(str(int(converted[i:i+2],16)) for i in (1,3,5))
        return match[1] + '(' + components + (match[5] or '') + ')'
    return re.sub(r'\b(rgba?)\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(,\s*[\d.]+\s*)?\)', replace_rgb, text)


def render(p, dest, wallpaper):
    c = p['colors']
    tokens = {**c, 'theme_id': p['id'], 'variant': p['variant'],
              'dark': str(int(p['variant'] == 'dark')),
              'workspace_start': '#5e81ac' if p['id'] == 'nord' else mix(c['accent'], c['bg'], .18),
              'gtk_theme': 'Kiwidots', 'wallpaper': str(wallpaper),
              **{f'color{i}': v for i, v in enumerate(p['ansi'])}}
    tokens.update({k + '_hex': v[1:] for k, v in c.items()})
    tokens.update({k + '_rgb': ', '.join(str(int(v[i:i+2], 16)) for i in (1,3,5)) for k,v in c.items()})
    for template in (ROOT / 'templates').iterdir():
        text = re.sub(r'\{\{(\w+)\}\}', lambda m: tokens.get(m[1], m[0]), template.read_text())
        write(dest / template.name, text)
    base = ROOT / 'templates/dunstrc'
    write(dest / 'dunstrc', recolor(base.read_text(), c))
    qt_roles = ['fg','surface','surface','raised','raised','muted','fg','fg','fg','bg',
                'bg','raised','accent','bg','cyan','magenta','surface','fg','surface','fg','fg']
    active = ', '.join(c[role] for role in qt_roles)
    disabled = ', '.join(c['muted'] if role == 'fg' else c[role] for role in qt_roles)
    write(dest / 'qt.colors', '[ColorScheme]\nactive_colors='+active+'\ninactive_colors='+active+'\ndisabled_colors='+disabled+'\n')
    write(dest / 'theme.json', json.dumps(p, indent=2) + '\n')
    (dest / 'wallpaper').symlink_to(wallpaper)
    # Keep the existing, GPL-licensed GTK widgets and their local assets.
    nordic = ROOT.parent.parent / '.themes/Nordic-darker'
    for version in ('gtk-2.0', 'gtk-3.0', 'gtk-4.0'):
        source = nordic / version
        for source_file in source.rglob('*'):
            if source_file.is_file() and (source_file.suffix in ('.css', '.rc') or source_file.name == 'gtkrc'):
                relative = source_file.relative_to(nordic)
                text = source_file.read_text()
                if p['id'] != 'nord':
                    text = recolor(text, c)
                write(dest / 'gtk' / relative, text)
        for name in ('assets',):
            if (source / name).exists():
                (dest / 'gtk' / version / name).symlink_to(source / name, target_is_directory=True)
    (dest / 'gtk/assets').symlink_to(nordic / 'assets', target_is_directory=True)
    write(dest / 'gtk/index.theme', '[Desktop Entry]\nType=X-GNOME-Metatheme\nName=Kiwidots\n[X-GNOME-Metatheme]\nGtkTheme=Kiwidots\n')
    scopes = [('comment', c['muted']), ('string', c['green']), ('constant.numeric', c['orange']),
              ('keyword, storage', c['magenta']), ('entity.name.function, support.function', c['accent']),
              ('entity.name.type, support.type', c['yellow']), ('variable', c['fg']),
              ('invalid', c['red']), ('markup.inserted', c['green']), ('markup.deleted', c['red']),
              ('markup.heading', c['accent']), ('constant.language', c['orange'])]
    tmtheme = {'name': 'Kiwidots', 'settings': [{'settings': {'background': c['bg'], 'foreground': c['fg'],
                 'caret': c['accent'], 'selection': c['raised'], 'lineHighlight': c['surface']}}] +
               [{'scope': scope, 'settings': {'foreground': color}} for scope, color in scopes]}
    (dest / 'kiwidots.tmTheme').write_bytes(plistlib.dumps(tmtheme))
    mapping = {'claude':'accent', 'text':'fg', 'inverseText':'bg', 'inactive':'muted', 'subtle':'raised',
               'suggestion':'accent', 'permission':'secondary', 'remember':'magenta', 'success':'green',
               'error':'red', 'warning':'yellow', 'merged':'magenta', 'promptBorder':'accent',
               'planMode':'cyan', 'autoAccept':'green', 'bashBorder':'orange', 'ide':'cyan',
               'fastMode':'yellow', 'userMessageBackground':'surface', 'selectionBg':'raised',
               'composerSidebarBackground':'surface', 'rate_limit_fill':'accent', 'rate_limit_empty':'raised'}
    overrides = {key:c[value] for key,value in mapping.items()}
    for key in ('claude','warning','permission','promptBorder','inactive','fastMode'):
        overrides[key + 'Shimmer'] = mix(overrides[key], c['fg'], .3)
    for key, role in [('diffAdded','green'), ('diffRemoved','red'), ('diffAddedWord','green'), ('diffRemovedWord','red')]:
        overrides[key] = mix(c['bg'], c[role], .25 if key.endswith('Word') else .12)
    write(dest / 'claude.json', json.dumps({'name':'Desktop theme', 'base':p['variant'], 'overrides':overrides}, indent=2)+'\n')


def set_toml_theme(text):
    """Edit just tui.theme, preserving comments, credentials and every other table."""
    data = tomllib.loads(text)
    if 'tui' in data and not isinstance(data['tui'], dict):
        raise ValueError('Codex tui must be a table.')
    # Inline tables and quoted table headers need a TOML writer; refuse to corrupt them.
    if re.search(r'^\s*tui\s*=\s*\{', text, re.M):
        raise ValueError('Expand the inline Codex tui table to [tui] before switching.')
    if re.search(r'^\s*tui\.theme\s*=', text, re.M):
        updated = re.sub(r'^(\s*tui\.theme\s*=)[^\n]*', r'\1 "kiwidots"', text, count=1, flags=re.M)
    else:
        header = re.search(r'^\[tui\]\s*(?:#.*)?$', text, re.M)
        if header:
            end = re.search(r'^\[', text[header.end():], re.M)
            stop = header.end() + end.start() if end else len(text)
            block = text[header.end():stop]
            if re.search(r'^\s*theme\s*=', block, re.M):
                block = re.sub(r'^(\s*theme\s*=)[^\n]*', r'\1 "kiwidots"', block, count=1, flags=re.M)
            else:
                block = '\ntheme = "kiwidots"\n' + block
            updated = text[:header.end()] + block + text[stop:]
        else:
            updated = text.rstrip() + '\n\n[tui]\ntheme = "kiwidots"\n'
    parsed = tomllib.loads(updated)
    expected = copy.deepcopy(data)
    expected.setdefault('tui', {})['theme'] = 'kiwidots'
    if parsed != expected:
        raise ValueError('Cannot safely update Codex tui.theme.')
    return updated


def settings_updates(p):
    """Validate shared settings before changing any files. No whole-file templates."""
    updates = {}
    codex = Path(os.environ.get('CODEX_HOME', HOME / '.codex'))
    claude = Path(os.environ.get('CLAUDE_CONFIG_DIR', HOME / '.claude'))
    path = codex / 'config.toml'
    updates[path] = set_toml_theme(path.read_text() if path.exists() else '').encode()
    path = claude / 'settings.json'
    data = read_json(path)
    if not isinstance(data, dict):
        raise ValueError('Claude settings.json must contain an object.')
    data['theme'] = 'custom:kiwidots'
    updates[path] = (json.dumps(data, indent=2) + '\n').encode()
    for version in ('5', '6'):
        path = CONFIG / f'qt{version}ct/qt{version}ct.conf'
        settings = configparser.ConfigParser(interpolation=None)
        settings.optionxform = str
        if path.exists():
            settings.read_string(path.read_text())
        if not settings.has_section('Appearance'):
            settings.add_section('Appearance')
        for key, value in {'color_scheme_path':str(CURRENT/'qt.colors'),
                           'custom_palette':'true', 'style':'Fusion'}.items():
            settings.set('Appearance', key, value)
        output = io.StringIO()
        settings.write(output)
        updates[path] = output.getvalue().encode()
    spotify = CONFIG/'spicetify/config-xpui.ini'
    if spotify.exists():
        settings = configparser.ConfigParser(interpolation=None)
        settings.read_string(spotify.read_text())
        if settings.get('Setting','current_theme',fallback='') == 'text':
            colors = CONFIG/'spicetify/Themes/text/color.ini'
            if colors.exists():
                scheme = configparser.ConfigParser(interpolation=None)
                scheme.read_string(colors.read_text())
                c = p['colors']
                roles = {'accent':'accent', 'accent-active':'secondary', 'accent-inactive':'surface',
                         'banner':'accent', 'border-active':'accent', 'border-inactive':'raised',
                         'header':'muted', 'highlight':'raised', 'main':'bg', 'notification':'cyan',
                         'notification-error':'red', 'subtext':'muted', 'text':'fg'}
                scheme['Kiwidots'] = {key:c[role][1:] for key,role in roles.items()}
                output = io.StringIO()
                scheme.write(output)
                updates[colors] = output.getvalue().encode()
                settings.set('Setting','color_scheme','Kiwidots')
                output = io.StringIO()
                settings.write(output)
                updates[spotify] = output.getvalue().encode()
    return updates, codex, claude


def backup(path):
    # Backups may contain private settings, so they live outside the checkout, mode 0600.
    destination = STATE / 'backups' / path.relative_to(HOME) if path.is_relative_to(HOME) else STATE / 'backups/external' / str(path).lstrip('/')
    if path.exists() and not destination.exists():
        atomic_write(destination, path.read_bytes())
        destination.chmod(0o600)


def wallpaper_for(p, override=None):
    prefs = read_json(STATE / 'wallpapers.json')
    path = Path(override).expanduser().resolve() if override else Path(prefs.get(p['id'], ROOT / 'wallpapers' / (p['id']+'.png')))
    if not path.is_file() or path.suffix.lower() not in ('.png','.jpg','.jpeg','.webp'):
        raise ValueError(f'Wallpaper missing or unsupported: {path}. Supply a PNG, JPG or WebP with --wallpaper.')
    return path


def wallpaper_apply():
    wallpaper = CURRENT / 'wallpaper'
    if not wallpaper.exists():
        return
    result = run('awww', 'query')
    # Session startup launches the daemon in parallel; wait briefly for its socket.
    for _ in range(15):
        if result is None or result.returncode == 0:
            break
        time.sleep(.1)
        result = run('awww', 'query')
    if result is not None and result.returncode == 0:
        result = run('awww', 'img', str(wallpaper.resolve()), '--transition-type', 'grow', '--transition-pos', '0.65,0.65', '--transition-duration', '0.6')
        if result and result.returncode:
            warn('awww could not apply the wallpaper: ' + result.stderr.strip())
    else:
        warn('awww daemon unavailable; wallpaper will apply at next login.')


def reload_apps(p):
    if os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):
        result = run('hyprctl', 'reload')
        if result and result.returncode:
            warn('Hyprland reload failed: '+result.stderr.strip())
    # Kitty reloads all its normal options as well as the new palette, across instances.
    run('pkill', '-USR1', '-u', str(os.getuid()), '-x', 'kitty')
    run('pkill', '-USR2', '-u', str(os.getuid()), '-x', 'waybar')
    run('dunstctl', 'reload', str(CURRENT / 'dunstrc'))
    run('tmux', 'source-file', str(CURRENT / 'tmux.conf'))
    run('gsettings', 'set', 'org.gnome.desktop.interface', 'gtk-theme', 'Kiwidots')
    run('gsettings', 'set', 'org.gnome.desktop.interface', 'color-scheme', 'prefer-'+p['variant'])
    # XSettings can be overridden without rewriting the user's base file.
    run('pkill', '-HUP', '-u', str(os.getuid()), '-x', 'xsettingsd')
    spotify = CONFIG/'spicetify/config-xpui.ini'
    if spotify.exists():
        settings = configparser.ConfigParser(interpolation=None)
        settings.read_string(spotify.read_text())
        if settings.get('Setting','current_theme',fallback='') == 'text' and shutil.which('spicetify'):
            result = run('spicetify','--no-restart','apply')
            if result is None or result.returncode:
                warn('Spotify theme saved; Spicetify apply failed. Run spicetify backup apply after a Spotify update.')
    wallpaper_apply()


def apply(p, wallpaper, no_reload=False):
    _, codex, claude = settings_updates(p)
    # Validate all link destinations before touching shared configuration.
    links = {CURRENT: None, codex/'themes/kiwidots.tmTheme': CURRENT/'kiwidots.tmTheme',
             HOME/'.themes/Kiwidots': CURRENT/'gtk'}
    for path in links:
        if path.exists() and not path.is_symlink():
            raise ValueError(f'Refusing to replace {path}; move it aside first.')
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    STATE.chmod(0o700)
    with (STATE / 'switch.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        updates, codex, claude = settings_updates(p)
        generations = STATE / 'generations'
        generations.mkdir(exist_ok=True)
        generation = Path(tempfile.mkdtemp(prefix=p['id']+'-', dir=generations))
        try:
            render(p, generation, wallpaper)
            old = CURRENT.resolve() if CURRENT.exists() else None
            updates[claude/'themes/kiwidots.json'] = (generation/'claude.json').read_bytes()
            before = {path: path.read_bytes() if path.exists() else None for path in updates}
            old_links = {path: os.readlink(path) if path.is_symlink() else None for path in links}
            try:
                for path, content in updates.items():
                    backup(path)
                    atomic_write(path, content)
                for path, target in links.items():
                    if target:
                        point(path, target)
                point(CURRENT, generation)
            except Exception:
                for path, content in before.items():
                    if content is None:
                        path.unlink(missing_ok=True)
                    else:
                        atomic_write(path, content)
                for path, target in old_links.items():
                    if target is None:
                        path.unlink(missing_ok=True)
                    else:
                        point(path, target)
                raise
            if old and old.is_dir() and old.parent == generations and read_json(old/'theme.json').get('id') != p['id']:
                point(STATE/'previous', old)
            prefs = read_json(STATE/'wallpapers.json')
            prefs[p['id']] = str(wallpaper)
            atomic_write(STATE/'wallpapers.json', (json.dumps(prefs,indent=2)+'\n').encode())
            keep = {CURRENT.resolve(), (STATE/'previous').resolve()}
            for directory in generations.iterdir():
                if directory.is_dir() and not directory.is_symlink() and directory not in keep:
                    shutil.rmtree(directory)
        except Exception:
            if CURRENT.resolve() != generation:
                shutil.rmtree(generation)
            raise
    if not no_reload:
        reload_apps(p)
    print(f"Applied {p['name']}. Reopen Codex/Claude to load their selected theme; Neovim updates on focus.")


def pick():
    choices = [(slug, load(slug)) for slug in palettes()]
    active = selected()
    labels = [p['name'] + ('  • current' if slug == active else '') for slug,p in choices]
    result = subprocess.run(['rofi','-dmenu','-i','-no-custom','-format','i','-p','Theme',
                             '-selected-row',str([s for s,_ in choices].index(active) if active in palettes() else 0),
                             '-theme',str(ROOT/'picker.rasi')], input='\n'.join(labels), text=True, capture_output=True)
    if result.returncode == 1:
        return None
    if result.returncode:
        raise ValueError(result.stderr.strip() or 'Rofi could not open the theme picker.')
    return choices[int(result.stdout.strip())][0]


def pick_wallpaper(p):
    paths = [ROOT/'wallpapers'/(p['id']+'.png')]
    paths += sorted((ROOT/'themes'/p['id']/'wallpapers').glob('*'))
    if p['id'] == 'nord':
        paths += sorted((CONFIG/'hypr/wallpapers/current').glob('*'))
    paths = [path for path in paths if path.is_file() and path.suffix.lower() in ('.png','.jpg','.jpeg','.webp')]
    entries = [f'{path.stem}\0icon\x1f{path}\n' for path in paths]
    result = subprocess.run(['rofi','-dmenu','-i','-no-custom','-format','i','-p',p['name']+' wallpaper',
                             '-theme',str(CONFIG/'rofi/wallpaper.rasi')], input=''.join(entries), text=True,capture_output=True)
    if result.returncode == 1:
        return None
    if result.returncode:
        raise ValueError(result.stderr.strip() or 'Rofi could not open the wallpaper picker.')
    return paths[int(result.stdout.strip())]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('theme', nargs='?', help='Theme slug; no argument opens Rofi.')
    group = parser.add_mutually_exclusive_group()
    for flag, help_text in [('list','List installed themes'), ('current','Print the current theme'),
                            ('init','Initialize Nord only if no theme is active'),
                            ('restore','Restore the saved theme at login'), ('previous','Switch to the previous theme'),
                            ('wallpapers','Pick a wallpaper for the active theme'), ('apply-wallpaper','Reapply wallpaper after monitor hotplug')]:
        group.add_argument('--'+flag, action='store_true', help=help_text)
    parser.add_argument('--wallpaper', type=Path, help='Remember a wallpaper for this theme')
    parser.add_argument('--dry-run', action='store_true', help='Validate and list changes without writing or reloading')
    parser.add_argument('--no-reload', action='store_true', help='Save files without contacting running apps')
    args = parser.parse_args()
    if args.list:
        for slug in palettes():
            print(f"{slug:24} {load(slug)['name']}")
        return
    if args.current:
        print(selected())
        return
    if args.apply_wallpaper:
        if not args.dry_run and not args.no_reload:
            wallpaper_apply()
        return
    if args.init and CURRENT.exists() and CURRENT.resolve().parent == STATE/'generations':
        return
    slug = args.theme
    if args.previous:
        previous = STATE/'previous/theme.json'
        if not previous.exists():
            raise ValueError('No previous theme yet.')
        slug = read_json(previous)['id']
    elif args.restore or args.wallpapers or args.wallpaper:
        slug = slug or selected()
    elif args.init:
        slug = 'nord'
    elif not slug:
        if args.dry_run:
            slug = selected()
        elif not shutil.which('rofi'):
            raise ValueError('Rofi is unavailable. Pass a theme name; use --list for choices.')
        else:
            slug = pick()
            if slug is None:
                return
    p = load(slug)
    override = args.wallpaper
    if args.wallpapers and not args.dry_run:
        override = pick_wallpaper(p)
        if override is None:
            return
    wallpaper = wallpaper_for(p, override)
    if args.dry_run:
        settings_updates(p)
        print(f"Would apply {p['name']} using {wallpaper}\nKitty, Hyprland, Hyprlock, Waybar, Rofi, Dunst, GTK 2/3/4, Qt 5/6, tmux, Zsh, Neovim, Codex and Claude.\nSpotify follows when Spicetify's text theme is configured.\nNo files or running apps changed.")
        return
    apply(p, wallpaper, args.no_reload or args.init)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, IndexError, configparser.Error, subprocess.SubprocessError) as error:
        warn(str(error))
        if len(sys.argv) == 1 or sys.argv[1:] == ['--wallpapers']:
            run('notify-send', '-u', 'critical', 'Theme switch failed', str(error))
        sys.exit(1)
