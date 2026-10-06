import Foundation
import SparrowToolbelt
import Tagged

public struct ProfileID: Sendable, Equatable, Hashable {
  public enum Kind: Sendable, Equatable, Hashable {
    case normal
    case incognito
  }

  public init(kind: Kind, token: UUID) {
    self.kind = kind
    self.token = token
  }

  /// A normal profile has its data persisted. The incognito variant is
  /// transcient but may expose some of the same services (e.g. bookmarks)
  /// as its normal variant. This is why they share the same `token`.
  public let kind: Kind

  /// A globally unique identifier for this profile. Note, the special value
  /// of zero refers to the default / initial normal profile.
  public let token: UUID
}

extension ProfileID {
  // TODO: Remove this!!
  public static let `default` = ProfileID(kind: .normal, token: .init(uuidString: "9A3E7702-C45A-4775-9C02-138FE2BAB355")!)
}

extension ProfileID {
  public var normalVariant: ProfileID {
    .init(kind: .normal, token: token)
  }

  public var incognitoVariant: ProfileID {
    .init(kind: .incognito, token: token)
  }
}

extension ProfileID {
  public var isIncognito: Bool {
    kind == .incognito
  }
}

extension ProfileID.Kind: Codable {}
extension ProfileID: Codable {}