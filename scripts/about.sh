#!/bin/bash
# Adapted from Omarchy’s omarchy-launch-about.
# Copyright (c) David Heinemeier Hansson; see LICENSE-omarchy.txt.

# Launch and size the About window for Miami Wind’s custom Fastfetch layout.

# The size that hugs the About content depends on the terminal font and the user's
# logo, so it can only be measured from inside the terminal. We remember the size
# that fit and apply it as a window rule before launching, so the window opens at
# it instead of resizing after the first paint. Bash defers WINCH traps while read
# blocks, so poll for size changes and re-render fastfetch whenever it is resized.

LOGO_FILE="$HOME/.config/fastfetch/about.txt"
FIT_FILE="$HOME/.local/state/omarchy/windows/miami-wind-about.fit"

# This launcher measures the complete custom output, including the logo.

# wc -L counts display columns only in a UTF-8 locale. A session that never set
# one counts every box-drawing and Nerd Font glyph in the About layout as
# nothing, which measures the content narrower than it renders.
display_columns() {
  LC_ALL=C.UTF-8 wc -L
}

logo_dimensions() {
  [[ -f $LOGO_FILE ]] || return 1
  printf '%s %s' "$(display_columns <"$LOGO_FILE")" "$(wc -l <"$LOGO_FILE")"
}

hypr_dispatch() {
  local lua="$1"
  shift
  hyprctl dispatch "$lua" >/dev/null 2>&1 || hyprctl dispatch "$@" >/dev/null
}

remember_fit() {
  local directory tmp
  directory=$(dirname "$FIT_FILE")
  mkdir -p "$directory"
  tmp=$(mktemp "$directory/.about.fit.XXXXXX")
  printf '%s %s %s %s\n' "$1" "$2" "$3" "$4" >"$tmp"
  mv "$tmp" "$FIT_FILE"
}

# Replaces the rule from the last launch so a remembered size never outlives the
# fit it came from. Called without one it only clears, leaving the float rule's
# starting size — where a Hyprland without the Lua API stays too.
apply_size_rule() {
  local rule=""
  (( $# == 2 )) && rule="omarchy_about_size_rule = hl.window_rule({ match = { class = \"org.omarchy.about\" }, size = { $1, $2 } })"

  hyprctl eval "if omarchy_about_size_rule then omarchy_about_size_rule:set_enabled(false) end; omarchy_about_size_rule = nil; $rule" >/dev/null 2>&1
}

# Sized before the terminal is spawned, so the window maps at its final size.
presize_window() {
  local logo_w logo_h fit_logo_w fit_logo_h fit_w fit_h

  if [[ -r $FIT_FILE ]]; then
    read -r logo_w logo_h <<<"$(logo_dimensions)"
    read -r fit_logo_w fit_logo_h fit_w fit_h <"$FIT_FILE"

    # A different logo needs a different window, so leave that launch to the
    # float rule and let the fit measure the new size.
    if [[ -n ${logo_w:-} && $logo_w == "$fit_logo_w" && $logo_h == "$fit_logo_h" ]] &&
      [[ $fit_w =~ ^[0-9]+$ && $fit_h =~ ^[0-9]+$ ]]; then
      apply_size_rule "$fit_w" "$fit_h"
      return
    fi
  fi

  apply_size_rule
}

# Hyprland animates a resize and the terminal reflows to every step of it, so
# wait for the grid to hold still before measuring it.
settle_grid() {
  local current previous="" held=0

  for _ in {1..20}; do
    current=$(stty size)
    if [[ $current == $previous ]]; then
      (( ++held == 3 )) && break
    else
      held=0
      previous=$current
    fi
    sleep 0.05
  done
}

fit_window() {
  local logo_w logo_h
  read -r logo_w logo_h <<<"$(logo_dimensions)"
  [[ -n ${logo_w:-} ]] || return 1

  # The guard character keeps command substitution from eating the trailing
  # break line, which provides the bottom padding row.
  local modules module_w module_h
  modules=$(fastfetch --pipe true | sed 's/\x1b\[[0-9;?]*[a-zA-Z]//g'; printf X)
  modules=${modules%X}
  module_w=$(printf '%s' "$modules" | display_columns)
  module_h=$(printf '%s' "$modules" | wc -l)

  # Full output already includes logo padding. Add two columns of slack
  # and one cursor row. --pipe is used for measuring only; rendering keeps color.
  local target_c=$(( module_w + 2 ))
  local target_r=$(( module_h + 1 ))

  local nudges=0 rows cols address width height shift_w shift_h target_w target_h
  while :; do
    read -r rows cols <<<"$(stty size)"
    read -r address width height <<<"$(hyprctl clients -j | jq -r '.[] | select(.class == "org.omarchy.about") | "\(.address) \(.size[0]) \(.size[1])"')"
    [[ -n ${address:-} ]] || return 1
    (( cols > 0 && rows > 0 && width > 0 && height > 0 )) || return 1

    # A window has to land on the terminal's cell boundaries, so take a cell of
    # slack over chasing an exact grid, and remember where it came to rest.
    if (( cols >= target_c && cols <= target_c + 1 && rows >= target_r && rows <= target_r + 1 )); then
      remember_fit "$logo_w" "$logo_h" "$width" "$height"
      return 0
    fi

    # Two nudges is the budget, and each one is measured before the next is spent.
    (( ++nudges <= 2 )) || return 1

    # Move by the cells the window is off by, rather than scaling it to the grid,
    # which would multiply up the terminal's padding along with them. Dividing a
    # window that carries that padding still leaves the cell a touch generous, so
    # round the move away from the grid that would clip.
    shift_w=$(( (target_c - cols) * width ))
    shift_h=$(( (target_r - rows) * height ))
    target_w=$(( width + (shift_w >= 0 ? (shift_w + cols - 1) / cols : shift_w / cols) ))
    target_h=$(( height + (shift_h >= 0 ? (shift_h + rows - 1) / rows : shift_h / rows) ))

    hypr_dispatch "hl.dsp.window.resize({ window = \"address:$address\", x = $target_w, y = $target_h })" resizewindowpixel "exact $target_w $target_h,address:$address"
    hypr_dispatch "hl.dsp.window.center({ window = \"address:$address\" })" centerwindow
    settle_grid
  done

  return 1
}

if [[ ${1:-} == "--render" ]]; then
  printf '\e[?25l'

  # Give the compositor a moment to apply the window rules before measuring cells.
  settle_grid

  fitted=false
  passes=0
  while :; do
    size=$(stty size)
    logo_stamp=$(stat -c %Y "$LOGO_FILE" 2>/dev/null)
    clear
    fastfetch
    # A second pass picks up a fit that could not measure the window the first
    # time. Beyond that, a window that will not settle would be fitted again on
    # every repaint.
    if [[ $fitted == false ]] && (( ++passes <= 2 )); then
      fit_window && fitted=true
    fi
    while [[ $(stty size) == $size && $(stat -c %Y "$LOGO_FILE" 2>/dev/null) == $logo_stamp ]]; do
      read -t 0.5 -n 1 -s && exit
      (( $? > 128 )) || exit
    done
    # A rebranded logo changes the content dimensions, so measure again.
    if [[ $(stat -c %Y "$LOGO_FILE" 2>/dev/null) != $logo_stamp ]]; then
      fitted=false
      passes=0
    fi
  done
fi

presize_window
exec omarchy-launch-or-focus-tui --app-id=org.omarchy.about "$HOME/.local/bin/miami-wind-about" --render
