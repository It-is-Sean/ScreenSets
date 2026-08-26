//
//  DisplaysPreferenceService.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/20.
//
import Foundation
import ColorSync
import CoreGraphics

protocol CoreGraphicsServiceProtocol {
    func applyPreset(preset: DisplayPreset) throws
    func getCurrentDisplaysPreference() throws -> [DisplaySettings]

}

enum CoreGraphicServiceError: Error {
    case InitDisplayConfigureationError
    case FailedToGetDisplayModes
    case FailedToGetDisplayUUID
    case NoMatchingMode
    case MissingDisplay
    case FailedToSetDisplayOrigin
    case FailedToSetDisplayMode
    case FailedToSetMirroringMaster
    case FailedToSaveConfiguration
}

final class CoreGraphicsService: CoreGraphicsServiceProtocol {

    private func getCurrentDisplayDirectIDs() -> [CGDirectDisplayID] {
        // WARN: U should check the value returned by CoreGraphics
        var displayCount: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &displayCount)
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetOnlineDisplayList(displayCount, &displayIDs, &displayCount)
        return displayIDs
    }

    private func getCurrentDisplayUUIDs() throws -> [UUID] {
        let displayIDs = getCurrentDisplayDirectIDs()
        return try displayIDs.compactMap { displayID in
            return try UUID.getUUIDFromDisplayID(displayID: displayID)
        }
    }

    private func getMatchedMode(settings: DisplaySettings) throws -> CGDisplayMode {
        let directDisplayID = CGDisplayGetDisplayIDFromUUID(settings.displayUUID.cfUUID)
        let options = [
              kCGDisplayShowDuplicateLowResolutionModes: true
          ] as CFDictionary
        
        guard let modes = CGDisplayCopyAllDisplayModes(directDisplayID, options) as? [CGDisplayMode]
        else {
            throw CoreGraphicServiceError.FailedToGetDisplayModes
        }

        guard
            let matchedMode = modes.first(where: {
                $0.width == settings.mode.width && $0.height == settings.mode.height
                    && $0.pixelWidth == settings.mode.pixelWidth
                    && $0.pixelHeight == settings.mode.pixelHeight
                    && abs($0.refreshRate - settings.mode.refreshRate) < 0.01
            })
        else {
            throw CoreGraphicServiceError.NoMatchingMode
        }
        return matchedMode

    }

    private func configureDisplay(config: CGDisplayConfigRef, settings: DisplaySettings) throws {
        let directDisplayID = CGDisplayGetDisplayIDFromUUID(settings.displayUUID.cfUUID)

        // Check & get matched mode
        let matchedMode = try getMatchedMode(settings: settings)

        // Configure display origin
        guard
            CGConfigureDisplayOrigin(config, directDisplayID, settings.originX, settings.originY)
                == .success
        else {
            throw CoreGraphicServiceError.FailedToSetDisplayOrigin
        }

        // Configure display mode
        guard
            CGConfigureDisplayWithDisplayMode(config, directDisplayID, matchedMode, nil) == .success
        else {
            throw CoreGraphicServiceError.FailedToSetDisplayMode
        }

        // Configure display mirroring
        if settings.mirroringMaster != nil {
            let mirroringMaterDirectID = CGDisplayGetDisplayIDFromUUID(
                settings.mirroringMaster?.cfUUID)
            guard
                CGConfigureDisplayMirrorOfDisplay(config, directDisplayID, mirroringMaterDirectID)
                    == .success
            else {
                throw CoreGraphicServiceError.FailedToSetMirroringMaster
            }
        } else {
            // UNSET THE POTENTIAL MIRRORING STAUS
            guard
                CGConfigureDisplayMirrorOfDisplay(config, directDisplayID, kCGNullDirectDisplay)
                    == .success
            else {
                throw CoreGraphicServiceError.FailedToSetMirroringMaster
            }
        }
    }

    // TODO: Use uuid to get the preset instead to make sure ViewModels are not dependent on the Storage
    func applyPreset(preset: DisplayPreset) throws {
        let currentDisplayUUIDs = try getCurrentDisplayUUIDs()
        guard preset.isAvaiable(currentDisplayUUIDs: currentDisplayUUIDs) else {
            throw CoreGraphicServiceError.MissingDisplay
        }

        // Start Transaction
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config
        else {
            throw CoreGraphicServiceError.InitDisplayConfigureationError
        }

        do {
            // Apply config to each display
            for displaySettings in preset.displayPreferences {
                try configureDisplay(config: config, settings: displaySettings)
            }

        } catch {
            // Cancel the transaction
            CGCancelDisplayConfiguration(config)
            throw error
        }
        // If no error is thrown, save the configuration
        guard CGCompleteDisplayConfiguration(config, .permanently) == .success else {
            throw CoreGraphicServiceError.FailedToSaveConfiguration
        }
    }

    private func getDisplaySetting(displayID: CGDirectDisplayID) throws -> DisplaySettings {
        // get UUID
        let id: UUID = try UUID.getUUIDFromDisplayID(displayID: displayID)

        // Get current display placements
        let bounds = CGDisplayBounds(displayID)
        // WARN: bounds.origin.x and .y is a FLOAT VALUE, IDK whether it is a safe convert
        let originX: Int32 = Int32(bounds.origin.x)
        let originY: Int32 = Int32(bounds.origin.y)

        // Get current display mode
        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            throw CoreGraphicServiceError.FailedToGetDisplayModes
        }
        let modePreference = DisplayModePreference(
            width: mode.width, height: mode.height, pixelWidth: mode.pixelWidth,
            pixelHeight: mode.pixelHeight, refreshRate: mode.refreshRate)

        // Get mirroring settings
        var mirroringMaster: UUID? = nil
        if CGDisplayIsInMirrorSet(displayID) != 0 {  // WARN: DO NOT USE == 1: CoreGraphics.CGDisplayIsInMirrorSet return a C-style bool, which can be any value but only 0 meaning false
            let masterID = CGDisplayMirrorsDisplay(displayID)
            if masterID != kCGNullDirectDisplay {
                mirroringMaster = try UUID.getUUIDFromDisplayID(displayID: masterID)
            }
        }

        let displaySetting = DisplaySettings(
            displayUUID: id, originX: originX, originY: originY, mode: modePreference,
            mirroringMaster: mirroringMaster)
        return displaySetting
    }

    func getCurrentDisplaysPreference() throws -> [DisplaySettings] {
        let displayDirectIDs = getCurrentDisplayDirectIDs()
        var displaysPreference: [DisplaySettings] = []
        for directID in displayDirectIDs {
            displaysPreference.append(try getDisplaySetting(displayID: directID))
        }

        return displaysPreference

    }
}
