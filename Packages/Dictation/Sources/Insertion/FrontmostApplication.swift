internal protocol FrontmostApplication: Sendable {
    func frontmostPID() -> Int32?
}
