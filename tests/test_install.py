"""Run with python -m unittest discover -s tests; never changes the host desktop."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
ARCH = Path('/etc/arch-release').exists()


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kiwidots-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / 'relocated checkout'
        self.home = self.root / 'home with spaces'
        self.bin = self.root / 'bin'
        for directory in [self.repo / 'scripts', self.repo / 'desktop', self.home, self.bin]:
            directory.mkdir(parents=True)
        shutil.copy(REPO / 'install.sh', self.repo)
        shutil.copy(REPO / 'scripts/setup-desktop.sh', self.repo / 'scripts')
        shutil.copy(REPO / 'desktop/packages.txt', self.repo / 'desktop')
        config = self.repo / 'config/.config/demo'
        config.mkdir(parents=True)
        (config / 'settings').write_text('tracked settings\n')
        (self.repo / 'system').mkdir()
        self.log = self.root / 'calls.jsonl'
        self.env = {
            **os.environ,
            'HOME': str(self.home),
            'PATH': str(self.bin) + ':' + os.environ['PATH'],
            'TEST_LOG': str(self.log),
            'REAL_STOW': shutil.which('stow'),
        }
        stub = '''#!/usr/bin/python3
import json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['TEST_LOG'], 'a') as log:
    log.write(json.dumps([name, *args]) + '\\n')
if name == 'stow':
    if '--target=/' in args:
        sys.exit(1 if os.environ.get('SYSTEM_CONFLICT') else 0)
    os.execv(os.environ['REAL_STOW'], [os.environ['REAL_STOW'], *args])
if name == 'curl':
    pathlib.Path(args[args.index('--output') + 1]).write_bytes(b'corrupt download')
if name == 'systemctl' and args[0] == 'is-enabled':
    sys.exit(0 if os.environ.get('OTHER_NETWORK_MANAGER') else 1)
if name == 'systemctl' and '--user' in args and os.environ.get('SYSTEMD_OFFLINE') != '1':
    sys.exit(42)
'''
        for name in ['stow', 'sudo', 'systemctl', 'curl']:
            self.executable(self.bin / name, stub)
        self.executable(self.repo / 'scripts/setup-spicetify.sh', stub)

    @staticmethod
    def executable(path, text):
        path.write_text(text)
        path.chmod(0o755)

    def run_install(self, *args, **env):
        return subprocess.run(
            ['bash', str(self.repo / 'install.sh'), *args],
            cwd=self.root,
            env={**self.env, **env},
            text=True,
            capture_output=True,
        )

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_default_home_install_relocated_and_repeatable(self):
        for _ in range(2):
            result = self.run_install()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / '.config/demo/settings').read_text(), 'tracked settings\n')
        self.assertFalse(any(call[0] == 'sudo' for call in self.calls()))

    def test_dry_run_does_not_create_files_or_use_sudo(self):
        result = self.run_install('--home', '--system', '--spicetify', '--dry-run')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertTrue(all(call[0] == 'stow' and '--simulate' in call for call in self.calls()))

    def test_home_conflict_keeps_existing_file_and_stops_before_sudo(self):
        path = self.home / '.config/demo/settings'
        path.parent.mkdir(parents=True)
        path.write_text('keep me')
        result = self.run_install('--home', '--system')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(path.read_text(), 'keep me')
        self.assertTrue(all(call[0] == 'stow' and '--simulate' in call for call in self.calls()))

    def test_system_conflict_prevents_home_changes(self):
        result = self.run_install('--home', '--system', SYSTEM_CONFLICT='1')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertEqual(len(self.calls()), 2)
        self.assertTrue(all('--simulate' in call for call in self.calls()))

    def test_system_only_and_spicetify_only_are_independent(self):
        result = self.run_install('--system')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertFalse(any('--target=' + str(self.home) in call for call in self.calls()))
        self.log.unlink()
        result = self.run_install('--spicetify')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [['setup-spicetify.sh']])

    def test_invalid_option_and_help(self):
        self.assertEqual(self.run_install('--unknown').returncode, 2)
        self.assertEqual(self.run_install('--help').returncode, 0)
        self.assertEqual(self.calls(), [])

    @unittest.skipUnless(ARCH, 'Arch-specific desktop mode')
    def test_desktop_preview_never_installs_or_enables_anything(self):
        result = self.run_install('--desktop', '--dry-run')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('hyprland', result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertTrue(all(call[0] == 'stow' and '--simulate' in call for call in self.calls()))
        self.assertTrue(any(arg.startswith('--ignore=') and 'ly' in arg for arg in self.calls()[-1]))

    @unittest.skipUnless(ARCH, 'Arch-specific desktop mode')
    def test_desktop_prepares_real_runtime_directories_before_linking(self):
        for name in ['.config/systemd/user/battery_notify.timer', '.local/share/icons/default/index.theme']:
            path = self.repo / 'config' / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('tracked')
        # Stop after Stow: test the orchestration without configuring a live desktop.
        self.executable(self.repo / 'scripts/setup-desktop.sh', '#!/bin/sh\nexit 0\n')
        result = self.run_install('--desktop')
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in ['.config/systemd/user', '.config/zsh', '.local/share/icons']:
            path = self.home / name
            self.assertTrue(path.is_dir())
            self.assertFalse(path.is_symlink(), name)
        calls = self.calls()
        self.assertEqual(calls[0][0], 'stow')
        self.assertIn('--simulate', calls[0])
        self.assertIn('--simulate', calls[1])

    @unittest.skipUnless(ARCH, 'Arch-specific desktop mode')
    def test_package_install_uses_system_upgrade_and_curated_list(self):
        result = subprocess.run(
            [str(self.repo / 'scripts/setup-desktop.sh'), '--packages'],
            env=self.env, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        call, = self.calls()
        self.assertEqual(call[:5], ['sudo', 'pacman', '-Syu', '--needed', '--'])
        self.assertIn('wiremix', call)
        self.assertNotIn('chromium', call)
        self.assertNotIn('neovim', call)

    @unittest.skipUnless(ARCH, 'Arch-specific desktop mode')
    def test_corrupt_cursor_download_is_rejected_before_installation(self):
        result = subprocess.run(
            [str(self.repo / 'scripts/setup-desktop.sh'), '--configure'],
            env=self.env, capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / '.local/share/icons/Bibata-Modern-Classic').exists())
        self.assertEqual([call[0] for call in self.calls()], ['curl'])

    @unittest.skipUnless(ARCH, 'Arch-specific desktop mode')
    def test_existing_assets_are_kept_and_services_are_only_enabled(self):
        for name in ['.local/share/icons/Bibata-Modern-Classic/index.theme', '.config/zsh/znap/znap.zsh']:
            path = self.home / name
            path.parent.mkdir(parents=True)
            path.write_text('existing')
        binary = self.home / '.local/bin/oh-my-posh'
        binary.parent.mkdir(parents=True)
        self.executable(binary, '#!/bin/sh\nexit 0\n')
        for _ in range(2):
            result = subprocess.run(
                [str(self.repo / 'scripts/setup-desktop.sh'), '--configure'],
                env=self.env, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(all(call[0] in ['sudo', 'systemctl'] for call in self.calls()))
        self.assertFalse(any('--now' in call or 'restart' in call for call in self.calls()))
        self.assertEqual((self.home / '.config/zsh/znap/znap.zsh').read_text(), 'existing')
        self.log.unlink()
        result = subprocess.run(
            [str(self.repo / 'scripts/setup-desktop.sh'), '--configure'],
            env={**self.env, 'OTHER_NETWORK_MANAGER': '1'}, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Manual step:', result.stdout)
        self.assertFalse(any(call[:3] == ['sudo', 'systemctl', 'enable'] and 'NetworkManager.service' in call for call in self.calls()))

    def test_full_home_package_has_working_gtk_and_shell_links(self):
        subprocess.run(
            [self.env['REAL_STOW'], '--dir=' + str(REPO), '--target=' + str(self.home), 'config'],
            check=True, capture_output=True, text=True, env=self.env,
        )
        for name in ['.config/gtk-4.0/gtk.css', '.config/gtk-4.0/gtk-dark.css', '.config/assets', '.zshrc']:
            self.assertTrue((self.home / name).exists(), name)
        theme = self.home / '.themes/Nordic-darker'
        self.assertTrue((theme / 'LICENSE').exists())
        for path in theme.rglob('*'):
            if path.is_symlink():
                self.assertTrue(path.exists(), str(path))


if __name__ == '__main__':
    unittest.main()
