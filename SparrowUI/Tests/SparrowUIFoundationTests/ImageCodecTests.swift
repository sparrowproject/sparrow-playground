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
        <rect width="24" height="16" fill="red"/>
      </svg>
      """.utf8)

    guard let image = await codec.decode(svg) else {
      preconditionFailure("Expected SVG decoding to succeed")
    }
    precondition(image.size == NSSize(width: 24, height: 16))
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

    let invalid = await codec.decode(Data("not an image".utf8))
    precondition(invalid == nil, "Expected invalid data to fail decoding")
    print("Image codec tests passed")
  }
}
