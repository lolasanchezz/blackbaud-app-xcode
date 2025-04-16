//
//  hub2App.swift
//  hub2
//
//  Created by Lola Sanchez on 10/14/24.
//



public struct AssignmentStruct: Decodable, Identifiable{
    public let id = UUID()
    var Title: String
    var DateDue: String
    var GroupName: String
    var AssignmentStatus: Int
    var LongDescription: String
}

public struct AllAssignments: Decodable {
    var assignments: [AssignmentStruct]!
}
public var Assignments: AllAssignments? = AllAssignments(assignments: [])
import SwiftUI

@main
struct hub2App: App {
    
    
    
    
    func readFromFile() {
        
        
        var fileURL = URL(fileURLWithPath: "tmp/assignments.json")
        do {
            var fileContents = try String(contentsOf: fileURL, encoding: .utf8)
            var jsonData = fileContents.data(using: .utf8)!
            Assignments?.assignments = try! JSONDecoder().decode([AssignmentStruct].self, from: jsonData)
        
            if var assignments = Assignments?.assignments {
                for i in assignments.indices {
                    assignments[i].DateDue = String(assignments[i].DateDue.prefix(9))
                }
                Assignments?.assignments = assignments
            }

             
            
        } catch {
            print("Error reading file: \(error)")
        }
        
    }
    
    init() {
       // readFromFile()
    }
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(assignmentObj: Assignments!)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}


        
        
        
    

