//
//  NewPresetSheetView.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/28.
//

import SwiftUI
import OSLog

struct NewPresetPopoverView: View {
    @Environment(ScreenSetsService.self)
    private var screenSetsService
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var draftName: String = ""
    @FocusState private var isNameFocused: Bool
   
    
    private var trimmedName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canRename: Bool {
        !trimmedName.isEmpty
    }
    
    private var displayCount: Int {
        screenSetsService.displayState.onlineDisplayUUIDs.count
    }
    
    var body: some View {
        VStack(spacing: 10){
            
            PresetPreviewCanvas(
                displayPreferences: screenSetsService.getCurrentDisplayPreferences(),
                borderLineWidth: 2.3,
                cornerRadius: 4,
                numberFontSize: 17
            )
            .frame(height: 170)
            .padding(12)
            .background {
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .fill(.quaternary)
            }
            
            
            HStack{
                Image(systemName: "display.2").font(.system(size: 20, weight: .semibold))
                    .padding(.bottom, 1)
                Text("\(displayCount)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                renameField
            }
            
            Spacer()
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
                    try screenSetsService.newPreset(name: trimmedName)

                    
                }
                .disabled(!canRename)
                .opacity(canRename ? 1 : 0.4)
                .help("Save")
                .accessibilityLabel("Save preset")
            }.padding(.leading, 3)
        }.padding()
        .onAppear {
                if draftName.isEmpty {
                    draftName = screenSetsService.getDefaultName()
                }
                isNameFocused = true
            }
    }
    
    private var renameField: some View {
        HStack(spacing: 8) {
            TextField("Preset name", text: $draftName)
                .textFieldStyle(.plain)
                .lineLimit(1)
                .font(.system(size: 15,design: .rounded)).bold()
                .focused($isNameFocused)
                .onSubmit {
                    submitNewPreset(name: trimmedName)
                    dismiss()
                }
                .onExitCommand {
                    dismiss()
                }
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .frame(minWidth: 230, minHeight: 36)
        .glassEffect(
            .clear,
            in: .capsule
        )
        .animation(.smooth(duration: 0.2), value: isNameFocused)
    }
    
    private func submitNewPreset(name: String){
        do{
            try screenSetsService.newPreset(name: trimmedName)
        } catch {
            Logger.service.error("Submit New Preset Failed: \(error)")
        }
    }
}

