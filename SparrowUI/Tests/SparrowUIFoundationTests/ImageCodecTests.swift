import AppKit
import SparrowUIFoundation

@main
struct ImageCodecTests {
  @MainActor
  static func main() async {
    let codec = ImageCodecs.lossless
    let svg = Data("""
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="16" viewBox="0 0 24 16">
        <style>:root { fill: #ff0000; } .translucent { fill-opacity: 0.5; }</style>
        <rect x="2" y="2" width="20" height="12" rx="3" class="translucent"/>
      </svg>
      """.utf8)

    guard let image = await codec.decode(svg) else {
      preconditionFailure("Expected SVG decoding to succeed")
    }
    precondition(image.size == NSSize(width: 24, height: 16))
    guard let rendered = image.representations.first as? NSBitmapImageRep,
      let pixels = rendered.bitmapData
    else {
      preconditionFailure("Expected SVG to rasterize to a bitmap")
    }
    let offset = 8 * rendered.bytesPerRow + 12 * 4
    precondition(pixels[offset] >= 127 && pixels[offset + 1] == 0 && pixels[offset + 2] == 0,
      "Expected CSS to produce red pixels")
    precondition(abs(Int(pixels[offset + 3]) - 128) <= 1,
      "Expected CSS fill opacity to survive rasterization")
    precondition(pixels[3] == 0, "Expected the canvas background to remain transparent")
    let alphas = stride(from: 3, to: rendered.bytesPerRow * rendered.pixelsHigh, by: 4)
      .map { pixels[$0] }
    precondition(alphas.contains { $0 > 0 && $0 < 127 },
      "Expected antialiased edges to retain partial transparency")
    // Rendering must not discard the retained vector source.
    precondition(image.tiffRepresentation != nil)
    let encodedSVG = await codec.encode(image)
    precondition(encodedSVG == svg, "Expected SVG source to survive encoding unchanged")
    guard let restored = await codec.decode(encodedSVG!) else {
      preconditionFailure("Expected encoded SVG to decode")
    }
    let reencodedSVG = await codec.encode(restored)
    precondition(reencodedSVG == svg)

    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 3,
      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
      isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    bitmap.setColor(NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: 1), atX: 0, y: 0)
    let png = bitmap.representation(using: .png, properties: [:])!
    guard let raster = await codec.decode(png),
      let encodedPNG = await codec.encode(raster),
      let restoredBitmap = NSBitmapImageRep(data: encodedPNG)
    else {
      preconditionFailure("Expected PNG round trip to succeed")
    }
    precondition(encodedPNG.starts(with: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))
    precondition(restoredBitmap.pixelsWide == 2 && restoredBitmap.pixelsHigh == 3)
    let restoredColor = restoredBitmap.colorAt(x: 0, y: 0)!.usingColorSpace(.sRGB)!
    let originalColor = NSBitmapImageRep(data: png)!.colorAt(x: 0, y: 0)!.usingColorSpace(.sRGB)!
    for (actual, expected) in zip(restoredColor.cgColor.components!, originalColor.cgColor.components!) {
      precondition(abs(actual - expected) < 0.01, "Expected PNG pixel color to survive encoding")
    }

    for format: NSBitmapImageRep.FileType in [.jpeg, .gif, .tiff] {
      guard let data = bitmap.representation(using: format, properties: [:]),
        let decoded = await codec.decode(data),
        let encoded = await codec.encode(decoded),
        let restored = NSBitmapImageRep(data: encoded)
      else {
        preconditionFailure("Expected raster format \(format) to decode and encode")
      }
      precondition(encoded.starts(with: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        "Expected raster images to encode as PNG")
      precondition(restored.pixelsWide == 2 && restored.pixelsHigh == 3)
    }

    let blossomURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent().appendingPathComponent("SparrowUIDemo/Resources/blossom-icon.svg")
    let blossom = try! Data(contentsOf: blossomURL)
    guard let blossomImage = await codec.decode(blossom),
      let blossomBitmap = blossomImage.representations.first as? NSBitmapImageRep,
      let blossomPixels = blossomBitmap.bitmapData
    else {
      preconditionFailure("Expected blossom SVG to rasterize")
    }
    precondition(blossomImage.size == NSSize(width: 180, height: 180))
    precondition(stride(from: 3, to: blossomBitmap.bytesPerRow * blossomBitmap.pixelsHigh, by: 4)
      .contains { blossomPixels[$0] > 0 }, "Expected CSS to make the blossom visible")
    let encodedBlossom = await codec.encode(blossomImage)
    precondition(encodedBlossom == blossom)

    let transparentSVG = Data("""
      <svg xmlns="http://www.w3.org/2000/svg" width="8" height="8">
        <rect width="8" height="8" fill="none"/>
      </svg>
      """.utf8)
    guard let transparent = await codec.decode(transparentSVG),
      let transparentBitmap = transparent.representations.first as? NSBitmapImageRep,
      let transparentPixels = transparentBitmap.bitmapData
    else { preconditionFailure("Expected fully transparent SVG to decode") }
    precondition(stride(from: 3, to: transparentBitmap.bytesPerRow * transparentBitmap.pixelsHigh, by: 4)
      .allSatisfy { transparentPixels[$0] == 0 })

    let malformedSVG = await codec.decode(Data("<svg xmlns=\"http://www.w3.org/2000/svg\"><broken>".utf8))
    precondition(malformedSVG == nil)
    let invalid = await codec.decode(Data("not an image".utf8))
    precondition(invalid == nil, "Expected invalid data to fail decoding")
    print("Image codec tests passed")
  }
}
