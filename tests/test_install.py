"""Exercise the menu merge and installer against an isolated home directory."""
import importlib.util
import json
import os
import subprocess
import shutil
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('install_menu', ROOT / 'scripts/install-menu.py')
menu = importlib.util.module_from_spec(spec)
spec.loader.exec_module(menu)


class InstallTests(unittest.TestCase):
    def test_menu_preserves_comments_and_existing_entries(self):
        fixtures = [
            '{\n // comment\n}',
            '{"personal": {"label": "https://example.com"}, // comment\n}',
            '{"personal": {"label": "Notes"} /* comment */\n}',
            '{"about": {"description": "Keep me ,}", "action": "old"}, // comment\n}',
        ]
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'menu.jsonc'
            for fixture in fixtures:
                with self.subTest(fixture=fixture):
                    path.write_text(fixture)
                    menu.update_menu(path, Path('/some path/about'))
                    once = path.read_text()
                    menu.update_menu(path, Path('/some path/about'))
                    self.assertEqual(once, path.read_text())
                    self.assertIn('comment', once)
                    data = json.loads(menu.clean_jsonc(once))
                    self.assertEqual(data['about']['label'], 'About')
                    self.assertEqual(data['about']['icon'], '')
                    self.assertEqual(data['about']['action'], "'/some path/about'")
                    if 'personal' in fixture:
                        self.assertIn('personal', data)
                    if 'description' in fixture:
                        self.assertEqual(data['about']['description'], 'Keep me ,}')

    def test_installer_backs_up_and_can_be_rerun(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            config = home / '.config'
            config.mkdir()
            prompt = config / 'starship.toml'
            prompt.write_text('original prompt')
            tools = home / 'bin'
            tools.mkdir()
            omarchy = tools / 'omarchy'
            omarchy.write_text('#!/bin/sh\nexit 0\n')
            omarchy.chmod(0o755)
            env = dict(os.environ, HOME=str(home), PATH=str(tools) + ':' + os.environ['PATH'])
            command = ['bash', str(ROOT / 'scripts/install.sh'), '--skip-icons', '--no-apply']
            for _ in range(2):
                subprocess.run(command, env=env, check=True, capture_output=True, text=True)
            self.assertTrue(prompt.is_symlink())
            self.assertEqual(prompt.resolve(), ROOT / 'starship.toml')
            self.assertTrue((config / 'fastfetch/about.txt').resolve().is_file())
            self.assertTrue(os.access(home / '.local/bin/miami-wind-about', os.X_OK))
            path = config / 'omarchy/extensions/omarchy-menu.jsonc'
            self.assertEqual(json.loads(menu.clean_jsonc(path.read_text()))['about']['label'], 'About')
            backups = list((home / '.local/state/omarchy/backups').glob('*/.config/starship.toml'))
            self.assertTrue(any(not p.is_symlink() and p.read_text() == 'original prompt' for p in backups))


    def test_installer_relocates_standard_omarchy_clone(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            source = home / '.config/omarchy/themes/miami-wind'
            shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns('.git', '__pycache__'))
            (source / '.git').mkdir()
            tools = home / 'bin'
            tools.mkdir()
            command = tools / 'omarchy'
            command.write_text('#!/bin/sh\nexit 0\n')
            command.chmod(0o755)
            env = dict(os.environ, HOME=str(home), PATH=str(tools) + ':' + os.environ['PATH'])
            subprocess.run(['bash', str(source / 'scripts/install.sh'), '--skip-icons', '--no-apply'],
                           env=env, check=True, capture_output=True, text=True)
            self.assertTrue(source.is_symlink())
            self.assertIn('.local/share/omarchy/theme-sources', str(source.resolve()))
            self.assertTrue((source / '.git').is_dir())
            self.assertEqual((home / '.config/starship.toml').resolve(), source.resolve() / 'starship.toml')


if __name__ == '__main__':
    unittest.main()
