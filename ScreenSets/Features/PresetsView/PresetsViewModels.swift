//
//  PresetsViewModels.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/26.
//

import OSLog
import SwiftUI

struct CardTitle: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .font(.system(.title, design: .rounded, weight: .semibold))
        }.padding(.leading, 5)
    }
}

struct ApplyButton: View {
    enum ApplyButtonState: Equatable {
        case active
        case available
        case unavailable
    }
    
    private enum FeedbackPhase: Hashable {
        case applied
        case compact
    }

    private enum AnimationState: Hashable {
        case apply
        case applied
        case active
        case unavailable
    }

    @State private var feedbackPhase: FeedbackPhase?
    @State private var showAlert = false

    let presetName: String
    let state: ApplyButtonState
    let action: () throws -> Void

    private var buttonBorderShape: ButtonBorderShape {
        switch  animationState{
        case .active: .circle
        case .applied: .capsule
        case .apply: .capsule
        case .unavailable: .circle
        }
    }
    
    private var animationState: AnimationState {
        if feedbackPhase == .applied {
            return .applied
        }
        

        if feedbackPhase == .compact {
            return .active
        }

        switch state {
        case .available:
            return .apply
        case .active:
            return .active
        case .unavailable:
            return .unavailable
        }
    }
    
    private var buttonTint: Color?{
        switch animationState {
        case .apply:
                nil
        case .applied:
                .blue
        case .active:
                .blue
        case .unavailable:
                nil
        }
            
    }

    init(presetName: String, isActive: Bool, isAvailable: Bool, action: @escaping () throws -> Void)
    {
        self.presetName = presetName
        self.action = action
        let buttonState: ApplyButtonState =
            if isActive {
                .active
            } else if isAvailable {
                .available
            } else {
                .unavailable
            }
        self.state = buttonState
    }

    var body: some View {
        Button {
            guard state == .available else {
                return
            }
            Task { @MainActor in
                // WARN: This stuck the main process
                await Task.yield()

                do {
                    try action()
                } catch {
                    Logger.service.error(
                        "Failed to apply preset: \(error.localizedDescription, privacy: .public)"
                    )
                }
                feedbackPhase = .applied

                try? await Task.sleep(
                    for: .milliseconds(1250)
                )
                
                feedbackPhase = .compact

                try? await Task.sleep(
                    for: .milliseconds(750)
                )
                feedbackPhase = nil
            }
        } label: {
            ZStack {
                buttonLabel.id(animationState)
                    //.transition(.scale(scale: 0.7).combined(with: .opacity))
                    .transition(.blurReplace.animation(.smooth(duration: 0.6)))

            }

        }.controlSize(.large)
            .buttonStyle(.glass)
            .tint(buttonTint)
            .buttonBorderShape(buttonBorderShape)
            .disabled(state == .unavailable)
            .animation(
                .smooth(duration: 0.4),
                value: animationState
            )

    }
    @ViewBuilder
    
    private var buttonLabel: some View {
        switch animationState {
        case .apply:
            Text("Apply")
                .font(.headline)

        case .applied:
            HStack{
                Image(systemName: "checkmark.seal")
                    .font(.headline).padding(.trailing, -3)
                Text("Applied")
                    .font(.headline)
            }
        case .active:
            Image(systemName: "checkmark.seal")
                .font(.headline)

        case .unavailable:
            Image(systemName: "nosign")
                .font(.headline)
        }
    }
}

struct EditButton<Content: View>: View {
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
        .popover(
            isPresented: $isPresented, attachmentAnchor: .rect(.bounds),
            arrowEdge: .bottom
        ) {
            content()
        }
    }
}

struct PresetCard: View {
    @Environment(ScreenSetsService.self) private var screenSetsService
    let displayPreset: DisplayPreset
    let monitorCount: Int

    init(displayPreset: DisplayPreset) {
        self.displayPreset = displayPreset
        self.monitorCount = displayPreset.displayUUIDs.count
    }
    var body: some View {
        let isAvailable = screenSetsService.displayState.availablePresetUUIDs.contains(
            displayPreset.id)

        let isActive = screenSetsService.displayState.enabledPresetUUID == displayPreset.id

        HStack {
            HStack {
                VStack {
                    PresetPreviewCanvas(
                        displayPreferences: displayPreset.displayPreferences
                    )
                    .frame(width: 100)
                    .padding(12)
                    .background {
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                        .fill(.quaternary)
                    }
                }.padding(.leading, 3)
                Spacer()
                VStack(alignment: .trailing) {
                    CardTitle(text: displayPreset.name)
                        .padding(.bottom, 2)
                    HStack {
                        ApplyButton(
                            presetName: displayPreset.name, isActive: isActive,
                            isAvailable: isAvailable
                        ) {
                            try screenSetsService.applyPreset(id: displayPreset.id)
                        }
                        EditButton {
                            CardEditPopoverView(preset: displayPreset)
                        }
                    }

                }
            }.padding(15)

        }
        .glassEffect(
            .regular.interactive(),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous)
        )
        .frame(minWidth: 180, maxWidth: .infinity)
    }
}

#Preview {
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
