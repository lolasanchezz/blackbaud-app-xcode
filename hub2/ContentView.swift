//
//  ContentView.swift
//  hub2
//
//  Created by Lola Sanchez on 10/14/24.
//

import SwiftUI
import CoreData
import AppKit
import Foundation


var processLaunched = false
var ran = 0;
func makeOneBar(assignmentData: AssignmentStruct) -> some View{
    @State var showingPopover: Bool = false

    let body = Button(action: {
        showingPopover = true
        print("clicked")
    }) {
        VStack{
            Divider()
            HStack(alignment: .bottom){
                Text(assignmentData.Title)
                Spacer()
                Text(assignmentData.GroupName)
            }
        }
    }.contentShape(Rectangle())
        .onTapGesture{
            if assignmentData.LongDescription != "" {
                showingPopover = true
            }
            print("tapped")
        }.popover(isPresented: $showingPopover) {
            Text(assignmentData.LongDescription)
        }
    return body
    }









func runCurl() -> [AssignmentStruct]{
    print("running!")
    guard !processLaunched else {
        print("hold on")
        return []
    }
    processLaunched = true
    ran+=1
    
    //open file, read from it
    //execute what's read and format the output into json
    //put that output in a file
    
    //read from tmp file
    let fileURL = URL(fileURLWithPath: "/tmp/curl.txt")
    guard var fileContents = try? String(contentsOf: fileURL, encoding: .utf8), !fileContents.isEmpty else {
        print("file was empty :(")
        return []
    }
    //print(fileContents)
    //making pipe to execute read command
    
    let process = Process()
    let outputPipe = Pipe()
    let errPipe = Pipe()
    var firstData: Data = Data()
       process.standardOutput = outputPipe
       process.standardError = errPipe
    //print(fileContents)
       process.arguments = ["-c", fileContents]
    //process.arguments = ["-c", "echo 'hello from curl process'"]

    process.executableURL = URL(fileURLWithPath: "/bin/bash")
       process.standardInput = Pipe()

    
            
    do {
        print("starting")
        

            try process.run()
      
        print(process.isRunning)
    
        firstData =  outputPipe.fileHandleForReading.readDataToEndOfFile()
        var errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        processLaunched = false
        print(errData)
        print(firstData);
        print("meow")
       
            
            
        // Prevents curl from waiting for input
        
        //firstData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        
    print("data output!")
       } catch {
            print("Error executing command: \(error)")
            
      }
    //ok now turning it into json
    //decode it using json decoder, change the value of assignments,
    //then write it into a file
    let decoder = JSONDecoder()
    
    var secondData: [AssignmentStruct]

     do {
          secondData = try decoder.decode([AssignmentStruct].self, from: firstData)
         print(String(data:firstData, encoding: .utf8))
         
     } catch {
         print("JSON Decoding Error: \(error)")
         print("break")
         //print(String(data:firstData, encoding: .utf8))
         return []
     }
   
    
    //now putting it into the json file for later use
    
    do {
        let documentsURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        let jsonURL = documentsURL.appendingPathComponent("assignments.json")
        let jsonData = try JSONEncoder().encode(firstData)
        try jsonData.write(to: jsonURL)
    } catch {
        print("couldn't write to file:\(error)")
    }
    
    //have to fix the dates real quick
    var assignments = secondData
        for i in assignments.indices {
            assignments[i].DateDue = String(assignments[i].DateDue.prefix(9))
        }
        secondData = assignments
    processLaunched = true
    return secondData
    
}






struct ContentView: View {
    @State var showCompleted: Bool = false
    var assignmentObj: AllAssignments
    @State var assignments: [AssignmentStruct]  = []
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()
    let dayDateFormatter: DateFormatter = {
        let dayDateFormatter = DateFormatter()
        dayDateFormatter.dateFormat = "EEEE"
        return dayDateFormatter
    }()
    
    var calendar = Calendar.current
    
   
    
    var tdyAssignments: [AssignmentStruct] {
       
        var assigns = (assignments.filter({dateFormatter.date(from: $0.DateDue) == Calendar.current.startOfDay(for: Date())})).sorted{$0.DateDue > $1.DateDue}
        
       
        //print(assigns)
        return assigns
    }
    
    
    var tmrwAssignments: [AssignmentStruct]{
        (assignments.filter({dateFormatter.date(from: $0.DateDue) == calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!})).sorted{$0.DateDue > $1.DateDue}
    }
    var tdyTmrwAssignments: [AssignmentStruct] {(tdyAssignments+tmrwAssignments).sorted{$0.DateDue > $1.DateDue}}
    
    var tdyAllDone: Bool {
        var leng = tdyAssignments.filter({$0.AssignmentStatus != 1})
        if leng.count > 0 {
            return false
        }
        else {
            return true
        }
    }
    
