#!/usr/bin/env bash
REDISCOVER="${REDISCOVER:-}"

_elgato() {
  elgato_bin=$(cat "$HOME/.config/elgato/alfred_bin_path")
  if test -z "$elgato_bin"
  then
    for bin in "$(which elgato)" \
      "$HOME/.home_env/bin/elgato" \
      "$HOME/.asdf/shims/elgato"
    do
      if "$bin" --help
      then
        elgato_bin="$bin" &&
          echo "$bin" > "$HOME/.config/elgato/alfred_bin_path"
      fi
    done
    if test -z "$elgato_bin"
    then
      >&2 echo "ERROR: pyelgato not installed; run 'pip install pyelgato' to install it."
      exit 1
    fi
  fi
  "$elgato_bin" "$@"
}

_wifi_network_encoded() {
  net=$(ipconfig getsummary en0 | grep ' SSID' | cut -f2 -d ':' | sed -E 's/^ +//')
  if test -z "$net"
  then
    >&2 echo "ERROR: Current wi-fi network not found."
    exit 1
  fi
  echo "$net" | base64 -w 0 | tr '[:upper:]' '[:lower:]'
}

_discovered_file_for_this_wifi_network() {
  echo "$HOME/.config/elgato/discovered_$(_wifi_network_encoded).json"
}

_num_lights_discovered() {
  if test "$1" != "--overwrite" && test -f "$HOME/.config/elgato/.num_lights_$(_wifi_network_encoded)"
  then cat "$HOME/.config/elgato/.num_lights_$(_wifi_network_encoded)" && return 0
  fi
  jq -r '.|length' "$(_discovered_file_for_this_wifi_network)" > "$HOME/.config/elgato/.num_lights_$(_wifi_network_encoded)"
}

discover_lights() {
  test -z "$REDISCOVER" && test -f "$(_discovered_file_for_this_wifi_network)" && return 0

  _elgato lights --discover &&
    cp "$HOME/.config/elgato/discovered.json" "$(_discovered_file_for_this_wifi_network)" &&
    _num_lights_discovered --overwrite
}

# set_brightness [BRIGHTNESS_LIGHT_1] [BRIGHTNESS_LIGHT_2] ...: Sets light brightness.
set_brightness() {
  discover_lights || return 1
  idx=0
  for arg in "$@"
  do
    if test "$idx" -gt "$(_num_lights_discovered)"
    then
      >&2 echo "ERROR: Not enough lights to set this brightness level: $idx; ignoring rest"
      return 0
    fi
    >&2 echo "INFO: Setting brightness for light $idx to $arg"
    _elgato brightness "$idx" --level "$arg" || return 1
    idx=$((idx+1))
  done
}

# set_color [color_LIGHT_1] [color_LIGHT_2] ...: Sets light color.
set_color() {
  discover_lights || return 1
  idx=0
  for arg in "$@"
  do
    if test "$idx" -gt "$(_num_lights_discovered)"
    then
      >&2 echo "ERROR: Not enough lights to set this color level: $idx; ignoring rest"
      return 0
    fi
    >&2 echo "INFO: Setting color for light $idx to $arg"
    _elgato color "$idx" --level "$arg" || return 1
    idx=$((idx+1))
  done
}

# turn_on_all_lights: Turns on all discovered lights.
turn_on_all_lights() {
  discover_lights || return 1
  idx=0
  while test "$idx" -lt "$(_num_lights_discovered)"
  do
    >&2 echo "INFO: Turning on light $idx"
    _elgato on "$idx"
    idx=$((idx+1))
  done
  echo 'on' > "$HOME/.config/elgato/.light_power_state"
}

# turn_on_all_lights: Turns off all discovered lights.
turn_off_all_lights() {
  discover_lights || return 1
  idx=0
  while test "$idx" -lt "$(_num_lights_discovered)"
  do
    >&2 echo "INFO: Turning off light $idx"
    _elgato off "$idx"
    idx=$((idx+1))
  done
  echo 'off' > "$HOME/.config/elgato/.light_power_state"
}

# toggle: Toggles light power status.
toggle() {
  state="$(cat "$HOME/.config/elgato/.light_power_state")"
  case "$state" in
    on)
      turn_off_all_lights
      ;;
    off)
      turn_on_all_lights
      ;;
    *)
      >&2 echo "WARNING: Invalid state: $state; assuming on."
      turn_on_all_lights
      ;;
  esac
}

case "$1" in
  --on)
    turn_on_all_lights
    ;;
  --off)
    turn_off_all_lights
    ;;
  --bright-key-left)
    turn_on_all_lights && set_brightness 40 26 && set_color 5000 3700
    ;;
  --bright-key-right)
    turn_on_all_lights && set_brightness 26 40 && set_color 3700 5000
    ;;
  --soft-key-left)
    turn_on_all_lights && set_brightness 20 14 && set_color 5000 3700
    ;;
  --soft-key-right)
    turn_on_all_lights && set_brightness 14 20 && set_color 3700 5000
    ;;
  --toggle)
    toggle
    ;;
esac
