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
    @Environment(ScreenSetsService.self)
    private var screenSetsService
    
    var body: some View {
        VStack{
            Text("ScreenSets").font(.headline).foregroundStyle(.secondary)
            if screenSetsService.availableDisplayPresets.isEmpty {
                Button("No Available Presets") {}
                    .disabled(true)
            } else {
                ForEach(screenSetsService.availableDisplayPresets) { preset in
                    Button {
                        do {
                            try screenSetsService.applyPreset(id: preset.id)
                        } catch {
                            Logger.service.error(
                                "Failed to apply preset: \(error)"
                            )
                        }
                    } label: {
                        if screenSetsService
                            .displayState
                            .enabledPresetUUID == preset.id
                        {
                            Label(preset.name, systemImage: "checkmark")
                        } else {
                            Text(preset.name)
                        }
                    }
                }
            }
            Divider()
            AboutButton()
            
            Button {
                openWindow(id: "main")
            } label: {
                Label("Open Dashboard", systemImage: "macwindow")
            }.keyboardShortcut("e")
            

            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Exit ScreenSets", systemImage: "power")
            }
            .keyboardShortcut("q")
        }
    }
}
