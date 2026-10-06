extension Array where Element == Task<Void, Never> {
  public func joined() -> Task<Void, Never> {
    .init {
      for task in self {
        await task.value
      }
    }
  }
}