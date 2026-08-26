//
//  PresetsView.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/26.
//

import SwiftUI

struct PresetsView: View {
    @Environment(ScreenSetsService.self)
    private var screenSetsService
    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(text: "Presets")
            ForEach(
                screenSetsService.displayPresets,
                id: \.id
            ) { preset in
                let isEnabled =
                    preset.id == screenSetsService.enabledDisplayPresetUUID

                Button {
                    try? screenSetsService.applyPreset(id: preset.id)
                } label: {
                    HStack {
                        Text(preset.name)

                        Spacer()

                        if isEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
            if screenSetsService.enabledDisplayPresetUUID == nil {
                Button("Save Current Preset", systemImage: "plus") {
                    try? screenSetsService.newPreset(name: UUID().uuidString)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    PresetsView()
}
