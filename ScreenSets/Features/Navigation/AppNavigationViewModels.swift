//
//  NavigationViewModels.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/24.
//

import Foundation



enum SidebarSections: String, CaseIterable, Identifiable {
    case presets = "Presets"
    case settings = "Settings"
    var id: String {self.rawValue}
    
    var iconName: String  {
        switch self {
        case .presets: return "books.vertical"
        case .settings: return "gearshape"
        }
    }
}
