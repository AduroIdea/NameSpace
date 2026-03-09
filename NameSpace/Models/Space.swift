struct Space: Identifiable, Equatable {
    let id: Int       // CGS space ID
    let index: Int    // 1-based display index
    var name: String  // custom name from store
    let type: Int     // 0 = normal, 1 = fullscreen app, 4 = tiled/split view
}
