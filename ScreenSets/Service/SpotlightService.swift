//
//  SpotlightService.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/29.
//
import Foundation
import CoreSpotlight
import AppIntents
import OSLog

enum SpotlightDependencyKey {
    static let value = "ScreenSets.SpotlightService"
}

struct PresetEntity: IndexedEntity {
     static let typeDisplayRepresentation:
         TypeDisplayRepresentation = "Display Preset"

     static let defaultQuery = PresetEntityQuery()

     let id: UUID
     let name: String
     let displayCount: Int

     var displayRepresentation: DisplayRepresentation {
         DisplayRepresentation(
             title: "\(name)",
             subtitle: "\(displayCount) Displays",
             image: .init(systemName: "display.2")
         )
     }

     var attributeSet: CSSearchableItemAttributeSet {
         let attributes = defaultAttributeSet

         attributes.title = name
         attributes.contentDescription =
             "\(displayCount) displays"
         attributes.keywords = [
             "display",
             "monitor",
             "preset"
         ]

         return attributes
     }
 }
protocol SpotlightServiceProtocol: Sendable{
    func syncEntities() async
    func suggestedEntities() -> [PresetEntity]
    func entities(for ids: [UUID]) -> [PresetEntity]
    func applyPreset(id: UUID) throws
}

enum SpotlightServiceError: LocalizedError {
     case presetNotFound
     case presetUnavailable(String)

     var errorDescription: String? {
         switch self {
         case .presetNotFound:
             "The display preset no longer exists."

         case .presetUnavailable(let name):
             "\(name) isn't available with the currently connected displays."
         }
     }
 }
final class SpotlightService : SpotlightServiceProtocol{
    private let screenSetsService: ScreenSetsService
    private let searchableIndex = CSSearchableIndex(
        name: "ScreenSets.Presets"
    )

    init(screenSetsService: ScreenSetsService) {
        self.screenSetsService = screenSetsService
    }
    
    func syncEntities() async {
        let entities = suggestedEntities()

        do {
            try await searchableIndex.deleteAppEntities(
                ofType: PresetEntity.self
            )

            if !entities.isEmpty {
                try await searchableIndex.indexAppEntities(entities)
            }

            } catch {
                Logger.service.error(
                     """
                     Failed to synchronize Spotlight entities: \
                     \(error.localizedDescription, privacy: .public)
                     """)
        }
        ScreenSetsShortcuts.updateAppShortcutParameters()
    }
    
    func suggestedEntities() -> [PresetEntity] {
        let availableIDs = Set(
            screenSetsService
                .displayState
                .availablePresetUUIDs
        )

        return screenSetsService.displayPresets.compactMap {
            preset in
            guard availableIDs.contains(preset.id) else {
                return nil
            }

            return makeEntity(from: preset)
        }
    }
    func entities(for ids: [UUID]) -> [PresetEntity] {
        let presetByID = Dictionary(
            uniqueKeysWithValues:
                screenSetsService.displayPresets.map {
                    ($0.id, $0)
                }
        )

        return ids.compactMap {
            guard let preset = presetByID[$0] else {
                return nil
            }

            return makeEntity(from: preset)
        }
    }

    func applyPreset(id: UUID) throws {
        guard
            let preset = screenSetsService.displayPresets.first(
                where: { $0.id == id }
            )
        else {
            throw SpotlightServiceError.presetNotFound
        }

        guard screenSetsService.isPresetAvailable(id: id) else {
            throw SpotlightServiceError.presetUnavailable(
                preset.name
            )
        }

        try screenSetsService.applyPreset(id: id)
    }

    private func makeEntity(
        from preset: DisplayPreset
    ) -> PresetEntity {
        PresetEntity(
            id: preset.id,
            name: preset.name,
            displayCount: preset.displayUUIDs.count
        )
    }
}

struct PresetEntityQuery: EntityStringQuery {
    @Dependency(key: SpotlightDependencyKey.value)
    private var spotlightService:
        any SpotlightServiceProtocol

    @MainActor
    func entities(
        for identifiers: [UUID]
    ) async throws -> [PresetEntity] {
        spotlightService.entities(for: identifiers)
    }

    @MainActor
    func suggestedEntities() async throws -> [PresetEntity] {
        spotlightService.suggestedEntities()
    }

    @MainActor
    func entities(
        matching string: String
    ) async throws -> [PresetEntity] {
        spotlightService
            .suggestedEntities()
            .filter {
                $0.name.localizedCaseInsensitiveContains(
                    string
                )
            }
    }
}

struct OpenPresetIntent: OpenIntent {
    static let title: LocalizedStringResource =
        "Open ScreenSet Preset"

    @Parameter(title: "Preset")
    var target: PresetEntity

    @Dependency(key: SpotlightDependencyKey.value)
    private var spotlightService:
        any SpotlightServiceProtocol

    @MainActor
    func perform() async throws -> some IntentResult {
        try spotlightService.applyPreset(id: target.id)
        return .result()
    }
}

struct ApplyPresetIntent: AppIntent {
    static let title: LocalizedStringResource =
        "Apply ScreenSet Preset"

    static let description = IntentDescription(
        "Applies a saved display configuration."
    )

    static let supportedModes: IntentModes = [
        .background
    ]

    @Parameter(
        title: "Preset",
        requestValueDialog: "Which display preset?"
    )
    var preset: PresetEntity

    @Dependency(key: SpotlightDependencyKey.value)
    private var spotlightService:
        any SpotlightServiceProtocol

    static var parameterSummary: some ParameterSummary {
        Summary("Apply \(\.$preset)")
    }

    @MainActor
    func perform() async throws
        -> some IntentResult & ProvidesDialog
    {
        try spotlightService.applyPreset(id: preset.id)

        return .result(
            dialog: "Applied \(preset.name)."
        )
    }
}

struct ScreenSetsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ApplyPresetIntent(),
            phrases: [
                "Apply ScreenSets \(\.$preset) in \(.applicationName)",
                "Switch to \(\.$preset) with \(.applicationName)"
            ],
            shortTitle: "Apply ScreenSet Preset",
            systemImageName: "display.2"
        )
    }

    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}
