"""Check the prompt's top bar never renders wider than the terminal."""
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BRANCH = 'feature/a-long-branch-name-that-keeps-going'


@unittest.skipUnless(shutil.which('starship') and shutil.which('git'), 'needs starship and git')
class PromptWidthTests(unittest.TestCase):
    def bar(self, home, cwd, width):
        env = dict(os.environ, HOME=str(home), STARSHIP_CONFIG=str(ROOT / 'starship.toml'),
                   STARSHIP_SHELL='sh', MIAMI_WIND_COLS=str(width), PWD=str(cwd))
        out = subprocess.run(['starship', 'prompt', '--terminal-width', str(width)],
                             cwd=cwd, env=env, capture_output=True, text=True, check=True).stdout
        return re.sub(r'\x1b\[[0-9;]*m', '', out).strip('\n').split('\n')[0]

    def test_bar_fits_terminal_width(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            theme = home / '.local/state/omarchy/current'
            theme.mkdir(parents=True)
            (theme / 'theme').symlink_to(ROOT)
            repo = home / 'project'
            repo.mkdir()
            (repo / 'package.json').write_text('{"version": "1.2.3"}')
            subprocess.run(['git', 'init', '-q', '-b', BRANCH], cwd=repo, check=True)
            for cwd in (home, repo):
                for width in (60, 80, 100, 200):
                    with self.subTest(cwd=cwd.name, width=width):
                        self.assertLessEqual(len(self.bar(home, cwd, width)), width)
            self.assertIn('PM', self.bar(home, repo, 200).replace('AM', 'PM'))
            self.assertIn('1.2.3', self.bar(home, repo, 200))
            self.assertIn(BRANCH, self.bar(home, repo, 200))


if __name__ == '__main__':
    unittest.main()
