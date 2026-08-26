//
//  ScreenSetsService.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/23.
//
import Foundation

protocol ScreenSetsServiceProtocol {
    var displayPresets: [DisplayPreset] { get }
    var enabledDisplayPresetUUID: UUID? { get }

    func applyPreset(id: UUID) throws
    func updatePreset(id: UUID) throws
    func newPreset(name: String) throws

}

enum ScreenSetsServiceError: Error {
    case PresetNotFound
    case ConfictingName
}

@Observable
final class ScreenSetsService: ScreenSetsServiceProtocol {
    let coreGraphicsService: CoreGraphicsServiceProtocol
    let displayPresetStorage: DisplayPresetsStorage

    var displayPresets: [DisplayPreset]
    var enabledDisplayPresetUUID: UUID? = nil

    init(
        coreGraphicsService: CoreGraphicsServiceProtocol,
        displayPresetStorage: DisplayPresetsStorage
    ) {
        self.coreGraphicsService = coreGraphicsService
        self.displayPresetStorage = displayPresetStorage
        do {
            self.displayPresets = try displayPresetStorage.loadDisplayPresets()
        } catch {
            self.displayPresets = displayPresetStorage.initDisplayPresets()
        }
        try? refreshEnabledDisplayPresetUUID()
    }

    func refreshEnabledDisplayPresetUUID() throws {
        let currentDisplaysPreference: [DisplaySettings] =
            try coreGraphicsService.getCurrentDisplaysPreference()

        enabledDisplayPresetUUID =
            displayPresets.first {
                $0.matches(currentDisplaysPreference)
            }?.id
    }

    func applyPreset(id: UUID) throws {
        guard
            let preset = displayPresets.first(where: {
                $0.id == id
            })
        else {
            throw ScreenSetsServiceError.PresetNotFound
        }
        try coreGraphicsService.applyPreset(preset: preset)
        try refreshEnabledDisplayPresetUUID()
    }

    func updatePreset(id: UUID) throws {
        guard
            let presetIndex = displayPresets.firstIndex(where: {
                $0.id == id
            })
        else {
            throw ScreenSetsServiceError.PresetNotFound
        }

        let currentDisplaysPreference = try coreGraphicsService.getCurrentDisplaysPreference()
        let newDisplayPreset = DisplayPreset(
            displayPreferences: currentDisplaysPreference, name: displayPresets[presetIndex].name,
            id: displayPresets[presetIndex].id)
        displayPresets[presetIndex] = newDisplayPreset
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        try refreshEnabledDisplayPresetUUID()
    }

    func newPreset(name: String) throws {
        let currentDisplaysPreference = try coreGraphicsService.getCurrentDisplaysPreference()
        let newDisplayPreset = DisplayPreset(
            displayPreferences: currentDisplaysPreference, name: name)
        displayPresets.append(newDisplayPreset)
        try displayPresetStorage.saveDisplayPresets(displayPresets)
        try refreshEnabledDisplayPresetUUID()
    }

}
