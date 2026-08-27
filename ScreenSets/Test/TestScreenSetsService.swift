//
//  TestScreenSetsService.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/27.
//

import Foundation
@MainActor
 final class TestCoreGraphicsService:
     CoreGraphicsServiceProtocol
{
     func isPresetAvailable(preset: DisplayPreset)  -> Bool {
         return true
     }
     
     private var currentSettings: [DisplaySettings]

     init(currentSettings: [DisplaySettings]) {
         self.currentSettings = currentSettings
     }

     func applyPreset(preset: DisplayPreset) throws {
         currentSettings = preset.displayPreferences
     }

     func getCurrentDisplaysPreference() throws
         -> [DisplaySettings]
     {
         currentSettings
     }
 }
@MainActor
 final class TestDisplayPresetsStorage:
     DisplayPresetsStorageProtocol
 {
     private var presets: [DisplayPreset]

     init(presets: [DisplayPreset]) {
         self.presets = presets
     }

     func initDisplayPresets() -> [DisplayPreset] {
         presets
     }

     func loadDisplayPresets() throws -> [DisplayPreset] {
         presets
     }

     func saveDisplayPresets(
         _ presets: [DisplayPreset]
     ) throws {
         self.presets = presets
     }
     static func makeDisplayPresets() -> [DisplayPreset] {
         let displayUUID = UUID(
             uuidString: "37D8832A-2D66-02CA-B9F7-8F30A301B230"
         )!

         let defaultSettings = DisplaySettings(
             displayUUID: displayUUID,
             originX: 0,
             originY: 0,
             mode: DisplayModePreference(
                 width: 1512,
                 height: 982,
                 pixelWidth: 3024,
                 pixelHeight: 1964,
                 refreshRate: 120
             ),
             mirroringStatus: .independent,
             mirroringMaster: nil
         )

         let moreSpaceSettings = DisplaySettings(
             displayUUID: displayUUID,
             originX: 0,
             originY: 0,
             mode: DisplayModePreference(
                 width: 1800,
                 height: 1169,
                 pixelWidth: 3600,
                 pixelHeight: 2338,
                 refreshRate: 120
             ),
             mirroringStatus: .independent,
             mirroringMaster: nil
         )

         return [
             DisplayPreset(
                 displayPreferences: [defaultSettings],
                 name: "Default",
                 id: UUID(
                     uuidString:
                         "00000000-0000-0000-0000-000000000001"
                 )!
             ),
             DisplayPreset(
                 displayPreferences: [moreSpaceSettings],
                 name: "More Space",
                 id: UUID(
                     uuidString:
                         "00000000-0000-0000-0000-000000000002"
                 )!
             ),
         ]
     }
 }

@MainActor
enum PreviewDI {
    static func makeScreenSetsService(
        presets: [DisplayPreset],
        currentSettings: [DisplaySettings]
    ) -> ScreenSetsService {
        ScreenSetsService(
            coreGraphicsService:
                TestCoreGraphicsService(
                    currentSettings: currentSettings
                ),
            displayPresetStorage:
                TestDisplayPresetsStorage(
                    presets: presets
                )
        )
    }
}
