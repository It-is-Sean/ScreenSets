//
//  PresetPreviewPopoverView.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/29.
//


import SwiftUI


struct PresetPreviewPopoverView: View {
    struct PopoverParameters{
        let popoverSpacing: CGFloat = 8
        let popoverSectionSpacing: CGFloat = 6
        let popoverPadding: CGFloat = 14
        let popoverMinWidth: CGFloat = 240
        let popoverArrowEdge: Edge = .top
    }
    let item: PresetPreviewCanvas.CanvasItem
    let parameters: PopoverParameters = PopoverParameters()

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: parameters.popoverSpacing
        ) {
            //Text("Display \(item.label)")
            //    .font(.headline)
            //Divider()
            ForEach(item.members) { member in
                HStack(
                    alignment: .center,
                ) {
                    Text("Display \(member.number)")
                        .font(.subheadline.weight(.semibold))
                    Text ("\(member.settings.displayName)")
                }

            }
        }
        .padding(parameters.popoverPadding)
    }
}
