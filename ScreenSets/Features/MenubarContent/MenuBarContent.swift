//
//  MenuBarContent.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/29.
//


import AppKit
import Combine
import OSLog
import SwiftUI
import AppIntents

struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack{
            Text("ScreenSets").font(.headline).foregroundStyle(.secondary)
            Button {
                openWindow(id: "main")
            } label: {
                Label("Open Dashboard", systemImage: "macwindow")
            }.keyboardShortcut("e")
            
            Divider()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Exit ScreenSets", systemImage: "power")
            }
            .keyboardShortcut("q")
        }
    }
}
