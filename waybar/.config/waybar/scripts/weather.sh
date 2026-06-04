#!/usr/bin/env bash
# Weather via wttr.in (auto IP geolocation, metric units).
# Caches the JSON response for 30 minutes to stay polite to wttr.in.

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather.json"
TTL=1800
mkdir -p "$(dirname "$CACHE")"

age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
if [ ! -s "$CACHE" ] || [ "$age" -gt "$TTL" ]; then
  raw="$(curl -fsSL --max-time 10 "https://wttr.in/?format=j1" 2>/dev/null)"
  [ -n "$raw" ] && printf '%s' "$raw" > "$CACHE"
fi

if [ ! -s "$CACHE" ]; then
  jq -nc '{text: " ?", alt: "unknown", tooltip: "Weather unavailable", class: "unknown"}'
  exit 0
fi

read -r temp feels code humidity wind wdir city country mint maxt desc < <(
  jq -r '
    [.current_condition[0].temp_C,
     .current_condition[0].FeelsLikeC,
     .current_condition[0].weatherCode,
     .current_condition[0].humidity,
     .current_condition[0].windspeedKmph,
     .current_condition[0].winddir16Point,
     (.nearest_area[0].areaName[0].value     | gsub(" "; "_")),
     (.nearest_area[0].country[0].value      | gsub(" "; "_")),
     .weather[0].mintempC,
     .weather[0].maxtempC,
     (.current_condition[0].weatherDesc[0].value | gsub(" "; "_"))
    ] | @tsv
  ' "$CACHE"
)
city="${city//_/ }"
country="${country//_/ }"
desc="${desc//_/ }"

case "$code" in
  113)                                                            icon="";  klass="sunny" ;;
  116)                                                            icon="";  klass="partly-cloudy" ;;
  119)                                                            icon="";  klass="cloudy" ;;
  122)                                                            icon="";  klass="overcast" ;;
  143|248|260)                                                    icon="";  klass="fog" ;;
  176|263|266|281|284|293|296|299|302|305|308|311|314|317|350|353|356|359|362|365|368)
                                                                  icon="";  klass="rainy" ;;
  179|182|185|227|230|320|323|326|329|332|335|338|371|374|377|386|389|392|395)
                                                                  icon=""; klass="snowy" ;;
  200|389|392)                                                    icon="";  klass="thunder" ;;
  *)                                                              icon="";  klass="unknown" ;;
esac

text="$icon $temp°"
tooltip="$(printf '<b>%s, %s</b>\n%s · %s°C (feels %s°)\nLow %s° · High %s°\n %s%%   %s km/h %s' \
  "$city" "$country" "$desc" "$temp" "$feels" "$mint" "$maxt" "$humidity" "$wind" "$wdir")"

jq -nc \
  --arg t "$text" \
  --arg tt "$tooltip" \
  --arg c "$klass" \
  '{text:$t, alt:$c, tooltip:$tt, class:$c}'
