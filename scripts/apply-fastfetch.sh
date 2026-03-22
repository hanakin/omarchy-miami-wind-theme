#!/bin/bash

set -e

THEME_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FASTFETCH_DIR="$HOME/.config/fastfetch"
CONFIG_TARGET="$FASTFETCH_DIR/config.jsonc"
LOGO_TARGET="$FASTFETCH_DIR/about.txt"

mkdir -p "$FASTFETCH_DIR"

if [[ -e $CONFIG_TARGET ]] && [[ ! -L $CONFIG_TARGET ]]; then
  mv "$CONFIG_TARGET" "$CONFIG_TARGET.bak.$(date +%s)"
fi

if [[ -e $LOGO_TARGET ]] && [[ ! -L $LOGO_TARGET ]]; then
  mv "$LOGO_TARGET" "$LOGO_TARGET.bak.$(date +%s)"
fi

ln -sfn "$THEME_DIR/fastfetch/config.jsonc" "$CONFIG_TARGET"

# Keep the old about.txt symlink for compatibility, even though the current config uses robot.svg directly.
ln -sfn "$THEME_DIR/fastfetch/about.txt" "$LOGO_TARGET"

echo "Fastfetch now uses:"
echo "  $THEME_DIR/fastfetch/config.jsonc"
echo "  SVG logo: $HOME/Downloads/robot.svg"
echo "  Legacy text logo: $THEME_DIR/fastfetch/about.txt"
