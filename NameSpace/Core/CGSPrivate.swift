import Foundation
import CoreGraphics
import Darwin

// MARK: - CGS Private API Types

typealias CGSConnectionID = UInt32
typealias CGSSpaceID = UInt64

// MARK: - Dynamic symbol loading

private let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)

private func loadSymbol<T>(_ name: String, as type: T.Type) -> T? {
    guard let ptr = dlsym(rtldDefault, name) else { return nil }
    return unsafeBitCast(ptr, to: type)
}

// Cached symbols — global lets in Swift are lazily initialized once (thread-safe)
private let _cgsMainConnectionID: (@convention(c) () -> CGSConnectionID)? =
    loadSymbol("CGSMainConnectionID", as: (@convention(c) () -> CGSConnectionID).self)

private let _cgsCopyManagedDisplaySpaces: (@convention(c) (CGSConnectionID) -> CFArray)? =
    loadSymbol("CGSCopyManagedDisplaySpaces", as: (@convention(c) (CGSConnectionID) -> CFArray).self)

private let _cgsGetActiveSpace: (@convention(c) (CGSConnectionID) -> CGSSpaceID)? =
    loadSymbol("CGSGetActiveSpace", as: (@convention(c) (CGSConnectionID) -> CGSSpaceID).self)

private let _cgsCopyManagedDisplayForSpace: (@convention(c) (CGSConnectionID, CGSSpaceID) -> CFString?)? =
    loadSymbol("CGSCopyManagedDisplayForSpace", as: (@convention(c) (CGSConnectionID, CGSSpaceID) -> CFString?).self)

private let _cgsManagedDisplaySetCurrentSpace: (@convention(c) (CGSConnectionID, CFString, CGSSpaceID) -> Void)? =
    loadSymbol("CGSManagedDisplaySetCurrentSpace", as: (@convention(c) (CGSConnectionID, CFString, CGSSpaceID) -> Void).self)

// MARK: - Wrappers

func CGSMainConnectionID() -> CGSConnectionID {
    _cgsMainConnectionID?() ?? 0
}

/// Returns array of display dicts; each has a "Spaces" key with space dicts containing "id64".
func CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray {
    _cgsCopyManagedDisplaySpaces?(cid) ?? ([] as CFArray)
}

func CGSGetActiveSpace(_ cid: CGSConnectionID) -> CGSSpaceID {
    _cgsGetActiveSpace?(cid) ?? 0
}

/// Returns the UUID string of the display that owns this space.
func CGSCopyManagedDisplayForSpace(_ cid: CGSConnectionID, _ spaceID: CGSSpaceID) -> CFString? {
    _cgsCopyManagedDisplayForSpace?(cid, spaceID)
}

/// Switches the display (identified by UUID string) to the given space.
func CGSManagedDisplaySetCurrentSpace(
    _ cid: CGSConnectionID,
    _ displayUUID: CFString,
    _ spaceID: CGSSpaceID
) {
    _cgsManagedDisplaySetCurrentSpace?(cid, displayUUID, spaceID)
}
