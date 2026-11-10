#!/usr/bin/env python3
"""Connect the theme switcher on an existing Stow desktop; back up replaced GTK files."""
import argparse
import importlib.util
import os
from pathlib import Path
import subprocess
import sys

REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO / 'config'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--dry-run', action='store_true')
args = parser.parse_args()
home = Path.home()
config = Path(os.environ.get('XDG_CONFIG_HOME', home/'.config'))
engine = SOURCE / '.config/desktop-theme/engine.py'
spec = importlib.util.spec_from_file_location('desktop_theme', engine)
theme = importlib.util.module_from_spec(spec)
spec.loader.exec_module(theme)
links = {config/'desktop-theme': SOURCE/'.config/desktop-theme',
         home/'.local/bin/theme-switch': engine}
for name in ('.gtkrc-2.0', '.config/gtk-3.0/settings.ini', '.config/gtk-4.0/settings.ini',
             '.config/gtk-4.0/gtk.css', '.config/gtk-4.0/gtk-dark.css', '.config/xsettingsd/xsettingsd.conf'):
    target = config / name.removeprefix('.config/') if name.startswith('.config/') else home/name
    links[target] = SOURCE/name
for destination, source in links.items():
    if destination.resolve() == source.resolve():
        continue
    if destination.exists() or destination.is_symlink():
        if destination in (config/'desktop-theme',home/'.local/bin/theme-switch'):
            sys.exit(f'Conflict: {destination}; move it aside first. Nothing changed.')
        if destination.is_dir():
            sys.exit(f'Expected a file: {destination}. Nothing changed.')
if args.dry_run:
    for destination, source in links.items():
        print(f'Would link {destination} -> {source}; existing GTK files get private backups.')
    sys.exit(0)
# Generate before replacing GTK links, then install only the new switcher and GTK links.
subprocess.run([sys.executable, str(engine), '--init'], check=True)
for destination, source in links.items():
    if destination.resolve() == source.resolve():
        continue
    if destination.exists():
        theme.backup(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.is_symlink() or destination.exists():
        destination.unlink()
    destination.symlink_to(source)
print('Theme switcher linked. Run theme-switch nord to refresh the current session.')
