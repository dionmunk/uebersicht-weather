# weather.widget
#
# Top row:  city (left) · condition (right)
# Middle:   current temp + condition icon (same line, left)
# Footer:   active weather alert (left) · today's hi/lo (right)
# Location auto-detected by IP (ipinfo.io); current weather + hi/lo from Open-Meteo;
# active alerts from the US NWS (api.weather.gov). No API keys.
# Icons are macOS SF Symbols rendered by lib/render-symbols.swift, used as CSS masks
# so they take the theme ink colour (--text) and flip with the mode.
# To pin a location, set LAT/LON/CITY in lib/weather.sh.

command: "weather.widget/lib/weather.sh"

refreshFrequency: 900000   # 15 min

# WMO weather code → [day icon, night icon, label]  (SF Symbol names in lib/icons)
weatherMap:
  0:  ['sun.max.fill',        'moon.stars.fill',      'Clear']
  1:  ['sun.max.fill',        'moon.stars.fill',      'Mainly Clear']
  2:  ['cloud.sun.fill',      'cloud.moon.fill',      'Partly Cloudy']
  3:  ['cloud.fill',          'cloud.fill',           'Overcast']
  45: ['cloud.fog.fill',      'cloud.fog.fill',       'Fog']
  48: ['cloud.fog.fill',      'cloud.fog.fill',       'Rime Fog']
  51: ['cloud.drizzle.fill',  'cloud.drizzle.fill',   'Light Drizzle']
  53: ['cloud.drizzle.fill',  'cloud.drizzle.fill',   'Drizzle']
  55: ['cloud.drizzle.fill',  'cloud.drizzle.fill',   'Heavy Drizzle']
  56: ['cloud.sleet.fill',    'cloud.sleet.fill',     'Freezing Drizzle']
  57: ['cloud.sleet.fill',    'cloud.sleet.fill',     'Freezing Drizzle']
  61: ['cloud.rain.fill',     'cloud.rain.fill',      'Light Rain']
  63: ['cloud.rain.fill',     'cloud.rain.fill',      'Rain']
  65: ['cloud.heavyrain.fill','cloud.heavyrain.fill', 'Heavy Rain']
  66: ['cloud.sleet.fill',    'cloud.sleet.fill',     'Freezing Rain']
  67: ['cloud.sleet.fill',    'cloud.sleet.fill',     'Freezing Rain']
  71: ['cloud.snow.fill',     'cloud.snow.fill',      'Light Snow']
  73: ['cloud.snow.fill',     'cloud.snow.fill',      'Snow']
  75: ['cloud.snow.fill',     'cloud.snow.fill',      'Heavy Snow']
  77: ['cloud.snow.fill',     'cloud.snow.fill',      'Snow Grains']
  80: ['cloud.sun.rain.fill', 'cloud.moon.rain.fill', 'Light Showers']
  81: ['cloud.sun.rain.fill', 'cloud.moon.rain.fill', 'Showers']
  82: ['cloud.heavyrain.fill','cloud.heavyrain.fill', 'Heavy Showers']
  85: ['cloud.snow.fill',     'cloud.snow.fill',      'Snow Showers']
  86: ['cloud.snow.fill',     'cloud.snow.fill',      'Snow Showers']
  95: ['cloud.bolt.rain.fill','cloud.bolt.rain.fill', 'Thunderstorm']
  96: ['cloud.bolt.rain.fill','cloud.bolt.rain.fill', 'Thunderstorm']
  99: ['cloud.bolt.rain.fill','cloud.bolt.rain.fill', 'Thunderstorm']

# NWS alert severity → colour. Under a colour scheme these resolve to the status
# hues; under monochrome (--status-* unset) they fall back to the theme ink (--text),
# so the alert goes monochrome with everything else.
severityColor:
  Extreme:  'var(--status-critical, var(--text, #fff))'
  Severe:   'var(--status-elevated, var(--text, #fff))'
  Moderate: 'var(--status-warn, var(--text, #fff))'
  Minor:    'var(--status-warn, var(--text, #fff))'

