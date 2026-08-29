//
//  AboutButton.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/29.
//


import AppKit
import SwiftUI

struct AboutButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button {
            openWindow(id: "about")

            // A menu bar item can open a window without activating the app.
            // Wait until the menu has dismissed, then make the About window key.
            Task { @MainActor in
                await Task.yield()
                NSApp.activate()
            }
        } label: {
            Label("About ScreenSets", systemImage: "info.circle")
        }
    }
}
