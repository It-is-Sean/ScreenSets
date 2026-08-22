//
//  DisplayPreferenceStorage.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/20.
//

import Foundation
import OSLog

struct DisplayModePreference: Codable {
    let width: Int
    let height: Int

    let pixelWidth: Int
    let pixelHeight: Int

    let refreshRate: Double
}
enum DisplayPreferenceStorageError: Error {
    case dataNotFound
}
final class DisplaySettings: Decodable, Encodable {
    let displayUUID: UUID
    let originX: Int32
    let originY: Int32
    let mode: DisplayModePreference
    let mirroringMaster: UUID?
    init(
        displayUUID: UUID, originX: Int32, originY: Int32, mode: DisplayModePreference,
        mirroringMaster: UUID?
    ) {
        self.displayUUID = displayUUID
        self.originX = originX
        self.originY = originY
        self.mode = mode
        self.mirroringMaster = mirroringMaster
    }
}
final class DisplayPreset: Decodable, Encodable {
    let id: UUID
    let displayUUIDs: [UUID]
    let displayPreferences: [DisplaySettings]
    init(displayPreferences: [DisplaySettings]) {
        self.id = UUID()
        var displayUUIDs: [UUID] = []
        for preference in displayPreferences {
            displayUUIDs.append(preference.displayUUID)
        }
        self.displayPreferences = displayPreferences
        self.displayUUIDs = displayUUIDs
    }
    func isAvaiable(currentDisplayUUIDs: [UUID]) -> Bool {
        if Set(currentDisplayUUIDs) == Set(self.displayUUIDs) {
            return true
        }
        return false
    }
}
final class DisplayPresetsStorage {
    private let key = "displayPreferences"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func initDisplayPreference() -> [DisplayPreset] {
        let defaultsDisplayPrefernce: [DisplayPreset] = []
        do { try saveAlarmPreference(defaultsDisplayPrefernce) } catch {
            // TODO: Handel Error from saveAlarmPreference()
        }

        return defaultsDisplayPrefernce
    }

    func loadDisplayPreference() throws -> [DisplayPreset] {
        guard let data = defaults.data(forKey: key),
            let rawValue = try? JSONDecoder().decode([DisplayPreset].self, from: data)
        else {
            throw DisplayPreferenceStorageError.dataNotFound
        }
        return rawValue
    }

    func saveAlarmPreference(_ displayPreferences: [DisplayPreset]) throws {
        guard let data = try? JSONEncoder().encode(displayPreferences) else {
            return
        }
        defaults.set(data, forKey: key)
    }

}
