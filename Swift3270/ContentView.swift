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
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item")
                    } label: {
                        Text("\(item.timestamp)")
                    }
                }
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
