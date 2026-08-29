//
//  ScreenSetsService.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/23.
//
import AppKit
import Foundation
import OSLog
import SwiftUI

protocol ScreenSetsServiceProtocol {
//    // Hook for SpotlightService
//    var onPresetsChanged: (() -> Void)? { get }
    
    // Get DisplayPresets (all, available, unavilable)
    var displayPresets: [DisplayPreset] { get }
    var availableDisplayPresets: [DisplayPreset] { get }
    var unavailableDisplayPresets: [DisplayPreset] { get}
    
    var displayState: ScreenSetsService.DisplayState { get }
    func getCurrentDisplayPreferences() throws -> [DisplaySettings]

    // Preset Actions
    func applyPreset(id: UUID) throws
    func isPresetAvailable(id: UUID) -> Bool
    func updatePreset(id: UUID) throws
    func deletePreset(id: UUID) throws
    func newPreset(name: String) throws
    
    // Name Related
    func getDefaultName() -> String
    func renamePreset(id: UUID, newName: String) throws

}

enum ScreenSetsServiceError: Error {
    case PresetNotFound
    case ConfictingName
}

@Observable
final class ScreenSetsService: ScreenSetsServiceProtocol {
    struct DisplayState: Equatable {
        var enabledPresetUUID: UUID?
        var availablePresetUUIDs: [UUID]
        var onlineDisplayUUIDs: [UUID]
    }
    let coreGraphicsService: any CoreGraphicsServiceProtocol
    let displayPresetStorage: any DisplayPresetsStorageProtocol

    @ObservationIgnored
    private var displayChangesTask: Task<Void, Never>?

    var displayPresets: [DisplayPreset]

    var displayState: DisplayState = DisplayState(enabledPresetUUID: nil, availablePresetUUIDs: [], onlineDisplayUUIDs: [])
    
    var availableDisplayPresets: [DisplayPreset] {
        let availableIDs = Set(displayState.availablePresetUUIDs)

        return displayPresets.filter { preset in
            availableIDs.contains(preset.id)
        }
    }
    var unavailableDisplayPresets: [DisplayPreset] {
        let availableIDs = Set(displayState.availablePresetUUIDs)

        return displayPresets.filter { preset in
            !availableIDs.contains(preset.id)
        }
    }
    
//    @ObservationIgnored
//    var onPresetsChanged: (() -> Void)?

    init(
        coreGraphicsService: any CoreGraphicsServiceProtocol,
        displayPresetStorage: any DisplayPresetsStorageProtocol
    ) {
        self.coreGraphicsService = coreGraphicsService
        self.displayPresetStorage = displayPresetStorage
        do {
            self.displayPresets = try displayPresetStorage.loadDisplayPresets()
        } catch {
            self.displayPresets = displayPresetStorage.initDisplayPresets()
        }
        try? refreshDisplayState()
        startMonitoringDisplayChanges()
    }

    deinit {
        displayChangesTask?.cancel()
    }

