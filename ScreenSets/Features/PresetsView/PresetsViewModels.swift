//
//  PresetsViewModels.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/26.
//

import SwiftUI
import OSLog
struct CardTitle: View {
    let text: String
    var body: some View {
        HStack{
            Text(text)
                .font(.system(.title, design: .rounded, weight: .semibold))
        }.padding(.leading, 5)
    }
}




struct ApplyButton: View{
    @State private var showAlert = false

    let presetName: String
    let action: () throws -> Void

    var body: some View {
        Button {
            do {
                try action()
            } catch {
                Logger.service.error(
                    "Failed to refresh preset: \(error.localizedDescription, privacy: .public)"
                )
            }
        } label: {
            HStack {
                Text("Apply")
                    .font(.headline)
            }
            .foregroundStyle(.white)
        }
        .controlSize(.large)
        .buttonStyle(.glassProminent)

    }
}


struct EditButton<Content: View> :View {
    @State private var isPresented = false
    
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: "info")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(4)
        }
        .controlSize(.large)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .help("Edit")
        .popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds),
        arrowEdge: .top){
            content()
        }
    }
}

struct PresetCard: View{
    @Environment(ScreenSetsService.self) private var screenSetsService
    let displayPreset: DisplayPreset
    let monitorCount: Int
    
    init(displayPreset: DisplayPreset) {
        self.displayPreset = displayPreset
        self.monitorCount = displayPreset.displayUUIDs.count
    }
    var body: some View {
        HStack{
            HStack{
                VStack(){
                    Image(systemName: "display.2")        .font(.system(size: 20, weight: .semibold)).padding(.bottom,1)
                    Text("\(monitorCount)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }.padding(.leading, 3)
                Spacer()
                VStack(alignment: .trailing){
                    CardTitle(text: displayPreset.name)
                        .padding(.bottom,2)
                    HStack{
                        ApplyButton(presetName: displayPreset.name){
                            try screenSetsService.applyPreset(id: displayPreset.id)
                        }.disabled(!screenSetsService.isPresetAvailable(id: displayPreset.id))
                        EditButton{
                            CardEditPopoverView(preset: displayPreset)
                        }
                    }

                }
            }.padding(15)
            
        }
        .glassEffect(.regular,
                         in: RoundedRectangle(
                             cornerRadius: 20,
                             style: .continuous))
        .frame(minWidth: 180, maxWidth: .infinity)
    }
}

#Preview{
    let previewSamples = TestDisplayPresetsStorage.makeDisplayPresets()
    let displayPreset = TestDisplayPresetsStorage.makeDisplayPresets()[0]

    PresetCard(displayPreset: displayPreset)
    .environment(
            PreviewDI.makeScreenSetsService(
                presets: previewSamples,
                currentSettings:
                    previewSamples[0]
.displayPreferences
            )
        )
}
