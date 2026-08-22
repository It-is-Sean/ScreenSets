//
//  Logger.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/20.
//

import OSLog

extension Logger {
    private static let subsystem =
        Bundle.main.bundleIdentifier ?? "com.It-is-Sean.ScreenSets"

    static let app = Logger(
        subsystem: subsystem,
        category: "App"
    )

    static let settings = Logger(
        subsystem: subsystem,
        category: "Settings"
    )
    static let storage = Logger(
        subsystem: subsystem,
        category: "Storage"
    )
}