    private func startMonitoringDisplayChanges() {
        displayChangesTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: NSApplication.didChangeScreenParametersNotification
            ) {
                guard let self else {
                    return
                }

                do {
                    try refreshDisplayState()
                } catch {
                    Logger.service.error(
                        "Failed to refresh display state: \(error.localizedDescription, privacy: .public)"
                    )
                }
            }
        }
    }

    private func getPreset(id: UUID) throws -> DisplayPreset {
        guard
            let preset = displayPresets.first(where: {
                $0.id == id
            })
        else {
            throw ScreenSetsServiceError.PresetNotFound
        }
        return preset
    }

    private func getPresetIndex(id: UUID) throws -> Int {
        guard
            let presetIndex = displayPresets.firstIndex(where: {
                $0.id == id
            })
        else {
            throw ScreenSetsServiceError.PresetNotFound
        }
        return presetIndex
    }

    func refreshDisplayState() throws {
        let currentSettings =
            try coreGraphicsService.getCurrentDisplaysPreference()

        let currentDisplayUUIDs =
            currentSettings.map(\.displayUUID)

        let enabledPresetUUID = displayPresets.first {
            $0.matches(currentSettings)
        }?.id

        let availablePresetUUIDs = Array(
            Set(
                displayPresets
                    .filter {
                        $0.isAvaiable(currentDisplayUUIDs: currentDisplayUUIDs)
                    }
                    .map(\.id)
            ))

        displayState = DisplayState(
            enabledPresetUUID: enabledPresetUUID, availablePresetUUIDs: availablePresetUUIDs, onlineDisplayUUIDs: currentDisplayUUIDs)
    }

    func isPresetAvailable(id: UUID) -> Bool {
        var isAvailable = false
        do {
            let preset = try getPreset(id: id)
            isAvailable = try coreGraphicsService.isPresetAvailable(preset: preset)
        } catch {
            Logger.service.error(
                "Failed to check preset availability: \(error.localizedDescription, privacy: .public)"
            )
        }
        return isAvailable
    }

    func applyPreset(id: UUID) throws {
        let preset = try getPreset(id: id)
        try coreGraphicsService.applyPreset(preset: preset)
        try refreshDisplayState()
    }

    
    func updatePreset(id: UUID) throws {
        let preset = try getPreset(id: id)

        let currentDisplaysPreference = try coreGraphicsService.getCurrentDisplaysPreference()
        
        preset.displayPreferences = currentDisplaysPreference
        preset.displayUUIDs = currentDisplaysPreference.map(\.displayUUID)
        
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        try refreshDisplayState()
        // onPresetsChanged?()
        
    }

    func newPreset(name: String) throws {
        let currentDisplaysPreference = try coreGraphicsService.getCurrentDisplaysPreference()
        let newDisplayPreset = DisplayPreset(
            displayPreferences: currentDisplaysPreference, name: name)
        displayPresets.append(newDisplayPreset)
        
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        try refreshDisplayState()
        // onPresetsChanged?()

    }
    
    func getCurrentDisplayPreferences() -> [DisplaySettings]{
        let currentDisplaysPreference = try? coreGraphicsService.getCurrentDisplaysPreference()
        return currentDisplaysPreference ?? []
    }
    

    func deletePreset(id: UUID) throws {
        let index = try getPresetIndex(id: id)

        displayPresets.remove(at: index)
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        try refreshDisplayState()
        // onPresetsChanged?()
    }
    
    func getValidName(id: UUID, name: String) -> String {
        func nameIsUsed(
            _ name: String,
            excluding presetID: UUID
        ) -> Bool {
            displayPresets.contains {
                $0.id != presetID
                    && $0.name.caseInsensitiveCompare(name) == .orderedSame
            }
        }

        func nameByRemovingNumericSuffixes(_ name: String) -> String {
            var baseName = name
            let suffixPattern = #"\s*\([0-9]+\)\s*$"#

            while let suffixRange = baseName.range(
                of: suffixPattern,
                options: .regularExpression
            ) {
                baseName.removeSubrange(suffixRange)
            }

            let normalizedName = baseName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            return normalizedName.isEmpty ? name : normalizedName
        }
        
        let requestedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard nameIsUsed(requestedName, excluding: id) else {
            return requestedName
        }

        let baseName = nameByRemovingNumericSuffixes(requestedName)
        var candidate: String
        var index = 1

        repeat {
            candidate = "\(baseName) (\(index))"
            index += 1
        } while nameIsUsed(candidate, excluding: id)

        return candidate
    }


    func getDefaultName() -> String {
        var index = 1
        let baseName = "New Preset"
        var candidate = baseName
        while displayPresets.contains(where: {
            $0.name.caseInsensitiveCompare(candidate) == .orderedSame
        }) {
            candidate = "\(baseName) (\(index))"
            index += 1
        }
        return candidate
    }
    
    func renamePreset(id: UUID, newName: String) throws {
        var name = newName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !name.isEmpty else {
            return
        }
        name = getValidName(id: id, name: name)
        let preset = try getPreset(id: id)

        guard preset.name != name else {
            return
        }

        preset.name = name
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        // onPresetsChanged?()
    }
    // WARN: DO NOT forget to 'try refreshEnabledDisplayPresetUUID()' when adding new functions
    //       (but i guess there is no need to add more functions anyway :) )
}
