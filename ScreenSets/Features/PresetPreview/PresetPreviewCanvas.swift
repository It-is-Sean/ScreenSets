//
//  PresetPreviewCanvas.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/29.
//

import SwiftUI

struct PresetPreviewCanvas: View {

    
    struct CanvasDisplayMember: Identifiable {
        let number: Int
        let settings: DisplaySettings

        var id: UUID {
            settings.displayUUID
        }
    }

    struct CanvasItem: Identifiable {
        let id: UUID
        let members: [CanvasDisplayMember]
        let rect: CGRect

        var label: String {
            members
                .map { String($0.number) }
                .joined(separator: "|")
        }
    }

    private struct PositionedItem: Identifiable {
        let item: CanvasItem
        let frame: CGRect

        var id: UUID {
            item.id
        }
    }

    struct CanvasParameters {
        let contentPadding: CGFloat = 2
        let displayGap: CGFloat = 1
        let borderLineWidth: CGFloat
        let cornerRadius: CGFloat
        let minimumDrawableLength: CGFloat = 1

        let fillColor: Color = .secondary.opacity(0.3)
        let borderColor: Color = .secondary.opacity(0.8)
        let numberColor: Color = .secondary
        let numberFontSize: CGFloat
        let numberFontWeight: Font.Weight = .bold
        let numberFontDesign: Font.Design = .rounded
        let numberPadding: CGFloat = 2

        var strokeInset: CGFloat {
            borderLineWidth / 2 + displayGap / 2
        }
        init (borderLineWidth: CGFloat = 2, cornerRadius: CGFloat = 3, numberFontSize: CGFloat = 12){
            self.borderLineWidth = borderLineWidth
            self.cornerRadius = cornerRadius
            self.numberFontSize = numberFontSize
            
        }
    }
    
    let displayPreferences: [DisplaySettings]
    let parameters : CanvasParameters
    
    init(displayPreferences: [DisplaySettings], borderLineWidth: CGFloat = 2, cornerRadius: CGFloat = 3, numberFontSize: CGFloat = 12){
        self.displayPreferences = displayPreferences
        self.parameters = CanvasParameters(
            borderLineWidth: borderLineWidth,
            cornerRadius: cornerRadius,
            numberFontSize: numberFontSize
        )
    }

    

    var body: some View {
        let items = makeItems()

        GeometryReader { proxy in
            let positionedItems = position(
                items: items,
                in: proxy.size
            )

            ZStack {
                Canvas { context, _ in
                    let shouldDrawNumbers = numbersFit(
                        positionedItems,
                        context: context
                    )

                    for positionedItem in positionedItems {
                        draw(
                            positionedItem,
                            shouldDrawNumber: shouldDrawNumbers,
                            context: &context
                        )
                    }
                }
                .accessibilityHidden(true)

                ForEach(positionedItems) { positionedItem in
                    DisplayHitArea(
                        item: positionedItem.item,
                        parameters: parameters
                    )
                    .frame(
                        width: positionedItem.frame.width,
                        height: positionedItem.frame.height
                    )
                    .position(
                        x: positionedItem.frame.midX,
                        y: positionedItem.frame.midY
                    )
                }
            }
        }
    }

    func makeItems() -> [CanvasItem] {
        let members = displayPreferences.enumerated().map {
            index, settings in
            CanvasDisplayMember(
                number: index + 1,
                settings: settings
            )
        }
        let memberByID = Dictionary(
            uniqueKeysWithValues: members.map { ($0.id, $0) }
        )
        var consumedIDs = Set<UUID>()
        var items: [CanvasItem] = []

        for member in members {
            guard !consumedIDs.contains(member.id) else {
                continue
            }

            let master: CanvasDisplayMember
            if let masterID = member.settings.mirroringMaster,
                let existingMaster = memberByID[masterID]
            {
                master = existingMaster
            } else {
                master = member
            }

            let groupedMembers = members
                .filter {
                    $0.id == master.id
                        || $0.settings.mirroringMaster == master.id
                }
                .sorted { $0.number < $1.number }

            consumedIDs.formUnion(groupedMembers.map(\.id))

            let masterSettings = master.settings
            items.append(
                CanvasItem(
                    id: master.id,
                    members: groupedMembers,
                    rect: CGRect(
                        x: CGFloat(masterSettings.originX),
                        y: CGFloat(masterSettings.originY),
                        width: CGFloat(masterSettings.mode.width),
                        height: CGFloat(masterSettings.mode.height)
                    )
                )
            )
        }

        return items
    }

