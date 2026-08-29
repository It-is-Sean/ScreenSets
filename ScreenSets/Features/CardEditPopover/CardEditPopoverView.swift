//
//  CardEditPopover.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/28.
//
import Foundation
import SwiftUI
import OSLog

struct CardEditPopoverView: View {
    @Environment(ScreenSetsService.self)
    private var screenSetsService

    @Environment(\.dismiss)
    private var dismiss

    let preset: DisplayPreset

    @State private var draftName = ""
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canRename: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            header
            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    renameField
                    displayNameList
                    buttons
                }
            }
        }
        .padding(10)
        .frame(minWidth: 250)
        .task(id: preset.id) {
            draftName = preset.name
        }
        .defaultFocus($isNameFocused, true)
    }

    private var header: some View {
        HStack {
            Spacer()

            Text("Details")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private var renameField: some View {
        VStack(alignment: .leading){
            HStack(spacing: 8) {
                
                Image(systemName: "character.cursor.ibeam")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                TextField("Preset name", text: $draftName)
                    .textFieldStyle(.plain)
                    .lineLimit(1)
                    .focused($isNameFocused)
                    .onSubmit {
                        renamePreset()
                    }
                    .onExitCommand {
                        dismiss()
                    }
            }
            .padding(.leading, 11)
            .padding(.trailing, 6)
            .frame(minWidth: 230, minHeight: 36)
            .glassEffect(
                .clear,
                in: .capsule
            )
            .animation(.smooth(duration: 0.2), value: isNameFocused)
        }

    }
    
    private var displayNameList: some View {
        VStack(alignment: .leading, spacing: 4){
            VStack(alignment: .leading, spacing: 6) {
                ForEach(preset.displayPreferences.enumerated(), id: \.element.displayUUID) { index, display in
                    HStack(alignment: .center){
                        Image(systemName: "display")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.trailing, -6)
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text(display.displayName)
                        Spacer()
                    }.padding(.leading, 5)
                }
            }
        }
    }

    private var buttons: some View {
        HStack(alignment: .center, spacing: 12) {
            DeleteButton(presetName: preset.name) {
                try screenSetsService.deletePreset(
                    id: preset.id
                )
            }

            Spacer()
            UpdateButton(presetName: preset.name) {
                try screenSetsService.updatePreset(
                    id: preset.id
                )
            }
            SaveButton {
                renamePreset()
            }
            .disabled(!canRename)
            .opacity(canRename ? 1 : 0.4)
            .help("Rename")
            .accessibilityLabel("Rename preset")

        }
    }
    
    private func renamePreset() {

        guard !trimmedName.isEmpty else {
            return
        }

        guard trimmedName != preset.name else {
            dismiss()
            return
        }

        do {
            try screenSetsService.renamePreset(
                id: preset.id,
                newName: trimmedName
            )
            dismiss()
        } catch {

            Logger.service.error(
                "Failed to rename preset: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
