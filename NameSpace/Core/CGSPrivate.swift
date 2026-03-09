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

// Internal-module version for callers outside this file
func loadCGSSymbol<T>(_ name: String, as type: T.Type) -> T? {
    guard let ptr = dlsym(rtldDefault, name) else { return nil }
    return unsafeBitCast(ptr, to: type)
}

// MARK: - Wrappers

func CGSMainConnectionID() -> CGSConnectionID {
    typealias Fn = @convention(c) () -> CGSConnectionID
    guard let fn = loadSymbol("CGSMainConnectionID", as: Fn.self) else { return 0 }
    return fn()
}

/// Returns array of display dicts; each has a "Spaces" key with space dicts containing "id64".
func CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray {
    typealias Fn = @convention(c) (CGSConnectionID) -> CFArray
    guard let fn = loadSymbol("CGSCopyManagedDisplaySpaces", as: Fn.self) else {
        return [] as CFArray
    }
    return fn(cid)
}

func CGSGetActiveSpace(_ cid: CGSConnectionID) -> CGSSpaceID {
    typealias Fn = @convention(c) (CGSConnectionID) -> CGSSpaceID
    guard let fn = loadSymbol("CGSGetActiveSpace", as: Fn.self) else { return 0 }
    return fn(cid)
}

/// Returns the UUID string of the display that owns this space.
func CGSCopyManagedDisplayForSpace(_ cid: CGSConnectionID, _ spaceID: CGSSpaceID) -> CFString? {
    typealias Fn = @convention(c) (CGSConnectionID, CGSSpaceID) -> CFString?
    guard let fn = loadSymbol("CGSCopyManagedDisplayForSpace", as: Fn.self) else { return nil }
    return fn(cid, spaceID)
}

/// Switches the display (identified by UUID string) to the given space.
func CGSManagedDisplaySetCurrentSpace(
    _ cid: CGSConnectionID,
    _ displayUUID: CFString,
    _ spaceID: CGSSpaceID
) {
    typealias Fn = @convention(c) (CGSConnectionID, CFString, CGSSpaceID) -> Void
    guard let fn = loadSymbol("CGSManagedDisplaySetCurrentSpace", as: Fn.self) else { return }
    fn(cid, displayUUID, spaceID)
}