    private func position(
        items: [CanvasItem],
        in size: CGSize
    ) -> [PositionedItem] {
        guard
            let bounds = items
                .map(\.rect)
                .reduce(nil as CGRect?) { result, rect in
                    result?.union(rect) ?? rect
                },
            bounds.width > 0,
            bounds.height > 0,
            size.width > 0,
            size.height > 0
        else {
            return []
        }

        let availableWidth = max(
            0,
            size.width - parameters.contentPadding * 2
        )
        let availableHeight = max(
            0,
            size.height - parameters.contentPadding * 2
        )
        let scale = min(
            availableWidth / bounds.width,
            availableHeight / bounds.height
        )

        guard scale.isFinite, scale > 0 else {
            return []
        }

        let offset = CGPoint(
            x: (size.width - bounds.width * scale) / 2
                - bounds.minX * scale,
            y: (size.height - bounds.height * scale) / 2
                - bounds.minY * scale
        )

        return items.compactMap { item in
            let rawFrame = CGRect(
                x: item.rect.minX * scale + offset.x,
                y: item.rect.minY * scale + offset.y,
                width: item.rect.width * scale,
                height: item.rect.height * scale
            )
            let maximumInset = max(
                0,
                min(rawFrame.width, rawFrame.height) / 2
                    - parameters.minimumDrawableLength / 2
            )
            let inset = min(parameters.strokeInset, maximumInset)
            let frame = rawFrame.insetBy(dx: inset, dy: inset)

            guard
                frame.width >= parameters.minimumDrawableLength,
                frame.height >= parameters.minimumDrawableLength
            else {
                return nil
            }

            return PositionedItem(item: item, frame: frame)
        }
    }

    private func draw(
        _ positionedItem: PositionedItem,
        shouldDrawNumber: Bool,
        context: inout GraphicsContext
    ) {
        let screenRect = positionedItem.frame
        let cornerRadius = min(
            parameters.cornerRadius,
            screenRect.width / 2,
            screenRect.height / 2
        )
        let path = Path(
            roundedRect: screenRect,
            cornerRadius: cornerRadius
        )

        context.fill(path, with: .color(parameters.fillColor))
        context.stroke(
            path,
            with: .color(parameters.borderColor),
            lineWidth: parameters.borderLineWidth
        )

        guard shouldDrawNumber else {
            return
        }

        context.draw(
            numberText(for: positionedItem.item),
            at: CGPoint(x: screenRect.midX, y: screenRect.midY)
        )
    }

    private func numbersFit(
        _ positionedItems: [PositionedItem],
        context: GraphicsContext
    ) -> Bool {
        positionedItems.allSatisfy { positionedItem in
            let numberSize = context
                .resolve(numberText(for: positionedItem.item))
                .measure(
                    in: CGSize(
                        width: CGFloat.greatestFiniteMagnitude,
                        height: CGFloat.greatestFiniteMagnitude
                    )
                )
            let frame = positionedItem.frame

            return
                numberSize.width + parameters.numberPadding * 2
                    <= frame.width
                && numberSize.height + parameters.numberPadding * 2
                    <= frame.height
        }
    }

