#!/bin/sh

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	exit 1
fi

mode="${1:-state}"
branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
status_lines="$(git status --porcelain=2 --branch 2>/dev/null)"

ahead=0
behind=0
staged=0
unstaged=0
untracked=0
conflicted=0

while IFS= read -r line; do
	case "$line" in
		"# branch.ab "*)
			set -- $line
			ahead="${3#+}"
			behind="${4#-}"
			;;
		"1 "*|"2 "*)
			xy="$(printf '%s' "$line" | cut -c3-4)"
			x="$(printf '%s' "$xy" | cut -c1)"
			y="$(printf '%s' "$xy" | cut -c2)"
			[ "$x" != "." ] && staged=$((staged + 1))
			[ "$y" != "." ] && unstaged=$((unstaged + 1))
			;;
		"u "*)
			conflicted=$((conflicted + 1))
			;;
		"? "*)
			untracked=$((untracked + 1))
			;;
	esac
done <<EOF
$status_lines
EOF

git_dir="$(git rev-parse --git-dir 2>/dev/null)"
op_state=""
if [ -n "$git_dir" ]; then
	[ -d "$git_dir/rebase-merge" ] && op_state="rebase"
	[ -d "$git_dir/rebase-apply" ] && op_state="rebase"
	[ -f "$git_dir/MERGE_HEAD" ] && op_state="merge"
	[ -f "$git_dir/CHERRY_PICK_HEAD" ] && op_state="pick"
	[ -f "$git_dir/REVERT_HEAD" ] && op_state="revert"
	[ -f "$git_dir/BISECT_LOG" ] && op_state="bisect"
fi

# Shorten the branch so the bar fits: at most a quarter of the terminal, and never
# more than what is left after the lead block (6), host and path, this block's own
# glyphs and counters, and the smallest right strip (7).
cols="${MIAMI_WIND_COLS:-$( (stty size </dev/tty) 2>/dev/null | cut -d' ' -f2)}"
if [ -n "$cols" ]; then
	esc="$(printf '\033')"
	used="$({ STARSHIP_SHELL=sh starship module hostname; STARSHIP_SHELL=sh starship module directory; } 2>/dev/null | sed "s/$esc\[[0-9;]*m//g" | tr -d '\n' | wc -m)"
	used=$((used + 6 + 8 + 7))
	for count in "$ahead" "$staged" "$untracked" "$unstaged" "$behind" "$conflicted"; do
		[ "${count:-0}" -gt 0 ] && used=$((used + ${#count} + 2))
	done
	[ -n "$op_state" ] && used=$((used + ${#op_state} + 1))
	max_branch=$((cols / 4))
	[ "$max_branch" -lt 12 ] && max_branch=12
	[ $((cols - used)) -lt "$max_branch" ] && max_branch=$((cols - used))
	# No room even for a stub: draw only the endcap, like outside a repo.
	if [ "$max_branch" -lt 2 ]; then
		[ "$mode" = render ] && printf '\033[38;2;34;211;238m\033[0m'
		exit 0
	fi
	[ "${#branch}" -gt "$max_branch" ] && branch="$(printf '%s' "$branch" | cut -c1-$((max_branch - 1)))…"
fi

state="clean"
bg="69;71;90"
branch_fg="74;222;128"
if [ "$conflicted" -gt 0 ] || [ -n "$op_state" ]; then
	state="conflict"
	branch_fg="244;63;94"
elif [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$untracked" -gt 0 ] || [ "${ahead:-0}" -gt 0 ] || [ "${behind:-0}" -gt 0 ]; then
	state="dirty"
	branch_fg="253;186;116"
fi

case "$mode" in
	state)
		echo "$state"
		;;
	render)
		base_fg="30;30;46"
		cyan_fg="34;211;238"
		green_fg="74;222;128"
		yellow_fg="254;240;138"
		red_fg="244;63;94"

		printf '\033[48;2;%sm\033[38;2;%sm' "$bg" "$cyan_fg"
		printf '\033[38;2;%sm   %s  ' "$branch_fg" "$branch"

		[ "${ahead:-0}" -gt 0 ] && printf '\033[38;2;%sm⇡%s ' "$green_fg" "$ahead"
		[ "$staged" -gt 0 ] && printf '\033[38;2;%sm+%s ' "$green_fg" "$staged"
		[ "$untracked" -gt 0 ] && printf '\033[38;2;%sm?%s ' "$green_fg" "$untracked"

		[ "$unstaged" -gt 0 ] && printf '\033[38;2;%sm!%s ' "$yellow_fg" "$unstaged"

		[ "${behind:-0}" -gt 0 ] && printf '\033[38;2;%sm⇣%s ' "$red_fg" "$behind"
		[ "$conflicted" -gt 0 ] && printf '\033[38;2;%sm~%s ' "$red_fg" "$conflicted"
		[ -n "$op_state" ] && printf '\033[38;2;%sm%s ' "$red_fg" "$op_state"

		printf '\033[0m\033[38;2;%sm' "$bg"
		;;
esac
