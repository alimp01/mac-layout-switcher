/// Physical input queued behind a correction keeps native event order. After an
/// explicit Tab/Enter, only physical keys may follow its destination; correction
/// text continues to require its original target and source-text precondition.
public struct InputReplayPolicy {
    public private(set) var followsNavigation = false
    public init() {}
    public mutating func didDeliverNavigation() { followsNavigation = true }
    public func allowsReplay(cancelled: Bool, secure: Bool, originalTargetCurrent: Bool) -> Bool {
        !cancelled && !secure && (followsNavigation || originalTargetCurrent)
    }
}
