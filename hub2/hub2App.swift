//
//  hub2App.swift
//  hub2
//
//  Created by Lola Sanchez on 10/14/24.
//

import SwiftUI

@main
struct hub2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
