//
//  PresetsView.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/26.
//

import SwiftUI
import OSLog
struct PresetsView: View {
    @Environment(\.openURL)
    private var openURL
    @Environment(ScreenSetsService.self)
    private var screenSetsService
    
    @State var showOpenSettingAlert = false

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 320), spacing: 8, alignment: .top)
    ]
    var body: some View {
        VStack(alignment: .leading) {
            if screenSetsService.displayPresets.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading) {
                        ForEach(screenSetsService.displayPresets) { preset in
                            PresetCard(displayPreset: preset)
                        }
                    }.padding(.bottom, 200).padding(.top)
                }
                .contentMargins(.leading, 16, for: .scrollContent)

                .contentMargins(.trailing, 17, for: .scrollContent)
                .scrollEdgeEffectStyle(.soft, for: [.top, .bottom])

            }
        }.safeAreaBar(edge: .top, alignment: .leading) {
            PageTitle(text: "Presets")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 3).padding(.leading)
        }.safeAreaBar(edge: .bottom, alignment: .leading) {
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
        let isNewPresetAvailable = screenSetsService.displayState.enabledPresetUUID == nil
        HStack {
            Spacer()

            Button {
                if isNewPresetAvailable {
                    try? screenSetsService.newPreset(
                        name: UUID().uuidString
                    )
                } else {
                    showOpenSettingAlert = true
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
            }
            .controlSize(.extraLarge)
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .alert("Open Settings to add a preset?", isPresented: $showOpenSettingAlert) {
                    Button("NO", role: .cancel) {}
                    Button("Yes"){
                            guard let url = URL(
                                string: "x-apple.systempreferences:com.apple.Displays-Settings.extension"
                            ) else {
                                Logger.service.error("Failed to open Settings")
                                return
                            }
                        openURL(url)
                   }
            }
        }.padding(.bottom).padding(.trailing)
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
