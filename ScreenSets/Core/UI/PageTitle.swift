//
//  Title.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/26.
//

import SwiftUI

struct PageTitle: View {
    let text: String
    var body: some View {
        HStack{
            Text(text)
                .font(.system(.largeTitle,weight: .semibold))
                .fontWidth(.expanded)
            Spacer()
        }.padding(.leading, 5).padding(.bottom, -1)
    }
}


#Preview {
    PageTitle(text: "Details")
}
