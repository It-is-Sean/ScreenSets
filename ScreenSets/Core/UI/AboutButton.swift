//
//  AboutButton.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/29.
//


import SwiftUI

struct AboutButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button {
            openWindow(id: "about")
        } label: {
            Label("About ScreenSets", systemImage: "info.circle")
        }
    }
}
