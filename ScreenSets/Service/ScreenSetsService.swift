//
//  ScreenSetsService.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/23.
//
import Foundation
import OSLog
import SwiftUI

protocol ScreenSetsServiceProtocol {
    
    var displayPresets: [DisplayPreset] { get }
    var displayState: ScreenSetsService.DisplayState { get }
    func getCurrentDisplayPreferences() throws -> [DisplaySettings]

    func applyPreset(id: UUID) throws
    func isPresetAvailable(id: UUID) -> Bool
    func updatePreset(id: UUID) throws
    func deletePreset(id: UUID) throws
    func newPreset(name: String) throws
    
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

    var displayPresets: [DisplayPreset]

    var displayState: DisplayState = DisplayState(enabledPresetUUID: nil, availablePresetUUIDs: [], onlineDisplayUUIDs: [])

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
        //try refreshDisplayState()
    }

    
    func updatePreset(id: UUID) throws {
        let preset = try getPreset(id: id)

        let currentDisplaysPreference = try coreGraphicsService.getCurrentDisplaysPreference()
        
        preset.displayPreferences = currentDisplaysPreference
        preset.displayUUIDs = currentDisplaysPreference.map(\.displayUUID)

        try displayPresetStorage.saveDisplayPresets(displayPresets)
        try refreshDisplayState()
    }

    func newPreset(name: String) throws {
        let currentDisplaysPreference = try coreGraphicsService.getCurrentDisplaysPreference()
        let newDisplayPreset = DisplayPreset(
            displayPreferences: currentDisplaysPreference, name: name)
        displayPresets.append(newDisplayPreset)
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        try refreshDisplayState()
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
    }
    
    func getValidName(id: UUID, name: String) -> String {
        let baseName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        var candidate = baseName
        var index = 1

        while displayPresets.contains(where: {
            $0.id != id &&
            $0.name.caseInsensitiveCompare(candidate) == .orderedSame
        }) {
            candidate = "\(baseName) (\(index))"
            index += 1
        }

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
    }
    // WARN: DO NOT forget to 'try refreshEnabledDisplayPresetUUID()' when adding new functions
    //       (but i guess there is no need to add more functions anyway :) )
}