style: """
  // grid: col 3 · rows 1–2 · 1×2  (see LAYOUT.md)
  top 10px
  left 670px

  color var(--text, #fff)
  text-shadow: 0 1px 1px rgba(20, 1, 1, 0.2)
  font-family -apple-system, BlinkMacSystemFont, system-ui, sans-serif

  .panel
    background var(--panel-bg, rgba(#000, .15))
    -webkit-backdrop-filter: blur(var(--panel-blur, 48px))
    backdrop-filter: blur(var(--panel-blur, 48px))
    border-radius 10px
    box-sizing: border-box
    min-height: 170px      // double height: 2·UNIT + GAP (see LAYOUT.md)

  .panel-stats
    padding 8px 10px 10px
    display: flex          // lets stats-inner fill the panel height

  .stats-inner
    width: 300px
    display: flex
    flex-direction: column   // current info on top, hourly strip at the bottom

  .wx-topline
    display: flex
    justify-content: space-between   // location left, alert right
    align-items: center

  .wx-city
    font-size: 10px
    text-transform: uppercase
    font-weight: bold

  .wx-temprow
    display: flex
    align-items: center            // icon vertically centred with the temp
    justify-content: space-between  // temp left, icon right
    margin-top: 3px

  .wx-statusrow
    display: flex
    justify-content: space-between  // hi/lo left (under temp), status right
    align-items: baseline
    margin-top: 4px

  .wx-cond
    font-size: 13px
    font-weight: 300
    margin-right: 6px   // breathing room to the right of the status text

  .wx-temp
    font-size: 30px
    font-weight: 400
    line-height: 1

  // Two-layer icon: ink layer (background + mask, set in update) flips with --text;
  // .wx-icon::after overlays the coloured accents (sun/rain) on top.
  .wx-icon
    position: relative
    width: 40px
    height: 30px             // same height as the temperature
    flex-shrink: 0
    -webkit-mask-repeat: no-repeat
    -webkit-mask-position: center
    -webkit-mask-size: contain
    filter: drop-shadow(0 1px 1px rgba(0, 0, 0, .12))

  // Coloured accent overlay (sun/rain), stacked over the ink layer of either
  // icon size. Hidden under monochrome (--wx-icon-accent 0), shown under a scheme.
  .wx-accent
    position: absolute
    top: 0
    left: 0
    right: 0
    bottom: 0
    background-image: var(--wx-color)
    background-repeat: no-repeat
    background-position: center
    background-size: contain
    // Gate via `visibility` (not `opacity`): Übersicht's nib plugin overrides the
    // opacity property with a mixin that does `n * 100`, which chokes on a var().
    visibility: var(--wx-icon-accent, hidden)

  // Footer: alert (left) and hi/lo (right) share one line.
  .wx-alert
    display: none            // shown by update() only when an alert is active
    align-items: center
    gap: 4px
    font-size: 10px          // matches the location title
    text-transform: uppercase
    font-weight: normal

  .wx-alert-icon
    width: 12px
    height: 12px
    flex-shrink: 0
    -webkit-mask-repeat: no-repeat
    -webkit-mask-position: center
    -webkit-mask-size: contain
    filter: drop-shadow(0 1px 1px rgba(0, 0, 0, .12))   // matches the other weather icons
    // background-colour + mask-image set inline (severity colour)

  .wx-hilo
    font-size: 13px
    font-weight: 300

  .wx-lo
    margin-left: 12px

  // Hourly strip (next 6 hours) — bottom-anchored, one column per hour.
  .wx-hourly
    position: relative
    display: flex
    justify-content: space-between
    margin-top: auto         // push to the bottom of the double-height panel
    padding-top: 12px        // gap from the divider line down to the hour columns

  // Divider drawn like the base bar: same --level-base grey + the same soft shadow.
  .wx-hourly::before
    content: ''
    position: absolute
    top: 0
    left: 0
    right: 0
    height: 1px
    background: var(--level-base, rgba(#fff, .2))
    box-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)

  .wx-hour
    flex: 1
    display: flex
    flex-direction: column
    align-items: center
    gap: 6px

  .wx-hour-time
    font-size: 10px
    text-transform: uppercase
    font-weight: bold
    color: var(--text-secondary, rgba(#fff, .5))

  .wx-hour-icon
    position: relative
    width: 26px
    height: 21px
    margin-top: 2px          // 8px above the icon (6px gap + 2px)
    margin-bottom: 1px       // 7px below the icon (6px gap + 1px)
    flex-shrink: 0
    -webkit-mask-repeat: no-repeat
    -webkit-mask-position: center
    -webkit-mask-size: contain
    filter: drop-shadow(0 1px 1px rgba(0, 0, 0, .12))


  .wx-hour-temp
    font-size: 12px
    font-weight: 300
"""