    private func numberText(for item: CanvasItem) -> Text {
        Text(verbatim: item.label)
            .font(
                .system(
                    size: parameters.numberFontSize,
                    weight: parameters.numberFontWeight,
                    design: parameters.numberFontDesign
                )
            )
            .foregroundStyle(parameters.numberColor)
    }

    private struct DisplayHitArea: View {
        let item: CanvasItem
        let parameters: CanvasParameters

        @State private var isPopoverPresented = false

        var body: some View {
            Button {
                isPopoverPresented = true
            } label: {
                RoundedRectangle(
                    cornerRadius: parameters.cornerRadius,
                    style: .continuous
                )
                .fill(.clear)
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: parameters.cornerRadius,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .help("Display \(item.label)")
            .accessibilityLabel("Display \(item.label)")
            .popover(
                isPresented: $isPopoverPresented,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            ) {
                PresetPreviewPopoverView(
                    item: item,
                )
            }
        }
    }


}

#Preview("Preset Canvas") {
    let list = PresetCanvasPreviewData.list
    let item = list[0]
    VStack(spacing: 12) {
        Text(item.name)
            .font(.headline)

        PresetPreviewCanvas(
            displayPreferences: item.displayPreferences
        )
        .frame(width: 100, height: 75)
        .padding(12)
        .background {
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(.quaternary)
        }
    }

    .padding()
}

private enum PresetCanvasPreviewData {
    static let mainID = UUID(
        uuidString: "00000000-0000-0000-0000-000000000101"
    )!

    static let leftID = UUID(
        uuidString: "00000000-0000-0000-0000-000000000102"
    )!

    static let rightID = UUID(
        uuidString: "00000000-0000-0000-0000-000000000103"
    )!

    static func display(
        id: UUID,
        x: Int32,
        y: Int32,
        width: Int,
        height: Int,
        status: MirroringStatus = .independent,
        master: UUID? = nil,
        name: String
    ) -> DisplaySettings {
        DisplaySettings(
            displayUUID: id,
            originX: x,
            originY: y,
            mode: DisplayModePreference(
                width: width,
                height: height,
                pixelWidth: width * 2,
                pixelHeight: height * 2,
                refreshRate: 60
            ),
            mirroringStatus: status,
            mirroringMaster: master,
            displayName: name
        )
    }

    static let list: [DisplayPreset] = [
        // Tri-Vertial
        DisplayPreset(
            displayPreferences: [
                display(
                    id: leftID,
                    x: -1920,
                    y: 120,
                    width: 1920,
                    height: 1080,
                    name: "Built-in Retina Display"
                    
                ),
                display(
                    id: mainID,
                    x: 0,
                    y: 0,
                    width: 1512,
                    height: 982,
                    name: "Studio Display"
                ),
                display(
                    id: rightID,
                    x: 1512,
                    y: -120,
                    width: 2560,
                    height: 1440,
                    name: "Studio Display XDR"
                ),
            ],
            name: "Three Displays"
        ),

        // Vertical
        DisplayPreset(
            displayPreferences: [
                display(
                    id: mainID,
                    x: 0,
                    y: 0,
                    width: 1512,
                    height: 982,
                    name: "Built-in Retina Display"
                ),
                display(
                    id: rightID,
                    x: 200,
                    y: -1440,
                    width: 2560,
                    height: 1440,
                    name: "iPad Air"
                ),
            ],
            name: "Vertical Layout"
        ),

        // Mirroring
        DisplayPreset(
            displayPreferences: [
                display(
                    id: mainID,
                    x: 0,
                    y: 0,
                    width: 1512,
                    height: 982,
                    status: .mirrored,
                    name: "Built-in Retina Display"
                ),
                display(
                    id: rightID,
                    x: 0,
                    y: 0,
                    width: 1920,
                    height: 1080,
                    status: .mirroring,
                    master: mainID,
                    name: "Generic Display"
                ),
            ],
            name: "Mirrored Displays"
        ),
    ]
}
