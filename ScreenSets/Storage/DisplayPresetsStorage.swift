//
//  DisplayPreferenceStorage.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/20.
//

import Foundation
import OSLog


enum DisplayPreferenceStorageError: Error {
    case dataNotFound
}

final class DisplayPresetsStorage {
    private let key = "displayPreferences"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func initDisplayPresets() -> [DisplayPreset] {
        let defaultsDisplayPrefernce: [DisplayPreset] = []
        do { try saveDisplayPresets(defaultsDisplayPrefernce) } catch {
            // TODO: Handel Error from saveAlarmPreference()
        }
        return defaultsDisplayPrefernce
    }

    func loadDisplayPresets() throws -> [DisplayPreset] {
        guard let data = defaults.data(forKey: key),
            let rawValue = try? JSONDecoder().decode([DisplayPreset].self, from: data)
        else {
            throw DisplayPreferenceStorageError.dataNotFound
        }
        return rawValue
    }

    func saveDisplayPresets(_ displayPreferences: [DisplayPreset]) throws {
        guard let data = try? JSONEncoder().encode(displayPreferences) else {
            return
        }
        defaults.set(data, forKey: key)
    }
    

}
