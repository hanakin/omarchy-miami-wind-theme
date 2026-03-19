#!/bin/sh

status="${STARSHIP_CMD_STATUS:-0}"
duration="${STARSHIP_DURATION:-0}"

base_fg="30;30;46"
green_bg="52;211;153"
red_bg="248;113;113"
orange_bg="253;186;116"
pink_bg="244;114;182"
blue_bg="129;140;248"
purple_bg="192;132;252"
cyan_bg="34;211;238"
yellow_bg="254;240;138"
lang_toggle=0

first=1
current_bg=""

find_up() {
  name="$1"
  dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -e "$dir/$name" ]; then
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  [ -e "/$name" ]
}

append_segment() {
  bg="$1"
  text="$2"

  if [ -z "$text" ]; then
    return
  fi

  if [ "$first" -eq 1 ]; then
    printf '\033[38;2;%sm' "$bg"
    first=0
  else
    printf '\033[38;2;%sm\033[48;2;%sm' "$bg" "$current_bg"
  fi

  printf '\033[48;2;%sm\033[38;2;%sm%s' "$bg" "$base_fg" "$text"
  current_bg="$bg"
}

append_lang_segment() {
  text="$1"
  if [ -z "$text" ]; then
    return
  fi

  if [ "$lang_toggle" -eq 0 ]; then
    append_segment "$purple_bg" "$text"
    lang_toggle=1
  else
    append_segment "$blue_bg" "$text"
    lang_toggle=0
  fi
}

segment_python() {
  if find_up pyproject.toml || find_up requirements.txt || find_up Pipfile || find_up setup.py || find_up .python-version || find_up environment.yml || find_up .venv || [ -n "$VIRTUAL_ENV" ]; then
    ver="$(python3 --version 2>/dev/null | awk '{print $2}')"
    [ -n "$VIRTUAL_ENV" ] && venv="($(basename "$VIRTUAL_ENV"))" || venv=""
    [ -n "$ver" ] && printf '  %s%s ' "$ver" "$venv"
  fi
}

segment_node() {
  if find_up package.json || find_up .nvmrc || find_up bun.lock || find_up bun.lockb || find_up pnpm-lock.yaml || find_up yarn.lock; then
    ver="$(node --version 2>/dev/null | sed 's/^v//')"
    [ -n "$ver" ] && printf '  %s ' "$ver"
  fi
}

segment_rust() {
  if find_up Cargo.toml || find_up rust-toolchain || find_up rust-toolchain.toml; then
    ver="$(rustc --version 2>/dev/null | awk '{print $2}')"
    [ -n "$ver" ] && printf '  %s ' "$ver"
  fi
}

segment_go() {
  if find_up go.mod || find_up go.work; then
    ver="$(go version 2>/dev/null | awk '{print $3}' | sed 's/^go//')"
    [ -n "$ver" ] && printf '  %s ' "$ver"
  fi
}

segment_java() {
  if find_up pom.xml || find_up build.gradle || find_up build.gradle.kts || find_up gradlew || find_up .java-version; then
    ver="$(java -version 2>&1 | awk -F '\"' 'NR==1{print $2}')"
    [ -n "$ver" ] && printf '  %s ' "$ver"
  fi
}

segment_package() {
  dir="$PWD"
  pkg=""
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/package.json" ]; then
      pkg="$dir/package.json"
      break
    fi
    dir="$(dirname "$dir")"
  done
  if [ -n "$pkg" ]; then
    ver="$(sed -n 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$pkg" | head -n 1)"
    [ -n "$ver" ] && printf ' 󰏗 %s ' "$ver"
  fi
}

segment_docker() {
  if find_up Dockerfile || find_up docker-compose.yml || find_up docker-compose.yaml || [ -n "$DOCKER_CONTEXT" ]; then
    ctx="${DOCKER_CONTEXT:-$(docker context show 2>/dev/null)}"
    [ -n "$ctx" ] && printf '  %s ' "$ctx"
  fi
}

segment_aws() {
  if [ -n "$AWS_PROFILE" ]; then
    printf ' 󰸏 %s ' "$AWS_PROFILE"
  fi
}

segment_direnv() {
  if [ -n "$DIRENV_FILE" ] || [ -n "$DIRENV_DIR" ]; then
    printf ' 󱁿 direnv '
  fi
}

if [ "$status" -eq 0 ] 2>/dev/null; then
  append_segment "$green_bg" " ✔ "
else
  append_segment "$red_bg" " ✘$status "
fi

if [ "$duration" -ge 3000 ] 2>/dev/null; then
  append_segment "$orange_bg" "  $((duration / 1000))s "
fi

py_seg="$(segment_python)"
[ -n "$py_seg" ] && append_lang_segment "$py_seg"

node_seg="$(segment_node)"
[ -n "$node_seg" ] && append_lang_segment "$node_seg"

rust_seg="$(segment_rust)"
[ -n "$rust_seg" ] && append_lang_segment "$rust_seg"

go_seg="$(segment_go)"
[ -n "$go_seg" ] && append_lang_segment "$go_seg"

java_seg="$(segment_java)"
[ -n "$java_seg" ] && append_lang_segment "$java_seg"

package_seg="$(segment_package)"
[ -n "$package_seg" ] && append_lang_segment "$package_seg"

docker_seg="$(segment_docker)"
[ -n "$docker_seg" ] && append_segment "$blue_bg" "$docker_seg"

aws_seg="$(segment_aws)"
[ -n "$aws_seg" ] && append_segment "$yellow_bg" "$aws_seg"

direnv_seg="$(segment_direnv)"
[ -n "$direnv_seg" ] && append_segment "$cyan_bg" "$direnv_seg"

append_segment "$pink_bg" "  $(date '+%I:%M %p') "
printf '\033[0m\033[38;2;%sm' "$pink_bg"
