import Foundation

public struct PathBuilder {
  init() {}

  public mutating func begin(at point: CGPoint) {
    commands.append(.begin(at: point))
  }

  public mutating func line(to point: CGPoint) {
    commands.append(.line(to: point))
  }

  public mutating func squircleCorner(to point: CGPoint, ending tangentAxis: Axis, steps: SquircleGeometry.Steps = .derived) {
    commands.append(.squircleCorner(to: point, ending: tangentAxis, steps: steps))
  }

  public mutating func end() {
    commands.append(.end)
  }

  var commands = [Path.Command]()
}
