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
    func applyPreset(id: UUID) throws
    func isPresetAvailable(id: UUID) -> Bool
    func updatePreset(id: UUID) throws
    func deletePreset(id: UUID) throws
    func newPreset(name: String) throws

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
    }
    let coreGraphicsService: any CoreGraphicsServiceProtocol
    let displayPresetStorage: any DisplayPresetsStorageProtocol

    var displayPresets: [DisplayPreset]

    var displayState: DisplayState = DisplayState(enabledPresetUUID: nil, availablePresetUUIDs: [])

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
            enabledPresetUUID: enabledPresetUUID, availablePresetUUIDs: availablePresetUUIDs)
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
        let presetIndex = try getPresetIndex(id: id)

        let currentDisplaysPreference = try coreGraphicsService.getCurrentDisplaysPreference()
        let newDisplayPreset = DisplayPreset(
            displayPreferences: currentDisplaysPreference, name: displayPresets[presetIndex].name,
            id: displayPresets[presetIndex].id)
        displayPresets[presetIndex] = newDisplayPreset
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        //try refreshDisplayState()
    }

    func newPreset(name: String) throws {
        let currentDisplaysPreference = try coreGraphicsService.getCurrentDisplaysPreference()
        let newDisplayPreset = DisplayPreset(
            displayPreferences: currentDisplaysPreference, name: name)
        displayPresets.append(newDisplayPreset)
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        try refreshDisplayState()
    }

    func deletePreset(id: UUID) throws {
        let index = try getPresetIndex(id: id)

        displayPresets.remove(at: index)
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        try refreshDisplayState()
    }

    // WARN: DO NOT forget to 'try refreshEnabledDisplayPresetUUID()' when adding new functions
    //       (but i guess there is no need to add more functions anyway :) )
}
