import AppKit

// Renders each SF Symbol into TWO PNGs so weather icons can both carry Apple's
// accent colours AND flip with the light/dark theme:
//   <name>.ink.png    full glyph silhouette, white — used as a CSS mask coloured
//                      by var(--text), so it flips with the mode.
//   <name>.color.png  only the saturated accent pixels (sun≈yellow, rain≈blue),
//                      everything neutral is transparent — overlaid on the ink.
// The split is by pixel chroma: coloured pixels -> color layer, white/grey (clouds,
// snow, bolt, moon, fog, wind) -> ink layer only. No per-symbol layer knowledge.

let names = [
  "sun.max.fill","moon.stars.fill","cloud.sun.fill","cloud.moon.fill","cloud.fill",
  "cloud.fog.fill","cloud.drizzle.fill","cloud.rain.fill","cloud.heavyrain.fill",
  "cloud.sun.rain.fill","cloud.moon.rain.fill","cloud.bolt.fill","cloud.bolt.rain.fill",
  "cloud.snow.fill","cloud.sleet.fill","cloud.hail.fill","wind","sun.haze.fill",
  "exclamationmark.triangle.fill"
]
let outDir = CommandLine.arguments[1]
let cfg = NSImage.SymbolConfiguration(pointSize: 200, weight: .regular)
  .applying(.preferringMulticolor())

func newBitmap(_ w: Int, _ h: Int) -> NSBitmapImageRep {
  NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
}

let chromaThreshold = 0.12   // above = coloured accent, below = neutral (ink)

for name in names {
  guard let sym = NSImage(systemSymbolName: name, accessibilityDescription: nil),
        let img = sym.withSymbolConfiguration(cfg) else { print("MISS \(name)"); continue }
  img.isTemplate = false
  let sz = img.size
  let w = Int(sz.width.rounded()), h = Int(sz.height.rounded())

  let src = newBitmap(w, h)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: src)
  img.draw(in: NSRect(origin: .zero, size: sz))
  NSGraphicsContext.restoreGraphicsState()

  let ink = newBitmap(w, h)
  let color = newBitmap(w, h)
  let clear = NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 0)

  for y in 0..<h {
    for x in 0..<w {
      guard let c = src.colorAt(x: x, y: y) else { continue }
      let a = c.alphaComponent
      if a < 0.05 { ink.setColor(clear, atX: x, y: y); color.setColor(clear, atX: x, y: y); continue }
      let r = c.redComponent, g = c.greenComponent, b = c.blueComponent
      let chroma = max(r, max(g, b)) - min(r, min(g, b))
      // Ink = the full silhouette in white (mask uses alpha; var(--text) colours it).
      ink.setColor(NSColor(deviceRed: 1, green: 1, blue: 1, alpha: a), atX: x, y: y)
      // Color = only the saturated accent pixels, in their real colour.
      color.setColor(chroma > chromaThreshold ? c : clear, atX: x, y: y)
    }
  }

  try! ink.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: outDir + "/" + name + ".ink.png"))
  try! color.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: outDir + "/" + name + ".color.png"))
  print("OK \(name)  \(w)x\(h)")
}
