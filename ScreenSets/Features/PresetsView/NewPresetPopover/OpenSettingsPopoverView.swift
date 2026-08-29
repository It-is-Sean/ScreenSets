//
//  OpenSettingView.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/29.
//

import SwiftUI
import OSLog

struct OpenSettingsPopoverView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.openURL)
    private var openURL
    
    var body: some View {
        VStack{
            ContentUnavailableView(
                "No New Presets",
                systemImage: "display",
                description: Text(
                    "Open Settings to add a Preset?"
                )
            )
            .frame(maxWidth: .infinity)
            HStack {
                Button{
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "xmark")
                        
                    }
                }
                .controlSize(.extraLarge)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                Spacer()
                SaveButton {
                    dismiss()
                    guard let url = URL(
                        string: "x-apple.systempreferences:com.apple.Displays-Settings.extension"
                    ) else {
                        Logger.service.error("Failed to open Settings")
                        return
                    }
                    openURL(url)

                }
                .help("Yes")
            }.padding(.leading, 3)
        }.padding()
    }
}

#Preview {
    // OpenSettingView()
}
