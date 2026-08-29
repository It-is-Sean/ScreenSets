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
            GroupBox {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("App settings").font(.body).bold().foregroundStyle(.secondary)
                        Toggle(
                            isOn: $appPreferences.showInMenuBar
                        ) {
                            Text("Show in menubar").frame(
                                maxWidth: .infinity, alignment: .leading)
                        }
                        .toggleStyle(.switch)
                        .frame(maxWidth: .infinity)
                        Divider()
                        Toggle(
                            isOn: $appPreferences.launchAtLogIn
                        ) {
                            Text("Launch at login").frame(
                                maxWidth: .infinity, alignment: .leading)
                        }
                        .toggleStyle(.switch)
                        .frame(maxWidth: .infinity)

                    }.frame(maxWidth: .infinity)
                        .padding(3)
                }.padding(7)
            }.padding(.top)

            Spacer()

        }
    }
}

#Preview {
    SettingsView()
}
