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
    
    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 16, alignment: .top)
    ]
    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(text: "Presets")
            if screenSetsService.displayPresets.isEmpty
            {
                Spacer()
                emptyState
                Spacer()
            }else{
                ScrollView{
                    LazyVGrid(columns: columns,alignment: .leading){
                        ForEach(screenSetsService.displayPresets){preset in
                            PresetCard(displayPreset: preset)
                        }
                    }.padding(.vertical, 8)
                }
            }
            
            footer
        }
    }
    private var emptyState: some View {
        ContentUnavailableView(
            "No Presets",
            systemImage: "display",
            description: Text(
                "Save the current display configuration to create a preset."
            )
        )
        .frame(maxWidth: .infinity)
    }
    @ViewBuilder
    private var footer: some View {
            HStack {
                Spacer()

                Button{
                    try? screenSetsService.newPreset(
                        name: UUID().uuidString
                    )
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .controlSize(.extraLarge)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .disabled(screenSetsService.enabledDisplayPresetUUID != nil)
                .animation(.easeInOut(duration: 0.2), value: screenSetsService.enabledDisplayPresetUUID != nil)            }
    }
}

#Preview {
    let previewSamples = TestDisplayPresetsStorage.makeDisplayPresets()
    RootView()
        .environment(
            PreviewDI.makeScreenSetsService(
                presets: previewSamples,
                currentSettings:
                    previewSamples[0]
.displayPreferences
            )
        )
}
