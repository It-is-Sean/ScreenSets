//
//  NavigationView.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/24.
//

import SwiftUI

struct AppNavigationView: View {
    @State private var selectedSection: SidebarSections? = .presets
    var body: some View {
        NavigationSplitView{
                List(SidebarSections.allCases, selection: $selectedSection) { section in
                    Label(section.rawValue, systemImage: section.iconName).tag(section)
                }.padding(.top, 15)
        } detail: {
            switch selectedSection {
            case .presets, .none: PresetsView()
            case .settings: SettingsView().padding(.leading)
            }
        }
        .navigationTransition(.automatic)
    }
}

#Preview {
    AppNavigationView()
}
