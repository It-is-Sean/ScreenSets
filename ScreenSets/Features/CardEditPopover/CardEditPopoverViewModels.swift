//
//  CardEditPopoverViewModels.swift
//  ScreenSets
//
//  Created by Sean on 2026/8/28.
//
import Foundation
import SwiftUI
import OSLog

struct DeleteButton: View {
    @State private var showAlert = false

    let presetName: String
    let action: () throws -> Void

    var body: some View {
        Button {
            showAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete")
                    .font(.headline)
            }
            .foregroundStyle(.white)
        }
        .controlSize(.large)
        .tint(.red)
        .buttonStyle(.glassProminent)
        .alert("Delete the preset \(presetName)?", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {}

            Button("Delete", role: .destructive) {
                do {
                    try action()
                } catch {
                    Logger.service.error(
                        "Failed to delete preset: \(error.localizedDescription, privacy: .public)"
                    )
                }
            }
        }

    }
}

struct UpdateButton: View{
    @State private var showAlert = false
    let presetName: String
    let action: () throws -> Void

    var body:some View{
        Button(action: {
            showAlert.toggle()
        }) {
             HStack {
                 Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                 Text("Update")
                     .font(.headline)
             }
             .foregroundStyle(.white)

             .alert("Delete the preset \(presetName)?", isPresented: $showAlert) {
                     Button("NO", role: .cancel) {}
                     Button("Yes"){
                         do {
                             try action()
                         } catch {
                             Logger.service.error(
                                 "Failed to refresh preset: \(error.localizedDescription, privacy: .public)"
                             )
                         }
                    }
             }
         }
         .controlSize(.large)
         .buttonStyle(.glass)
    }
}
