//
//  ScreenSetsApp.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/20.
//

import AppKit
import Combine
import SwiftUI
// import AppIntents

@main
struct ScreenSetsApp: App {
    @State private var screenSetsService: ScreenSetsService
    @State private var appPreferences: AppPreferences
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
    // private let spotlightService: SpotlightService
    
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
    
    @MainActor
    private final class AppDelegate: NSObject,
        NSApplicationDelegate,
        ObservableObject
    {
        @Published private(set) var mainWindowLaunchBehavior:
            SceneLaunchBehavior = .suppressed

        func applicationDidFinishLaunching(_ notification: Notification) {
            DispatchQueue.main.async { [weak self] in
                self?.mainWindowLaunchBehavior = .presented
            }
        }
        
        func applicationShouldTerminateAfterLastWindowClosed(
            _ sender: NSApplication
        ) -> Bool {
            false
        }
    }

    init() {
        let di = AppDI.live()
        // spotlightService = di.spotlightService
        _screenSetsService = State(
            initialValue: di.screenSetsService
        )

        _appPreferences = State(
            initialValue: di.appPreferences
        )
        
//        let dependency: any SpotlightServiceProtocol = di.spotlightService
//        AppDependencyManager.shared.add(
//            key: SpotlightDependencyKey.value,
//            dependency: dependency
//        )
//        ScreenSetsShortcuts.updateAppShortcutParameters()
    }
    var body: some Scene {
        Window("ScreenSets", id: "main") {
            RootView()
                .environment(screenSetsService)
                .environment(appPreferences)
                .frame(minWidth: 580, idealWidth: 580, maxWidth: 580 ,minHeight: 640, idealHeight: 720, maxHeight: .infinity)
                .containerBackground(for: .window) {
                    AlwaysActiveVisualEffectView()
                        .allowsHitTesting(false)
                }
//                .task {
//                    await spotlightService.syncEntities()
//                }
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    DispatchQueue.main.async {
                        NSApp.activate()
                    }
                }
                .onDisappear {
                    NSApp.setActivationPolicy(
                        appPreferences.showInMenuBar
                            ? .accessory
                            : .regular
                    )
                }

        }
        .defaultLaunchBehavior(
            appPreferences.showInMenuBar
                ? appDelegate.mainWindowLaunchBehavior
                : .presented
        )
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 720)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutButton()
            }
        }
        
        Window("About The App", id: "about") {
            AboutView()
                .containerBackground(.thickMaterial, for: .window)
    
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
        
        MenuBarExtra("ScreenSets", systemImage: "display.2",isInserted: $appPreferences.showInMenuBar) {
            MenuBarContent()
                .environment(screenSetsService)
        }
    }
}
