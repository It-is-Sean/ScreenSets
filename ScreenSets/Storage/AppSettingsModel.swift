//
//  AppSettingModel.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/20.
//

import Foundation
import OSLog
import ServiceManagement

@Observable
final class AppPreferences {
    private let defaults: UserDefaults

    var showInMenuBar: Bool {
        didSet {
            defaults.set(showInMenuBar, forKey: "showInMenuBar")
        }
    }

    var launchAtLogIn: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }

        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Logger.settings.error("\(error.localizedDescription, privacy:.public)")
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.showInMenuBar =
            defaults.object(forKey: "showInMenuBar") as? Bool ?? false
    }
}
