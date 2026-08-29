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

@main
struct ScreenSetsApp: App {
    @State private var screenSetsService: ScreenSetsService
    @State private var appPreferences: AppPreferences
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
                .frame(minWidth: 640, idealWidth: 640, maxWidth: 640 ,minHeight: 640, idealHeight: 720, maxHeight: .infinity)
                .containerBackground(for: .window) {
                    AlwaysActiveVisualEffectView()
                        .allowsHitTesting(false)
                }                // Listen to the Notification of system display status changed
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: NSApplication.didChangeScreenParametersNotification
                    )
                ) { _ in
                    do {
                        try screenSetsService.refreshDisplayState()
                    } catch {
                        Logger.service.error(
                            "Failed to refresh display preset: \(error.localizedDescription, privacy: .public)"
                        )
                    }
                }

        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 720)
        .windowResizability(.contentSize)

    }
}
