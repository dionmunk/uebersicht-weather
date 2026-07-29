# weather.widget
#
# Top row:  city (left) · condition (right)
# Middle:   current temp + condition icon (same line, left)
# Footer:   active weather alert (left) · today's hi/lo (right)
# Two layouts via the `layout` option: 'hourly' (default, adds the 6-hour strip
# below a divider, 170px) and 'compact' (header block only, 80px).
# The hourly strip cycles its bottom row through temperature, chance of
# precipitation, and wind speed + direction (see `hourlyMetrics`).
# Location auto-detected by IP (ipinfo.io); current weather + hi/lo from Open-Meteo;
# active alerts from the US NWS (api.weather.gov). No API keys.
# Icons are macOS SF Symbols rendered by lib/render-symbols.swift, used as CSS masks
# so they take the theme ink colour (--text) and flip with the mode.
# To pin a location, set LAT/LON/CITY in lib/weather.sh.

command: "weather.widget/lib/weather.sh"

# Enable or disable this widget.
widgetEnabled: true   # true | false

# Layout variant:
#   'hourly'  : city / temp / hi-lo, plus the 6-hour strip below the divider.
#               Two grid rows tall (170px), the shape this widget shipped with.
#   'compact' : the same header block with the strip dropped, so the panel falls
#               back to a single grid row (80px).
# Anything unrecognised behaves as 'hourly'. Switching to 'compact' frees 90px in
# the column: see the weather note in LAYOUT.md before re-stacking what sits below.
layout: 'hourly'   # 'hourly' | 'compact'

# Under the 'hourly' layout the strip's bottom row cycles through these metrics, in
# this order:
#   'temp'   : temperature (°F)
#   'precip' : chance of precipitation (%)
#   'wind'   : wind speed (mph) with a direction arrow
# A metric the API returned no data for is dropped, so a single-entry list pins the
# strip to that metric and never cycles at all.
hourlyMetrics: ['temp', 'precip', 'wind']

# Seconds each metric holds before the strip advances. Temperature is the reading you
# usually want, so it dwells longest and the other two are quick looks on the way back
# round. A metric missing from this map falls back to the temp dwell. The cycle
# freezes while the pointer is over the widget.
hourlyDwellSeconds:
  temp:   15
  precip: 5
  wind:   5

