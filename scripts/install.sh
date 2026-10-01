#!/usr/bin/env bash
# Explicit local installation for the theme author's trusted working copy.
set -euo pipefail

skip_icons=0
apply_theme=1
for arg in "$@"; do
  case "$arg" in
    --skip-icons) skip_icons=1 ;;
    --no-apply) apply_theme=0 ;;
    --help)
      echo 'Usage: bash scripts/install.sh [--skip-icons] [--no-apply]'
      echo 'Installs the trusted local theme, About launcher, Starship and Fastfetch.'
      echo '--skip-icons: use an existing Flatery icon installation; no network access.'
      echo '--no-apply: install files without switching the active Omarchy theme.'
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

for dependency in python3 omarchy; do
  command -v "$dependency" >/dev/null || { echo "Required command missing: $dependency" >&2; exit 1; }
done
if (( ! skip_icons )); then
  command -v git >/dev/null || { echo 'Required command missing: git' >&2; exit 1; }
fi

THEME_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
THEME_LINK="$HOME/.config/omarchy/themes/miami-wind"
STATE_DIR="$HOME/.local/state/omarchy"
mkdir -p "$STATE_DIR/backups"
BACKUP_DIR=$(mktemp -d "$STATE_DIR/backups/miami-wind-install.XXXXXX")

backup_path() {
  local path="$1"
  if [[ -e $path || -L $path ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${path#"$HOME/"}")"
    cp -a -- "$path" "$BACKUP_DIR/${path#"$HOME/"}"
  fi
}

# A symlink to an explicitly trusted working copy lets Omarchy stage every
# theme file. Keep Git history; do not edit Omarchy's packaged installer.
# If invoked inside the clone made by `omarchy theme install`, relocate that
# clone first so the theme link cannot point to itself.
if [[ ! -L $THEME_LINK && $THEME_DIR == "$THEME_LINK" ]]; then
  SOURCE_PARENT="$HOME/.local/share/omarchy/theme-sources"
  mkdir -p "$SOURCE_PARENT"
  SOURCE_DIR=$(mktemp -d "$SOURCE_PARENT/miami-wind.XXXXXX")
  rmdir "$SOURCE_DIR"
  mv -- "$THEME_DIR" "$SOURCE_DIR"
  THEME_DIR="$SOURCE_DIR"
fi
if [[ ! -L $THEME_LINK || $(readlink -f "$THEME_LINK") != "$THEME_DIR" ]]; then
  mkdir -p "$(dirname "$THEME_LINK")"
  if [[ -e $THEME_LINK || -L $THEME_LINK ]]; then
    mv -- "$THEME_LINK" "$BACKUP_DIR/previous-theme"
  fi
  ln -s -- "$THEME_DIR" "$THEME_LINK"
fi

for path in "$HOME/.config/starship.toml" "$HOME/.config/fastfetch/config.jsonc" \
            "$HOME/.config/fastfetch/about.txt" "$HOME/.local/bin/miami-wind-about" \
            "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"; do
  backup_path "$path"
done
mkdir -p "$HOME/.config/fastfetch" "$HOME/.local/bin"
ln -sfn "$THEME_LINK/starship.toml" "$HOME/.config/starship.toml"
ln -sfn "$THEME_LINK/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
ln -sfn "$THEME_LINK/fastfetch/about.txt" "$HOME/.config/fastfetch/about.txt"
install -m 755 "$THEME_DIR/scripts/about.sh" "$HOME/.local/bin/miami-wind-about"
python3 "$THEME_DIR/scripts/install-menu.py" \
  "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc" "$HOME/.local/bin/miami-wind-about"

if (( ! skip_icons )); then
  ICONS_DIR="$HOME/.local/share/icons"
  if [[ ! -f $ICONS_DIR/Flatery-Pink-Dark/index.theme || \
        ! -d $ICONS_DIR/Flatery-Dark || ! -d $ICONS_DIR/Flatery ]]; then
    ICON_SOURCE=$(mktemp -d)
    trap 'rm -rf -- "$ICON_SOURCE"' EXIT
    git clone --depth 1 https://github.com/cbrnix/Flatery.git "$ICON_SOURCE/Flatery"
    mkdir -p "$ICONS_DIR"
    # Color variants use relative links to both base directories.
    for name in Flatery Flatery-Dark Flatery-Pink-Dark; do
      if [[ -e $ICONS_DIR/$name ]]; then
        mv -- "$ICONS_DIR/$name" "$BACKUP_DIR/$name"
      fi
      cp -a -- "$ICON_SOURCE/Flatery/$name" "$ICONS_DIR/$name"
    done
    if command -v gtk-update-icon-cache >/dev/null; then
      gtk-update-icon-cache -f "$ICONS_DIR/Flatery-Pink-Dark"
    fi
  fi
fi

if (( apply_theme )); then
  omarchy theme set miami-wind
fi
printf 'Installed Miami Wind. Backups: %s\n' "$BACKUP_DIR"
printf 'Open About from Super + Space; open a new terminal for the prompt.\n'
