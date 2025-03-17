//
//  ContentView.swift
//  Swift3270
//
//  Created by Rudi on 2025-03-16.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [HostSettings]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.creationTimestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.nickname ?? item.hostName)
                    }
                }
                .onDelete(perform: closeSession)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: openSession) {
                        Label("Add Host", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("No Active Sessions")
        }
    }

    private func openSession() {
        withAnimation {
            
            let newHost = HostSettings(timestamp: Date(), hostname: "planet.sdf.org", port: 24)
            newHost.nickname = "SDFVM"
            let testC = newHost.getConnection()
            do {
               try testC.start()
                
            } catch let e {
                print("Could not connect: \(e)")
            }
            modelContext.insert(newHost)
        }
    }

    private func closeSession(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
