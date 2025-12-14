//
//  pdfconverterApp.swift
//  pdfconverter
//
//  Created by Bilaal Ishtiaq on 13/12/2025.
//

import SwiftUI
import SwiftData

@main
struct pdfconverterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ScannedDocument.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        SubscriptionService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environmentObject(SubscriptionService.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
