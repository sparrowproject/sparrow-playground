import Foundation

public struct SymbolSource: Sendable, Equatable, Hashable {
  #if os(macOS)
  public init(
    systemName: String,
    size: CGFloat,
    weight: Font.Weight = .regular,
  ) {
    self.systemName = systemName
    self.size = size
    self.weight = weight
  }
  #elseif os(Windows)
  public init(
    glyph: String,
    size: CGFloat,
    weight: Font.Weight = .regular,
  ) {
    self.glyph = glyph
    self.size = size
    self.weight = weight
  }
  #endif

  #if os(macOS)
  public let systemName: String
  #elseif os(Windows)
  public let glyph: String
  #endif

  public let size: CGFloat
  public let weight: Font.Weight
}