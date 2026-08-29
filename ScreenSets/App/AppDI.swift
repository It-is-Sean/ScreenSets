//
//  AppDI.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/26.
//

import Foundation

struct AppDI {
    let screenSetsService: ScreenSetsService
    let appPreferences: AppPreferences
    let spotlightService: SpotlightService
    static func live(
        defaults: UserDefaults = .standard
    ) -> AppDI {
        let coreGraphicsService = CoreGraphicsService()

        let displayPresetStorage = DisplayPresetsStorage(
            defaults: defaults
        )

        let screenSetsService = ScreenSetsService(
            coreGraphicsService: coreGraphicsService,
            displayPresetStorage: displayPresetStorage
        )

        let appPreferences = AppPreferences(
            defaults: defaults
        )
        let spotlightService = SpotlightService(screenSetsService: screenSetsService)
        
        screenSetsService.onPresetsChanged = {
            [weak spotlightService] in
            Task { @MainActor in
                await spotlightService?.syncEntities()
                
            }
        }

        return AppDI(
            screenSetsService: screenSetsService,
            appPreferences: appPreferences,
            spotlightService: spotlightService
        )
    }
}