render: -> """
  <div class="panel panel-stats">
    <div class="stats-inner">
      <div class="wx-topline">
        <div class="wx-city"></div>
        <div class="wx-alert"><span class="wx-alert-icon"></span><span class="wx-alert-text"></span></div>
      </div>
      <div class="wx-temprow">
        <div class="wx-temp"></div>
        <div class="wx-icon"><div class="wx-accent"></div></div>
      </div>
      <div class="wx-statusrow">
        <div class="wx-hilo"><span class="wx-hi"></span><span class="wx-lo"></span></div>
        <div class="wx-cond"></div>
      </div>
      <div class="wx-hourly"></div>
    </div>
  </div>
"""

# Format an ISO local hour ("2026-07-22T13:00") as "1 PM".
formatHour: (iso) ->
  h = parseInt(iso.slice(11, 13), 10)
  ampm = if h >= 12 then 'PM' else 'AM'
  h12 = h % 12
  h12 = 12 if h12 is 0
  "#{h12} #{ampm}"

update: (output, domEl) ->
  div = $(domEl)
  try
    data = JSON.parse (output or '').trim()
  catch e
    return
  return if not data or data.error or not data.weather
  cur   = data.weather.current
  daily = data.weather.daily
  return unless cur and daily

  temp = Math.round(cur.temperature_2m)
  hi   = Math.round(daily.temperature_2m_max[0])
  lo   = Math.round(daily.temperature_2m_min[0])
  day  = cur.is_day is 1
  [iconDay, iconNight, label] = @weatherMap[cur.weather_code] ? ['cloud.fill', 'cloud.fill', '—']
  icon = if day then iconDay else iconNight

  div.find('.wx-city').text (data.city or '')
  div.find('.wx-temp').text "#{temp}°"
  div.find('.wx-cond').text label
  div.find('.wx-hi').text "H:#{hi}°"
  div.find('.wx-lo').text "L:#{lo}°"
  iconEl = div.find('.wx-icon')[0]
  if iconEl
    # Ink layer: --wx-icon-ink lets a scheme tint the monochrome glyph; else --text.
    iconEl.style.background = 'var(--wx-icon-ink, var(--text, #fff))'
    iconEl.style.setProperty '-webkit-mask-image', "url(weather.widget/lib/icons/#{icon}.ink.png)"
    iconEl.style.setProperty '--wx-color', "url(weather.widget/lib/icons/#{icon}.color.png)"

  # Active weather alert (NWS) — coloured by severity, hidden when none.
  alert = data.alert
  if alert and alert.event
    color = @severityColor[alert.severity] ? 'var(--status-warn, var(--text, #fff))'
    div.find('.wx-alert').css 'display', 'flex'
    div.find('.wx-alert-text').text(alert.event).css 'color', color
    # Mask against the .color.png (the saturated triangle) not .ink.png: it keeps the
    # exclamation mark as a transparent cutout, so the severity fill shows it.
    div.find('.wx-alert-icon')
      .css('background', color)
      .css('-webkit-mask-image', 'url(weather.widget/lib/icons/exclamationmark.triangle.fill.color.png)')
  else
    div.find('.wx-alert').css 'display', 'none'

  # Hourly forecast — the next 6 hours after now.
  hourly = data.weather.hourly
  $hourly = div.find('.wx-hourly').empty()
  if hourly?.time and cur.time
    startIdx = hourly.time.findIndex (t) -> t > cur.time
    if startIdx >= 0
      for k in [0...6]
        i = startIdx + k
        continue unless hourly.time[i]?
        hTemp = Math.round(hourly.temperature_2m[i])
        hDay  = hourly.is_day[i] is 1
        [hDayIcon, hNightIcon] = @weatherMap[hourly.weather_code[i]] ? ['cloud.fill', 'cloud.fill']
        hIcon = if hDay then hDayIcon else hNightIcon
        $col = $('<div class="wx-hour"><div class="wx-hour-time"></div><div class="wx-hour-icon"><div class="wx-accent"></div></div><div class="wx-hour-temp"></div></div>')
        $col.find('.wx-hour-time').text @formatHour(hourly.time[i])
        $col.find('.wx-hour-temp').text "#{hTemp}°"
        hEl = $col.find('.wx-hour-icon')[0]
        hEl.style.background = 'var(--wx-icon-ink, var(--text, #fff))'
        hEl.style.setProperty '-webkit-mask-image', "url(weather.widget/lib/icons/#{hIcon}.ink.png)"
        hEl.style.setProperty '--wx-color', "url(weather.widget/lib/icons/#{hIcon}.color.png)"
        $hourly.append $col