# Total length of the swap between metrics: the values fade out over the first half,
# change while invisible, then fade back in over the second half. 0 swaps instantly.
hourlyFadeSeconds: 1.2

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
  // grid: col 2 · rows 1–2 · 1×2  (see LAYOUT.md)
  top 10px
  left 340px

  color var(--text, #fff)
  text-shadow: 0 1px 1px rgba(20, 1, 1, 0.2)
  font-family -apple-system, BlinkMacSystemFont, system-ui, sans-serif

  .panel
    background var(--panel-bg, rgba(#000, .15))
    -webkit-backdrop-filter: blur(var(--panel-blur, 48px))
    backdrop-filter: blur(var(--panel-blur, 48px))
    border-radius 10px
    box-sizing: border-box
    min-height: 170px      // 'hourly' layout: 2·UNIT + GAP (see LAYOUT.md)

  // 'compact' layout: no hourly strip, so the panel drops to one grid row. The
  // class is toggled by update() from the `layout` option above.
  //
  // The header block measures 65px (topline 12 + temprow 30 + statusrow 16, plus the
  // 3px/4px margins between them). With .panel-stats' 8px top padding that is 73px,
  // so the bottom padding is trimmed 10px → 7px to land the panel on exactly 80px
  // instead of 83px. Beats .panel-stats on specificity (two classes vs one).
  .panel.is-compact
    min-height: 80px
    padding-bottom: 7px

  .is-compact .wx-hourly
    display: none

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
    cursor: pointer          // opens the NWS advisory page (see openUrl)

  // Hover affordance is an underline, not a colour change: update() sets the
  // severity colour inline, which would win over any colour rule here.
  .wx-alert:hover .wx-alert-text
    text-decoration: underline

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


  // Bottom row of each hour column. Its value is rewritten in place as the metric
  // cycle advances, so the row keeps a steady height rather than reflowing.
  .wx-hour-metric
    font-size: 12px
    display: flex
    align-items: center
    justify-content: center
    gap: 3px
    min-height: 14px
    // One direction of the metric cross-fade. --wx-fade is set from
    // hourlyFadeSeconds by startMetricCycle() so JS and CSS stay in step.
    transition: opacity var(--wx-fade, 600ms) ease-in-out

  // Chance of precipitation is tinted with the rain blue sampled straight out of the
  // SF Symbol rain icons (#00CAEC in cloud.rain / heavyrain / drizzle / sun.rain), so
  // the number matches the droplets in the icon above it. The class is toggled per
  // metric by showMetric().
  .wx-hour-metric.is-precip
    color: var(--wx-rain, #00CAEC)

  // Wind direction arrow: shown only for the 'wind' metric, rotated per hour by
  // showMetric(). Masked like the other icons so it takes the theme ink.
  .wx-hour-arrow
    display: none
    width: 10px
    height: 10px
    flex-shrink: 0
    background: var(--wx-icon-ink, var(--text, #fff))
    -webkit-mask-image: url(weather.widget/lib/icons/arrow.up.ink.png)
    -webkit-mask-repeat: no-repeat
    -webkit-mask-position: center
    -webkit-mask-size: contain
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

# Which of the configured metrics actually have readings this refresh. A metric the
# API left out, or returned null for at every hour, is dropped so the strip never
# shows a row of blanks. Temperature is the floor if nothing else survives.
availableMetrics: ->
  wanted = @hourlyMetrics ? ['temp']
  got = (m for m in wanted when @_hours?.some((h) -> h[m]?))
  if got.length then got else ['temp']

# Write one metric into every hour column. Temperature and precipitation are plain
# text; wind adds the direction arrow. Open-Meteo reports the direction the wind
# blows FROM, so the arrow is turned a further 180° to point where it is going.
showMetric: (metric) ->
  for h in (@_hours ? [])
    $arrow = h.$col.find('.wx-hour-arrow')
    $value = h.$col.find('.wx-hour-value')
    h.$col.find('.wx-hour-metric').toggleClass 'is-precip', metric is 'precip'
    switch metric
      when 'precip'
        $arrow.css 'display', 'none'
        $value.text (if h.precip? then "#{Math.round(h.precip)}%" else '—')
      when 'wind'
        if h.wind?
          $value.text "#{Math.round(h.wind)}"
          if h.windDir?
            $arrow.css('display', 'block')
                  .css('transform', "rotate(#{Math.round(h.windDir) + 180}deg)")
          else
            $arrow.css 'display', 'none'
        else
          $arrow.css 'display', 'none'
          $value.text '—'
      else
        $arrow.css 'display', 'none'
        $value.text (if h.temp? then "#{Math.round(h.temp)}°" else '—')

# Half the configured fade, in ms: the length of one direction. Also the CSS
# transition duration, pushed into --wx-fade so the two halves stay in step.
fadeHalfMs: ->
  Math.max(0, (@hourlyFadeSeconds ? 0) * 1000) / 2

# How long one metric holds, in ms. Anything not in the map borrows the temp dwell.
dwellMs: (metric) ->
  secs = @hourlyDwellSeconds?[metric] ? @hourlyDwellSeconds?.temp ? 6
  Math.max(1, secs) * 1000

# Fade the strip out, swap every column's value while it is invisible, then fade back
# in. Straight to the swap when the fade is switched off or nothing is built yet.
fadeToMetric: (metric) ->
  hours = @_hours ? []
  half = @fadeHalfMs()
  if half is 0 or not hours.length
    @showMetric metric
    return
  $vals = (h.$col.find('.wx-hour-metric') for h in hours)
  $v.css('opacity', 0) for $v in $vals
  clearTimeout @_fadeTimer if @_fadeTimer
  @_fadeTimer = setTimeout =>
    @showMetric metric
    $v.css('opacity', 1) for $v in $vals
  , half

# Drop the dwell timer and any in-flight fade, so a refresh that rebuilds the strip
# can't leave an old timer writing into discarded columns.
stopMetricCycle: ->
  clearTimeout @_cycleTimer if @_cycleTimer
  clearTimeout @_fadeTimer if @_fadeTimer
  @_cycleTimer = null
  @_fadeTimer = null

# Rotate the strip through the available metrics, each holding for its own dwell time.
# Chained timeouts rather than one interval, since the dwell varies per metric. Rebuilt
# on every update(), and a no-op beyond the first paint when there is nothing to rotate
# (compact layout, or only one metric with data).
startMetricCycle: (domEl) ->
  @stopMetricCycle()
  metrics = @availableMetrics()
  @_metricIdx = 0 unless @_metricIdx? and @_metricIdx < metrics.length
  hourlyEl = $(domEl).find('.wx-hourly')[0]
  hourlyEl?.style.setProperty '--wx-fade', "#{@fadeHalfMs()}ms"
  @showMetric metrics[@_metricIdx]
  return unless @_hours?.length and metrics.length > 1
  @bindCyclePause domEl
  tick = =>
    # Paused means the pointer is over the widget: re-check shortly instead of
    # advancing, so whatever is being read stays put.
    if @_paused
      @_cycleTimer = setTimeout tick, 500
      return
    @_metricIdx = (@_metricIdx + 1) % metrics.length
    @fadeToMetric metrics[@_metricIdx]
    @_cycleTimer = setTimeout tick, @dwellMs(metrics[@_metricIdx])
  @_cycleTimer = setTimeout tick, @dwellMs(metrics[@_metricIdx])

# Freeze the rotation while the pointer is over the widget, so a reading doesn't
# swap away mid-glance. Bound once: native mouseenter/leave don't bubble, so they
# won't stack across updates.
bindCyclePause: (domEl) ->
  return if @_pauseBound
  panelEl = $(domEl).find('.panel')[0]
  return unless panelEl
  @_pauseBound = true
  panelEl.addEventListener 'mouseenter', => @_paused = true
  panelEl.addEventListener 'mouseleave', => @_paused = false

# Open a URL in the default browser. Übersicht's WKWebView doesn't route
# target="_blank" out, and classic widgets don't get a `run` global, but the
# `uebersicht` run() just POSTs to the local /run/ endpoint, which executes a
# shell command for same-origin requests. A widget fetch is same-origin, so it
# carries the Origin/Referer the endpoint requires.
openUrl: (url) ->
  return unless url
  safe = url.replace /'/g, "'\\''"   # escape single quotes for the shell
  fetch '/run/', method: 'POST', body: "open '#{safe}'"

update: (output, domEl) ->
  # Hide entirely when disabled.
  if not @widgetEnabled
    $(domEl).css('display', 'none')
    return
  $(domEl).css('display', '')
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
    # Clicking the advisory opens the NWS point-forecast page for this location,
    # whose Hazards section links the full text of every active alert. `.off()`
    # first: the element persists across updates, so binding would stack up.
    $alert = div.find('.wx-alert').off 'click'
    if data.lat and data.lon
      url = "https://forecast.weather.gov/MapClick.php?lat=#{data.lat}&lon=#{data.lon}"
      $alert.css('cursor', 'pointer').on 'click', => @openUrl(url)
    else
      $alert.css 'cursor', 'default'
  else
    div.find('.wx-alert').css('display', 'none').off 'click'

  # Layout variant. Only 'compact' changes anything; every other value (including a
  # typo) leaves the widget in its default 'hourly' shape.
  compact = @layout is 'compact'
  div.find('.panel').toggleClass 'is-compact', compact

  # Hourly forecast: the next 6 hours after now. Skipped entirely under 'compact',
  # where the strip is hidden anyway, so there's no point building the columns.
  hourly = data.weather.hourly
  $hourly = div.find('.wx-hourly').empty()
  @_hours = []
  if not compact and hourly?.time and cur.time
    startIdx = hourly.time.findIndex (t) -> t > cur.time
    if startIdx >= 0
      for k in [0...6]
        i = startIdx + k
        continue unless hourly.time[i]?
        hDay  = hourly.is_day[i] is 1
        [hDayIcon, hNightIcon] = @weatherMap[hourly.weather_code[i]] ? ['cloud.fill', 'cloud.fill']
        hIcon = if hDay then hDayIcon else hNightIcon
        $col = $('<div class="wx-hour"><div class="wx-hour-time"></div><div class="wx-hour-icon"><div class="wx-accent"></div></div><div class="wx-hour-metric"><span class="wx-hour-arrow"></span><span class="wx-hour-value"></span></div></div>')
        $col.find('.wx-hour-time').text @formatHour(hourly.time[i])
        hEl = $col.find('.wx-hour-icon')[0]
        hEl.style.background = 'var(--wx-icon-ink, var(--text, #fff))'
        hEl.style.setProperty '-webkit-mask-image', "url(weather.widget/lib/icons/#{hIcon}.ink.png)"
        hEl.style.setProperty '--wx-color', "url(weather.widget/lib/icons/#{hIcon}.color.png)"
        # Park this hour's readings next to its column so the metric cycle can rewrite
        # the values without rebuilding the strip. Keys match the `hourlyMetrics` names.
        @_hours.push
          $col:    $col
          temp:    hourly.temperature_2m?[i]
          precip:  hourly.precipitation_probability?[i]
          wind:    hourly.wind_speed_10m?[i]
          windDir: hourly.wind_direction_10m?[i]
        $hourly.append $col

  # (Re)start the metric rotation for the strip just built.
  @startMetricCycle(domEl)
