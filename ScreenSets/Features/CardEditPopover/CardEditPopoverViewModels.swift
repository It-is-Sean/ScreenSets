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
            }
        }
        .controlSize(.extraLarge)
        .tint(.red)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
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

struct SaveButton: View {
    @State private var showAlert = false

    let action: () throws -> Void

    var body: some View {
        Button {
            do {
                try action()
            } catch{
                Logger.service.error("Failed to save name")
            }
            
        } label: {
            HStack {
                Image(systemName: "checkmark")
                
            }
        }
        .controlSize(.extraLarge)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)

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
        .controlSize(.extraLarge)
         .buttonStyle(.glass)
    }
}
