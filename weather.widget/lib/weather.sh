#!/bin/bash
# Location via IP (ipinfo.io); current weather + hi/lo via Open-Meteo; active
# alerts via NWS (api.weather.gov, US only). No API keys. Pin location by setting
# LAT/LON/CITY below (leave empty for auto).

# --- First-run icon generation -------------------------------------------------
# Weather icons are rendered locally from macOS's built-in SF Symbols (see README);
# the PNGs are NOT shipped with this widget. On first run, generate them with the
# Swift renderer. Requires Xcode Command Line Tools (`swift`). Takes ~2s, once.
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$DIR/icons/sun.max.fill.ink.png" ]; then
  mkdir -p "$DIR/icons"
  swift "$DIR/render-symbols.swift" "$DIR/icons" >/dev/null 2>&1
fi

LAT=""
LON=""
CITY=""
UA="ubersicht-weather-widget (personal)"

info=$(curl -s --max-time 6 https://ipinfo.io/json)
if [ -z "$LAT" ]; then
  loc=$(printf '%s' "$info" | grep -oE '"loc": *"[-0-9.]+,[-0-9.]+"' | grep -oE '[-0-9.]+,[-0-9.]+')
  LAT=${loc%,*}; LON=${loc#*,}
fi
[ -z "$CITY" ] && CITY=$(printf '%s' "$info" | sed -nE 's/.*"city": *"([^"]*)".*/\1/p')
[ -z "$LAT" ] && { echo '{"error":"no-location"}'; exit 0; }

wx=$(curl -s --max-time 6 "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,weather_code,is_day&hourly=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min&temperature_unit=fahrenheit&timezone=auto&forecast_days=2")
[ -z "$wx" ] && { echo '{"error":"no-weather"}'; exit 0; }

alerts=$(curl -s --max-time 6 -H "User-Agent: $UA" "https://api.weather.gov/alerts/active?point=${LAT},${LON}")
event=$(printf '%s' "$alerts" | grep -oE '"event": *"[^"]*"' | head -1 | sed -E 's/.*"event": *"([^"]*)".*/\1/')
severity=$(printf '%s' "$alerts" | grep -oE '"severity": *"[^"]*"' | head -1 | sed -E 's/.*: *"([^"]*)".*/\1/')

printf '{"city":"%s","alert":{"event":"%s","severity":"%s"},"weather":%s}' "$CITY" "$event" "$severity" "$wx"
