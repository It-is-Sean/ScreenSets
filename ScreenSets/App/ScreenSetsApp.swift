//
//  ScreenSetsApp.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/20.
//

import AppKit
import Combine
import OSLog
import SwiftUI
import AppIntents

@main
struct ScreenSetsApp: App {
    @State private var screenSetsService: ScreenSetsService
    @State private var appPreferences: AppPreferences
    private let spotlightSevice: SpotlightService
    
    private struct AlwaysActiveVisualEffectView: NSViewRepresentable {
        var material: NSVisualEffectView.Material = .underWindowBackground

        func makeNSView(context: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            configure(view)
            return view
        }

        func updateNSView(
            _ nsView: NSVisualEffectView,
            context: Context
        ) {
            configure(nsView)
        }

        private func configure(_ view: NSVisualEffectView) {
            view.material = material
            view.blendingMode = .behindWindow
            view.state = .active
        }
    }

    init() {
        let di = AppDI.live()
        spotlightSevice = di.spotlightService
        _screenSetsService = State(
            initialValue: di.screenSetsService
        )

        _appPreferences = State(
            initialValue: di.appPreferences
        )
        
        let dependency: any SpotlightServiceProtocol = di.spotlightService
        AppDependencyManager.shared.add(
            key: SpotlightDependencyKey.value,
            dependency: dependency
        )
        ScreenSetsShortcuts.updateAppShortcutParameters()
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(screenSetsService)
                .environment(appPreferences)
                .frame(minWidth: 640, idealWidth: 640, maxWidth: 640 ,minHeight: 640, idealHeight: 720, maxHeight: .infinity)
                .containerBackground(for: .window) {
                    AlwaysActiveVisualEffectView()
                        .allowsHitTesting(false)
                }                // Listen to the Notification of system display status changed
                .task {
                    await spotlightSevice.syncEntities()
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: NSApplication.didChangeScreenParametersNotification
                    )
                ) { _ in
                    Task { @MainActor in
                        do {
                            try screenSetsService.refreshDisplayState()
                            await spotlightSevice.syncEntities()
                        } catch {
                            Logger.service.error(
                                "Failed to refresh display preset: \(error.localizedDescription, privacy: .public)"
                            )
                        }
                    }
                }

        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 720)
        .windowResizability(.contentSize)

    }
}
