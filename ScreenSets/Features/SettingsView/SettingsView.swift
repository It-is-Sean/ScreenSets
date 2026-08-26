//
//  SettingsView.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppPreferences.self)
    private var appPreferences
    
    var body: some View {
        @Bindable var appPreferences = appPreferences
        VStack(alignment: .leading){
            PageTitle(text: "Settings")
            Form {
                Toggle(
                    "Show in Menu Bar",
                    isOn: $appPreferences.showInMenuBar
                )

                Toggle(
                    "Launch at Login",
                    isOn: $appPreferences.launchAtLogIn
                )
            }
            
            Spacer()

        }
    }
}

#Preview {
    SettingsView()
}
