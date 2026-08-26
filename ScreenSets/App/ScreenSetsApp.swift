//
//  ScreenSetsApp.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/20.
//

import SwiftUI

@main
struct ScreenSetsApp: App {
    @State private var screenSetsService: ScreenSetsService
    @State private var appPreferences: AppPreferences
    init(){
        let di = AppDI.live()
        _screenSetsService = State(
            initialValue: di.screenSetsService
        )

        _appPreferences = State(
            initialValue: di.appPreferences
        )
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(screenSetsService)
                .environment(appPreferences)
                .frame(minWidth: 720, minHeight: 520)
                .containerBackground(.thickMaterial, for: .window)

        }
        .windowStyle(.hiddenTitleBar)

    }
}
