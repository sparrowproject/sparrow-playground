extension String {
  public var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}