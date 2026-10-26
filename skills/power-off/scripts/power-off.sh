#!/bin/sh
# Power off (or suspend) this machine. Linux, macOS, WSL (acts on the Windows host), Git Bash/MSYS/Cygwin.
# Usage: power-off.sh [--sleep] [--dry-run]   (--sleep suspends instead of powering off; --dry-run only prints the command)
# If powering off fails, it retries once, then suspends instead.
# Waits 5s first so the calling agent can finish its reply; Ctrl+C or killing it cancels.
set -u
dry=0; mode=off
for a in "$@"; do
  case "$a" in
    --dry-run) dry=1 ;;
    --sleep) mode=sleep ;;
    *) echo "power-off: unknown option: $a" >&2; exit 2 ;;
  esac
done

case "$(uname -s)" in
  Darwin) os=macos ;;
  MINGW*|MSYS*|CYGWIN*) os=windows ;;
  Linux)
    if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then os=wsl; else os=linux; fi ;;
  *) echo "power-off: unsupported OS: $(uname -s)" >&2; exit 2 ;;
esac

sleep_cmd() {
  case "$os" in
    linux) set -- systemctl suspend ;;
    macos) set -- pmset sleepnow ;;
    *)     set -- rundll32.exe powrprof.dll,SetSuspendState 0,1,0 ;;
  esac
  echo "$*"
}

off_cmd() {
  case "$os" in
    linux)
      if command -v systemctl >/dev/null 2>&1; then echo "systemctl poweroff"; else echo "poweroff"; fi ;;
    macos) echo "osascript -e 'tell app \"System Events\" to shut down'" ;;
    *)
      # WSL and Git Bash call the Windows executables; doubled slashes stop MSYS rewriting them into paths.
      exe=shutdown.exe
      if [ "$os" = wsl ]; then
        command -v "$exe" >/dev/null 2>&1 || exe=/mnt/c/Windows/System32/shutdown.exe
        echo "$exe /s /t 0"
      else
        echo "$exe //s //t 0"
      fi ;;
  esac
}

sleep_line=$(sleep_cmd)
if [ "$mode" = sleep ]; then cmd=$sleep_line; else cmd=$(off_cmd); fi

echo "power-off: detected $os ($mode); command: $cmd"
[ "$mode" = off ] && echo "power-off: if it fails twice, falls back to: $sleep_line"
[ "$dry" = 1 ] && exit 0
sleep 5
# shellcheck disable=SC2086  # commands are simple space-separated words, except the macOS one run via eval
if [ "$mode" = sleep ]; then eval "$cmd"; exit $?; fi
if eval "$cmd"; then exit 0; fi
echo "power-off: power off failed; retrying once" >&2
sleep 2
if eval "$cmd"; then exit 0; fi
echo "power-off: power off failed again; sleeping instead: $sleep_line" >&2
eval "$sleep_line"
