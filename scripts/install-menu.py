#!/usr/bin/env python3
"""Update About without removing other menu entries or JSONC comments."""
import json
import re
import shlex
import sys
from pathlib import Path


def clean_jsonc(text, trailing_commas=True):
    # Keep character offsets unchanged so only the About value is replaced.
    pattern = r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/'
    clean = re.sub(pattern, lambda m: m[0] if m[0].startswith('"') else
                   ''.join('\n' if c == '\n' else ' ' for c in m[0]), text)
    if trailing_commas:
        clean = re.sub(r'"(?:\\.|[^"\\])*"|,(?=\s*[}\]])',
                       lambda m: m[0] if m[0].startswith('"') else ' ', clean)
    return clean


def update_menu(path, launcher):
    text = path.read_text() if path.exists() else '{}\n'
    clean = clean_jsonc(text)
    data = json.loads(clean)
    if not isinstance(data, dict):
        raise ValueError('Menu extensions must be a JSON object')
    about = data.get('about', {})
    if not isinstance(about, dict):
        raise ValueError('The About entry must be an object')
    about.update(icon='', label='About', action=shlex.quote(str(launcher)))
    replacement = json.dumps(about, ensure_ascii=False)
    decoder = json.JSONDecoder()
    pos = clean.index('{') + 1
    while True:
        while clean[pos].isspace() or clean[pos] == ',':
            pos += 1
        if clean[pos] == '}':
            # Insert before the closing brace, preserving comments and whitespace.
            needs_comma = bool(data) and not clean_jsonc(text, trailing_commas=False)[:pos].rstrip().endswith(',')
            text = text[:pos] + (',' if needs_comma else '') + '\n  "about": ' + replacement + '\n' + text[pos:]
            break
        key, end = decoder.raw_decode(clean, pos)
        pos = end
        while clean[pos].isspace():
            pos += 1
        if clean[pos] != ':':
            raise ValueError('Invalid menu entry')
        pos += 1
        while clean[pos].isspace():
            pos += 1
        start = pos
        _, pos = decoder.raw_decode(clean, pos)
        if key == 'about':
            text = text[:start] + replacement + text[pos:]
            break
    json.loads(clean_jsonc(text))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


if __name__ == '__main__':
    update_menu(Path(sys.argv[1]), Path(sys.argv[2]))
