struct Space: Identifiable, Equatable {
    let id: Int       // CGS space ID
    let index: Int    // 1-based display index
    var name: String  // custom name from store
}
