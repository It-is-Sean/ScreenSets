//
//  ScreeSetsModels.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/24.
//
import Foundation

struct DisplayModePreference: Codable {
    let width: Int
    let height: Int

    let pixelWidth: Int
    let pixelHeight: Int

    let refreshRate: Double
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
    func matches(_ other: DisplaySettings) -> Bool {
        displayUUID == other.displayUUID && originX == other.originX && originY == other.originY
            && mode.width == other.mode.width && mode.height == other.mode.height
            && mode.pixelWidth == other.mode.pixelWidth
            && mode.pixelHeight == other.mode.pixelHeight
            && abs(mode.refreshRate - other.mode.refreshRate) < 0.01
            && mirroringMaster == other.mirroringMaster
    }
}
final class DisplayPreset: Decodable, Encodable {
    let id: UUID
    let name: String
    var displayUUIDs: [UUID]
    var displayPreferences: [DisplaySettings]

    init(displayPreferences: [DisplaySettings], name: String, id: UUID = UUID()) {
        self.id = id
        var displayUUIDs: [UUID] = []
        for preference in displayPreferences {
            displayUUIDs.append(preference.displayUUID)
        }
        self.displayPreferences = displayPreferences
        self.displayUUIDs = displayUUIDs
        self.name = name
    }
    func isAvaiable(currentDisplayUUIDs: [UUID]) -> Bool {
        if Set(currentDisplayUUIDs) == Set(self.displayUUIDs) {
            return true
        }
        return false
    }

    func matches(_ current: [DisplaySettings]) -> Bool {
        guard displayPreferences.count == current.count else {
            return false
        }

        let currentByID = Dictionary(
            uniqueKeysWithValues: current.map {
                ($0.displayUUID, $0)
            }
        )
        return displayPreferences.allSatisfy { expected in
            guard let actual = currentByID[expected.displayUUID] else {
                return false
            }
            return expected.matches(actual)
        }
    }

}
