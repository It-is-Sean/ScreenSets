//
//  AppSettingModel.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/20.
//

import AppKit
import Foundation
import OSLog
import ServiceManagement

@Observable
final class AppPreferences {
    private let defaults: UserDefaults

    @ObservationIgnored
    private var applicationActivationTask: Task<Void, Never>?

    var showInMenuBar: Bool {
        didSet {
            defaults.set(showInMenuBar, forKey: "showInMenuBar")
        }
    }

    private(set) var launchAtLoginStatus: SMAppService.Status

    var isLaunchAtLoginEnabled: Bool {
        launchAtLoginStatus == .enabled
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.showInMenuBar =
            defaults.object(forKey: "showInMenuBar") as? Bool ?? false
        self.launchAtLoginStatus = SMAppService.mainApp.status

        startMonitoringApplicationActivation()
    }

    deinit {
        applicationActivationTask?.cancel()
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = SMAppService.mainApp.status
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        let service = SMAppService.mainApp

        defer {
            refreshLaunchAtLoginStatus()
        }

        do {
            switch (isEnabled, service.status) {
            case (true, .enabled), (false, .notRegistered):
                return
            case (true, _):
                try service.register()
            case (false, _):
                try service.unregister()
            }
        } catch {
            Logger.settings.error(
                "Failed to update launch-at-login status: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func startMonitoringApplicationActivation() {
        applicationActivationTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: NSApplication.didBecomeActiveNotification
            ) {
                guard let self else {
                    return
                }

                refreshLaunchAtLoginStatus()
            }
        }
    }
}
