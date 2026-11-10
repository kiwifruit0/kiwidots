"""Theme integration checks in a temporary home; never signal the host desktop."""
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import tomllib
import unittest
import struct
import zlib
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO/'config/.config/desktop-theme'


class ThemeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kiwidots-theme-test-')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)/'home with spaces'
        self.config = self.home/'.config'
        self.root = self.config/'desktop-theme'
        shutil.copytree(SOURCE, self.root, ignore=shutil.ignore_patterns('current','__pycache__'))
        shutil.copytree(REPO/'config/.themes/Nordic-darker', self.home/'.themes/Nordic-darker')
        shutil.copytree(REPO/'config/.config/dunst', self.config/'dunst')
        self.state = self.home/'.local/state/kiwidots-theme'
        self.env = {**os.environ, 'HOME':str(self.home), 'XDG_CONFIG_HOME':str(self.config),
                    'XDG_STATE_HOME':str(self.home/'.local/state'), 'CODEX_HOME':str(self.home/'.codex'),
                    'CLAUDE_CONFIG_DIR':str(self.home/'.claude')}
        self.original_codex = '# personal settings\nmodel = "keep-this"\n[tui]\nnotifications = true\ntheme = "nord"\n[projects."/work"]\ntrust_level = "trusted"\n'
        self.put('.codex/config.toml', self.original_codex)
        self.put('.claude/settings.json', '{"permissions":{"allow":["Read"]}, "model":"keep-this"}\n')
        self.put('.config/qt5ct/qt5ct.conf', '[Appearance]\nicon_theme=Papirus\n[Fonts]\ngeneral=Custom Font\n')

    def put(self, name, text):
        path = self.home/name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def run_theme(self, *args):
        return subprocess.run(['python3',str(self.root/'engine.py'),*args],env=self.env,capture_output=True,text=True)

    def apply(self, *args):
        result = self.run_theme(*args,'--no-reload')
        self.assertEqual(result.returncode,0,result.stderr)
        return result

    def current(self):
        return self.root/'current'

    def test_all_presets_render_native_configs_and_wallpapers(self):
        for palette in sorted((self.root/'palettes').glob('*.json')):
            with self.subTest(palette=palette.stem):
                self.apply(palette.stem)
                p=json.loads((self.current()/'theme.json').read_text())
                self.assertEqual(p['id'],palette.stem)
                self.assertIn(p['colors']['bg'],(self.current()/'kitty.conf').read_text())
                self.assertIn(p['colors']['accent'],(self.current()/'rofi.rasi').read_text())
                self.assertIn(p['colors']['fg'],(self.current()/'waybar.css').read_text())
                self.assertTrue((self.current()/'wallpaper').read_bytes().startswith(b'\x89PNG'))
                image=(self.current()/'wallpaper').read_bytes()
                width,height=struct.unpack('!II',image[16:24])
                offset,compressed=8,b''
                while offset<len(image):
                    size=struct.unpack('!I',image[offset:offset+4])[0]
                    if image[offset+4:offset+8]==b'IDAT':
                        compressed+=image[offset+8:offset+8+size]
                    offset+=size+12
                raw=zlib.decompress(compressed)
                self.assertEqual(len(raw),height*(1+width*3))
                self.assertEqual(set(raw[::1+width*3]),{0})
                self.assertEqual(len(plistlib.loads((self.current()/'kiwidots.tmTheme').read_bytes())['settings']),13)
                tomllib.loads((self.current()/'prompt.toml').read_text())
                self.assertIn('gtk-theme-name=Kiwidots',(self.current()/'gtk-4-settings.ini').read_text())
                self.assertTrue((self.current()/'gtk/assets').is_dir())
        self.assertLessEqual(len(list((self.state/'generations').iterdir())),2)

    def test_preserves_preferences_and_private_backups(self):
        self.apply('dracula')
        data=tomllib.loads((self.home/'.codex/config.toml').read_text())
        self.assertEqual(data['model'],'keep-this')
        self.assertEqual(data['projects']['/work']['trust_level'],'trusted')
        self.assertTrue(data['tui']['notifications'])
        self.assertEqual(data['tui']['theme'],'kiwidots')
        data=json.loads((self.home/'.claude/settings.json').read_text())
        self.assertEqual(data['permissions'],{'allow':['Read']})
        self.assertEqual(data['theme'],'custom:kiwidots')
        self.assertIn('general = Custom Font',(self.config/'qt5ct/qt5ct.conf').read_text())
        self.assertIn('icon_theme = Papirus',(self.config/'qt5ct/qt5ct.conf').read_text())
        backup=self.state/'backups/.codex/config.toml'
        self.assertEqual(backup.read_text(),self.original_codex)
        self.assertEqual(backup.stat().st_mode&0o777,0o600)
        self.apply('nord')
        self.assertEqual(backup.read_text(),self.original_codex)

    @unittest.skipUnless(shutil.which('kitty'), 'Kitty unavailable')
    def test_effective_kitty_tab_colors_follow_palette_after_multiplex_include(self):
        directory=self.config/'kitty'
        directory.mkdir()
        for name in ('kitty.conf','multiplex.conf'):
            shutil.copy(REPO/'config/.config/kitty'/name,directory/name)
        for slug in ('nord','dracula','catppuccin-latte'):
            self.apply(slug)
            colors=json.loads((self.current()/'theme.json').read_text())['colors']
            code=f'''
from kitty.config import load_config
o=load_config({str(directory/'kitty.conf')!r})
assert str(o.tab_bar_background)=={colors['bg']!r}, str(o.tab_bar_background)
assert str(o.tab_bar_margin_color)=={colors['bg']!r}
assert str(o.active_tab_background)=={colors['accent']!r}
assert str(o.inactive_tab_background)=={colors['bg']!r}
assert o.tab_separator == ''
assert '{{fmt.bg._{colors['surface'][1:]}}}' in o.tab_title_template
assert '{{fmt.bg._{colors['accent'][1:]}}}' in o.active_tab_title_template
from kitty.fast_data_types import Screen
from kitty.tab_bar import Formatter, ExtraData, as_rgb, draw_attributed_string, draw_tab_with_separator
from types import SimpleNamespace
from unittest.mock import patch
for template, background in ((o.tab_title_template, o.inactive_tab_background), (o.active_tab_title_template, o.active_tab_background)):
    screen=Screen(None, 1, 100, 1000)
    screen.cursor.bg=as_rgb(int(background))
    title=eval('f'+repr(template), {{'fmt':Formatter, 'title':'Tab', 'layout_name':''}})
    data=SimpleNamespace(leading_spaces=0, trailing_spaces=0, sep=o.tab_separator, inactive_bg=o.inactive_tab_background)
    with patch('kitty.tab_bar.draw_title', lambda data, s, *args, draw=draw_attributed_string, text=title: draw(text, s)):
        end=draw_tab_with_separator(data, screen, None, 0, 80, 1, False, ExtraData())
    assert str(screen.line(0))[end-1]==' '
    assert screen.line(0).cursor_from(end-1).bg==0, 'Tab gap must use the default background'
'''
            result=subprocess.run(['kitty','+runpy',code],env=self.env,capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            if slug=='nord':
                css=(self.current()/'waybar.css').read_text()
                self.assertIn('@define-color workspace_start #5e81ac;',css)
    def test_dry_run_list_and_current_write_nothing(self):
        before={p:p.read_bytes() for p in self.home.rglob('*') if p.is_file()}
        for args in [('dracula','--dry-run'),('--list',),('--current',)]:
            result=self.run_theme(*args)
            self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse(self.state.exists())
        self.assertFalse(self.current().exists())
        self.assertEqual(before,{p:p.read_bytes() for p in self.home.rglob('*') if p.is_file()})

    def test_bad_theme_palette_and_missing_wallpaper_leave_selection_unchanged(self):
        self.apply('nord')
        target=self.current().resolve()
        (self.root/'themes').mkdir()
        (self.root/'themes/broken.json').write_text('{"name":"Broken","colors":{}}')
        for args in [('not-a-theme',),('broken',),('dracula','--wallpaper','/does/not/exist.png')]:
            result=self.run_theme(*args,'--no-reload')
            self.assertNotEqual(result.returncode,0)
            self.assertEqual(self.current().resolve(),target)

    def test_corrupt_shared_settings_do_not_change_anything(self):
        self.apply('nord')
        target=self.current().resolve()
        self.put('.claude/settings.json','{bad json')
        codex=(self.home/'.codex/config.toml').read_bytes()
        result=self.run_theme('dracula','--no-reload')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(self.current().resolve(),target)
        self.assertEqual((self.home/'.codex/config.toml').read_bytes(),codex)

    def test_remembers_wallpaper_and_previous_theme_across_processes(self):
        custom=self.home/'wallpaper with spaces.png'
        shutil.copy(self.root/'wallpapers/everforest.png',custom)
        self.apply('dracula','--wallpaper',str(custom))
        self.apply('catppuccin-latte')
        self.apply('--previous')
        self.assertEqual(self.run_theme('--current').stdout.strip(),'dracula')
        self.assertEqual((self.current()/'wallpaper').resolve(),custom)
        self.apply('--restore')
        self.assertEqual(self.run_theme('--current').stdout.strip(),'dracula')
        self.apply('--init')
        self.assertEqual(self.run_theme('--current').stdout.strip(),'dracula')
        self.apply('--previous')
        self.assertEqual(self.run_theme('--current').stdout.strip(),'catppuccin-latte')

    def test_aliases_and_custom_palettes(self):
        self.apply('evergreen')
        self.assertEqual(self.run_theme('--current').stdout.strip(),'everforest')
        self.apply('catpuccin')
        self.assertEqual(self.run_theme('--current').stdout.strip(),'catppuccin-mocha')
        (self.root/'themes').mkdir()
        p=json.loads((self.root/'palettes/dracula.json').read_text())
        p['name']='My theme'
        (self.root/'themes/my-theme.json').write_text(json.dumps(p))
        self.apply('my-theme','--wallpaper',str(self.root/'wallpapers/dracula.png'))
        self.assertEqual(self.run_theme('--current').stdout.strip(),'my-theme')

    def test_atomic_write_failure_rolls_back_settings_and_links(self):
        with patch.dict(os.environ,self.env):
            spec=importlib.util.spec_from_file_location('test_engine',self.root/'engine.py')
            module=importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
        original=module.atomic_write
        calls=[]
        def fail(path,data):
            if path==self.home/'.claude/themes/kiwidots.json' and not calls:
                calls.append(path)
                raise OSError('injected disk failure')
            original(path,data)
        with patch.object(module,'atomic_write',side_effect=fail):
            with self.assertRaises(OSError):
                module.apply(module.load('dracula'),self.root/'wallpapers/dracula.png',True)
        self.assertEqual((self.home/'.codex/config.toml').read_text(),self.original_codex)
        self.assertFalse(self.current().exists())
        self.assertFalse((self.home/'.codex/themes/kiwidots.tmTheme').is_symlink())

    def test_codex_toml_forms_preserve_unrelated_tables(self):
        for text in ('model="keep"\n', 'tui.theme="nord"\nmodel="keep"\n',
                     '[tui]\nnotifications=true\n[other]\nname="theme"\n'):
            self.put('.codex/config.toml',text)
            self.apply('nord')
            data=tomllib.loads((self.home/'.codex/config.toml').read_text())
            self.assertEqual(data['tui']['theme'],'kiwidots')
        self.put('.codex/config.toml','tui = {theme="nord", notifications=true}\n')
        result=self.run_theme('dracula','--no-reload')
        self.assertNotEqual(result.returncode,0)
        self.assertIn('inline',result.stderr)

    def test_cancel_picker_is_noop(self):
        binary=self.home/'bin/rofi'
        binary.parent.mkdir()
        binary.write_text('#!/bin/sh\nexit 1\n')
        binary.chmod(0o755)
        self.env['PATH']=str(binary.parent)+':'+os.environ['PATH']
        result=self.run_theme()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse(self.current().exists())

    def test_spotify_text_scheme_keeps_extensions_and_other_schemes(self):
        self.put('.config/spicetify/config-xpui.ini','[Setting]\ncurrent_theme=text\ncolor_scheme=Nord\n[AdditionalOptions]\nextensions=keep.js\n')
        self.put('.config/spicetify/Themes/text/color.ini','[Nord]\nmain=2e3440\n')
        self.apply('dracula')
        self.assertIn('extensions = keep.js',(self.config/'spicetify/config-xpui.ini').read_text())
        self.assertIn('[Nord]',(self.config/'spicetify/Themes/text/color.ini').read_text())
        self.assertIn('main = 282a36',(self.config/'spicetify/Themes/text/color.ini').read_text())

    @unittest.skipUnless(shutil.which('nvim'), 'Neovim unavailable')
    def test_open_neovim_tracks_dark_and_light_switches(self):
        self.apply('nord')
        script=self.home/'check-neovim.lua'
        script.write_text('''
vim.opt.rtp:prepend(vim.env.TEST_NVIM_CONFIG)
require("config.desktop-theme").setup()
assert(vim.g.colors_name == "desktop")
for _, theme in ipairs({"dracula", "catppuccin-latte"}) do
  vim.fn.system({"python3", vim.env.TEST_THEME_ENGINE, theme, "--no-reload"})
  assert(vim.v.shell_error == 0)
  local fg = theme == "dracula" and 0xf8f8f2 or 0x4c4f69
  assert(vim.wait(2500, function()
    return vim.api.nvim_get_hl(0, {name="Normal"}).fg == fg
  end, 50), "Open Neovim did not refresh " .. theme)
  local colors = require("config.desktop-theme").palette()
  for group, role in pairs({ String="green", Keyword="magenta", Comment="muted", ["@function"]="accent" }) do
    assert(vim.api.nvim_get_hl(0, {name=group}).fg == tonumber(colors[role]:sub(2), 16),
      "Syntax highlight did not refresh: " .. group)
  end
  for _, group in ipairs({ "NormalFloat", "NeoTreeNormal", "NeoTreeNormalNC", "TelescopeNormal",
    "TelescopePromptNormal", "TelescopeResultsNormal", "TelescopePreviewNormal", "TelescopeBorder" }) do
    assert(vim.api.nvim_get_hl(0, {name=group, link=false}).bg == nil, "Panel background differs: " .. group)
  end
  assert(vim.o.background == (theme == "dracula" and "dark" or "light"))
end
vim.cmd.qa()
''')
        result=subprocess.run(['nvim','--headless','-u','NONE','-l',str(script)],
             env={**self.env,'TEST_NVIM_CONFIG':str(REPO/'config/.config/nvim'),
                  'TEST_THEME_ENGINE':str(self.root/'engine.py')},capture_output=True,text=True,timeout=12)
        self.assertEqual(result.returncode,0,result.stderr)

    @unittest.skipUnless(shutil.which('nvim') and (Path.home()/'.local/share/nvim/lazy/nord.nvim').is_dir(), 'Installed nord.nvim unavailable')
    def test_original_nord_syntax_and_panel_backgrounds_survive_all_themes(self):
        self.apply('nord')
        script=self.home/'check-native-nord.lua'
        script.write_text('''
vim.opt.rtp:prepend(vim.env.TEST_NVIM_CONFIG)
vim.opt.rtp:prepend(vim.env.TEST_NORD_CONFIG)
vim.g.nord_contrast = false
vim.g.nord_disable_background = true
vim.o.background = "dark"
vim.cmd.colorscheme("nord")
local original = {}
for _, group in ipairs({ "String", "Keyword", "Comment", "Function", "@function", "@variable", "@type" }) do
  original[group] = vim.api.nvim_get_hl(0, {name=group, link=false})
end
local desktop = require("config.desktop-theme")
desktop.setup()
assert(vim.g.colors_name == "nord", "Original Nord plugin was not selected")
local lualine
if vim.fn.isdirectory(vim.env.TEST_LUALINE_CONFIG) == 1 then
  vim.opt.rtp:prepend(vim.env.TEST_LUALINE_CONFIG)
  lualine = require("lualine")
  lualine.setup({ options = { theme = "auto" } })
  vim.api.nvim_exec_autocmds("FocusGained", {})
  assert(vim.api.nvim_get_hl(0, {name="lualine_c_normal"}).bg == 0x3b4252,
    "Focusing Neovim cleared the original dark Nord status line")
end
local ibl
if vim.fn.isdirectory(vim.env.TEST_IBL_CONFIG) == 1 then
  vim.opt.rtp:prepend(vim.env.TEST_IBL_CONFIG)
  ibl = require("ibl")
  ibl.setup({})
  vim.api.nvim_exec_autocmds("FocusGained", {})
  assert(vim.api.nvim_get_hl(0, {name="IblIndent"}).fg == 0x3b4252,
    "Focusing Neovim cleared the original dark Nord indent guides")
end
for _, palette in ipairs(vim.fn.glob(vim.env.TEST_PALETTE_DIR .. "/*.json", false, true)) do
  local theme = vim.fn.fnamemodify(palette, ":t:r")
  vim.fn.system({"python3", vim.env.TEST_THEME_ENGINE, theme, "--no-reload"})
  assert(vim.v.shell_error == 0)
  vim.api.nvim_exec_autocmds("FocusGained", {})
  if lualine then
    assert(vim.api.nvim_get_hl(0, {name="lualine_c_normal"}).bg ~= nil,
      "Switching on focus cleared Lualine: " .. theme)
  end
  if ibl then
    local fg = vim.api.nvim_get_hl(0, {name="IblIndent"}).fg
    assert(fg ~= nil, "Switching on focus cleared indent guides: " .. theme)
    assert(vim.api.nvim_get_hl(0, {name="@ibl.indent.char.1"}).fg == fg,
      "Rendered indent guide colour is stale: " .. theme)
  end
  for _, group in ipairs({ "Normal", "NormalFloat", "NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeFloatNormal",
    "TelescopeNormal", "TelescopePromptNormal", "TelescopeResultsNormal", "TelescopePreviewNormal",
    "TelescopeBorder", "TelescopePromptBorder", "TelescopeResultsBorder", "TelescopePreviewBorder" }) do
    assert(vim.api.nvim_get_hl(0, {name=group, link=false}).bg == nil, theme .. ": mismatched background " .. group)
  end
end
vim.fn.system({"python3", vim.env.TEST_THEME_ENGINE, "nord", "--no-reload"})
desktop.refresh(true)
assert(vim.g.colors_name == "nord")
if lualine then
  vim.api.nvim_exec_autocmds("TermLeave", {})
  assert(vim.api.nvim_get_hl(0, {name="lualine_c_normal"}).bg == 0x3b4252,
    "Returning to Nord did not restore its dark status line")
end
if ibl then
  vim.api.nvim_exec_autocmds("FocusGained", {})
  assert(vim.api.nvim_get_hl(0, {name="@ibl.indent.char.1"}).fg == 0x3b4252,
    "Returning to Nord did not restore its dark indent guides")
end
for group, highlight in pairs(original) do
  assert(vim.deep_equal(vim.api.nvim_get_hl(0, {name=group, link=false}), highlight), "Original Nord syntax changed: " .. group)
end
vim.cmd.qa()
''')
        result=subprocess.run(['nvim','--headless','-u','NONE','-l',str(script)],env={**self.env,
            'TEST_NVIM_CONFIG':str(REPO/'config/.config/nvim'),
            'TEST_NORD_CONFIG':str(Path.home()/'.local/share/nvim/lazy/nord.nvim'),
            'TEST_LUALINE_CONFIG':str(Path.home()/'.local/share/nvim/lazy/lualine.nvim'),
            'TEST_IBL_CONFIG':str(Path.home()/'.local/share/nvim/lazy/indent-blankline.nvim'),
            'TEST_THEME_ENGINE':str(self.root/'engine.py'),'TEST_PALETTE_DIR':str(self.root/'palettes')},
            capture_output=True,text=True,timeout=12)
        self.assertEqual(result.returncode,0,result.stderr)

    @unittest.skipUnless(shutil.which('oh-my-posh') and shutil.which('zsh'), 'Oh My Posh/Zsh unavailable')
    def test_existing_shell_prompt_uses_new_palette(self):
        self.apply('nord')
        source=(REPO/'config/.config/zsh/.zshrc').read_text()
        wrapper=source[source.index('_kiwidots_omp()'):source.index('_omp_executable=_kiwidots_omp')]
        code='''_theme_prompt="$HOME/.config/desktop-theme/current/prompt.toml"
eval "$(oh-my-posh init zsh --config "$_theme_prompt" --print)"
''' + wrapper + '''
_omp_executable=_kiwidots_omp
$_omp_executable print primary --shell=uni > "$HOME/before"
python3 "$TEST_THEME_ENGINE" dracula --no-reload >/dev/null
$_omp_executable print primary --shell=uni > "$HOME/after"
'''
        result=subprocess.run(['zsh','-f','-c',code],env={**self.env,
            'XDG_CACHE_HOME':str(self.home/'.cache'),'TEST_THEME_ENGINE':str(self.root/'engine.py')},
            capture_output=True,text=True,timeout=10)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('38;2;180;142;173',(self.home/'before').read_text())
        self.assertIn('38;2;255;121;198',(self.home/'after').read_text())

    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter unavailable')
    def test_hyprland_registers_binds_with_missing_or_broken_theme(self):
        script='''
local count = 0
local dummy
dummy=setmetatable({}, {__index=function() return dummy end, __call=function() return dummy end})
hl=setmetatable({
  bind=function() count=count+1 end,
  on=function() end,
  get_monitors=function() return {} end,
  get_workspace=function() return nil end,
}, {__index=function() return dummy end})
package.path=arg[1] .. "/?.lua;" .. package.path
assert(loadfile(arg[1] .. "/hyprland.lua"))()
assert(count==76, "Expected all 76 key bindings, got " .. count)
'''
        check=self.home/'check-hyprland.lua'
        check.write_text(script)
        for broken in (False,True):
            if broken:
                self.put('.config/desktop-theme/current/hyprland.lua','error("broken theme")')
            result=subprocess.run(['lua',str(check),str(REPO/'config/.config/hypr')],env=self.env,capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)

    @unittest.skipUnless(shutil.which('stow'), 'GNU Stow unavailable')
    def test_fresh_home_install_keeps_private_runtime_state_outside_checkout(self):
        checkout=Path(self.temp.name)/'relocated checkout'
        package=checkout/'config'
        shutil.copytree(self.root,package/'.config/desktop-theme',ignore=shutil.ignore_patterns('current','__pycache__'))
        shutil.copytree(REPO/'config/.themes/Nordic-darker',package/'.themes/Nordic-darker')
        (package/'.local/bin').mkdir(parents=True)
        (package/'.local/bin/theme-switch').symlink_to('../../.config/desktop-theme/engine.py')
        shutil.copy(REPO/'install.sh',checkout/'install.sh')
        fresh=Path(self.temp.name)/'fresh home'
        fresh.mkdir()
        env={**os.environ,'HOME':str(fresh),'XDG_CONFIG_HOME':str(fresh/'.config'),
             'XDG_STATE_HOME':str(fresh/'.local/state'),'CODEX_HOME':str(fresh/'.codex'),
             'CLAUDE_CONFIG_DIR':str(fresh/'.claude')}
        result=subprocess.run(['bash',str(checkout/'install.sh')],env=env,capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse((fresh/'.local').is_symlink())
        self.assertFalse((fresh/'.themes').is_symlink())
        self.assertTrue((fresh/'.local/state/kiwidots-theme/generations').is_dir())
        self.assertFalse((package/'.local/state').exists())
        self.assertTrue((fresh/'.local/bin/theme-switch').is_file())


if __name__=='__main__':
    unittest.main()
