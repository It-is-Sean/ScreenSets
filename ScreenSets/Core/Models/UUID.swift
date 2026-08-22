import ColorSync
import CoreGraphics
//
//  UUID.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/21.
//
import Foundation

extension UUID {
    var cfUUID: CFUUID {
        let string = self.uuidString as CFString
        return CFUUIDCreateFromString(kCFAllocatorDefault, string)
    }

    static func getUUIDFromDisplayID(displayID: CGDirectDisplayID) throws -> UUID {

        guard
            let cfUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue(),
            let uuid = UUID(uuidString: CFUUIDCreateString(nil, cfUUID) as String)
        else {
            throw DisplaysPreferenceServiceError.FailedToGetDisplayUUID
        }
        return uuid
    }
}