    var tmrwAllDone: Bool {
        var leng = tmrwAssignments.filter({$0.AssignmentStatus != 1})
        if leng.count > 0 {
            return false
        }
        else {
            return true
        }
    }

    
    var futureAssignments: [AssignmentStruct] {
        var array = assignments.filter({
            let date = dateFormatter.date(from:$0.DateDue)
            return date != Date() && date != calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: Date()))
        })
        array = array.sorted{$0.DateDue > $1.DateDue}
        return array
    }
    
    var missingAssignments: [AssignmentStruct] {
        assignments.filter{$0.AssignmentStatus == 4}
    }
    //TODO HERE: figure out what number correlates to missing
    var nextWeekAssignments: [AssignmentStruct] {
       var unFiltered = assignments.filter { assignment in
            
            guard let assignmentDate = dateFormatter.date(from: assignment.DateDue),
                  let weekFromNow = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: Date()))
                
            else {
                return false
            }
            
           let inTwoDays = calendar.date(byAdding: .day, value :2, to: calendar.startOfDay(for:Date()))
           return assignmentDate >= inTwoDays! && assignmentDate < weekFromNow
        }
        unFiltered = unFiltered.sorted{$0.DateDue < $1.DateDue}
        return unFiltered
        
    }
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
     
    var body: some View {
        
        TabView{
            
            VStack(alignment: .leading){
                Button(action: {
                    showCompleted = !showCompleted
                }) {
                    Text("show completed")
                    
                    
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .buttonStyle(.borderless)
                
                ScrollView(.vertical) {
                    if tdyTmrwAssignments.isEmpty {
                        Text("No homework due today or tomorrow")
                            .padding(5)
                    } else {
                        Text("today").foregroundColor(.gray)
                        //start of where hw is existing
                        
                        
                        //check whether hw for that day
                        if
                            ((tdyAllDone) && !(showCompleted)){
                            Text("everything's done!")
                        } else {
                            VStack(alignment: .leading, spacing:0){
                                
                                
                                ForEach(tdyAssignments){ item in
                                    if item.AssignmentStatus == 1 {
                                        if showCompleted == true {
                                            HStack() {
                                                Text(item.Title).strikethrough()
                                                Spacer()
                                                Text(item.GroupName)
                                            }
                                            Divider().padding([.bottom],6)
                                        }
                                    } else {
                                        HStack() {
                                            Text(item.Title)
                                            Spacer()
                                            Text(item.GroupName)
                                        }
                                        Divider().padding([.bottom],6)
                                        
                                    }
                                    
                                }
                            }
                        }
                        if !(tmrwAssignments.isEmpty) {
                        Text("tomorrow").foregroundColor(.gray)
                        VStack(alignment: .leading, spacing:0){
                           
                                if ((tmrwAllDone) && !(showCompleted)) {
                                    Text("everything's done!")
                                } else {
                                    
                                    ForEach(tmrwAssignments){ item in
                                        if item.AssignmentStatus == 1 {
                                            if showCompleted == true {
                                                HStack() {
                                                    Text(item.Title).strikethrough()
                                                    Spacer()
                                                    Text(item.GroupName)
                                                }
                                                Divider().padding([.bottom],6)
                                            }
                                        } else {
                                            HStack() {
                                                Text(item.Title)
                                                Spacer()
                                                Text(item.GroupName)
                                            }
                                            Divider().padding([.bottom],6)
                                            
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                }
                   
            }.padding(20)
                .tabItem {
                    Label("tdy + tmrw", systemImage: "t.square.fill").font(.system(size:12))
                }
                
                
            ScrollView(.vertical){
                if nextWeekAssignments.count == 0 {
                    Text("no homework next week 😛")
                } else {
                    Text("next week's assignments")
                    VStack(alignment:.leading, spacing: 0){
                        ForEach(nextWeekAssignments) { item in
                            HStack() {
                                Text(item.Title)
                                Text(item.GroupName).italic()
                                Spacer()
                                Text((dateFormatter.string(from:
                                (dateFormatter.date(from:item.DateDue))!)))
                                
                            }.padding(5)
                            Divider()
                        }
                    }.padding(5)
                }
            }.tabItem{
                Label("week", systemImage:"w.square.fill")
            }.padding(5)
            
            
            
            
            
                ScrollView(.vertical) {
                    (missingAssignments.count == 0) ? AnyView(Text("no missing homework!!")):
                    AnyView(
                        
                        VStack(alignment: .leading, spacing:0){
                            Text("missing 😔").padding([.bottom],6)
                            ForEach(missingAssignments){ item in
                                HStack() {
                                    Text(item.Title)
                                    Text(item.DateDue)
                                    Spacer()
                                    Text(item.GroupName)
                                    
                                    
                                }.padding(5)
                                Divider()
                            }
                            
                            
                        }
                            .onAppear {
                                print(NSScreen.main?.frame.width)
                            }
                            .padding(20)
                    )
                    
                }
                    .tabItem {
                        Label("missing", systemImage: "exclamationmark.2")
                    }
                
            ScrollView(.vertical) {
                VStack(alignment: .leading){
                    Button(action: {
                        showCompleted = !showCompleted
                    }) {
                        Text("show completed")
                        
                        
                    }.frame(maxWidth: .infinity, alignment: .leading)
                        .buttonStyle(.borderless)
                    
                    if futureAssignments.isEmpty {
                        Text("no future assignments!! (this might be a bug)")
                            .padding(5)
                    } else {
                        
                        //start of where hw is existing
                        VStack(alignment: .leading, spacing:0){
                            ForEach(futureAssignments){ item in
                                if item.AssignmentStatus == 1 {
                                    if showCompleted == true {
                                        HStack() {
                                            Text(item.Title).strikethrough()
                                            Spacer()
                                            Text(item.GroupName)
                                        }
                                        Divider().padding([.bottom],6)
                                    }
                                } else {
                                    HStack() {
                                        Text(item.Title)
                                        Spacer()
                                        Text(item.GroupName)
                                    }
                                    Divider().padding([.bottom],6)
                                    
                                }
                                
                            }
                        }
                    }
                    
                }
            }
        .padding(20)
            .tabItem {
                Label("future", systemImage: "f.square.fill")
            }
                
                
                
        }.toolbar{
            Button(action: {
                assignments = runCurl()
            }) {
                Text("refresh")
                
                
            }.frame(maxWidth: .infinity, alignment: .leading)
                .buttonStyle(.borderless)
        }
            
            
            
            
            
        }
        
    }


/*
func showAssignments(allData: allAssignments) -> some View {
    
}
*/




#Preview {
    
    ContentView(assignmentObj: Assignments!).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
