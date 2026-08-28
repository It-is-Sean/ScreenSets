//
//  CardEditPopover.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/28.
//
import Foundation
import SwiftUI

struct CardEditPopoverView: View {
    @Environment(ScreenSetsService.self) private var screenSetsService
    let preset: DisplayPreset
    var body: some View {
        VStack(alignment: .center, spacing: 7) {
            HStack {
                Spacer()
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary).padding(.trailing, -3)
                Text("EDIT")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(alignment: .center, spacing: 12) {
                UpdateButton(presetName: preset.name) {
                    try screenSetsService.updatePreset(id: preset.id)
                }
                DeleteButton(presetName: preset.name) {
                    try screenSetsService.deletePreset(id: preset.id)
                }
            }
        }
        .padding(10)
    }
}
