//
//  WWDC22App.swift
//  WWDC22
//
//  Created by liang2kl on 2022/6/15.
//

import SwiftUI

@main
struct WWDC22App: App {
    @State var selectedDemo: DemoType? = .interactiveChart
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List(DemoType.allCases, selection: $selectedDemo) { demoType in
                    NavigationLink(demoType.description, value: demoType)
                }
                // FIXME: There is a bug with NavigationLink destination
                .navigationDestination(for: DemoType.self) { $0.preview }
                .navigationTitle("WWDC22")
            } detail: {
                if let selectedDemo = selectedDemo {
                    selectedDemo.preview
                } else {
                    Text("Select a demo from the sidebar.")
                }
            }
        }
    }
}

enum DemoType: String, CustomStringConvertible, CaseIterable, Identifiable {
    case waterfall
    case equalWidth
    case interactiveChart
    
    var description: String {
        switch self {
        case .waterfall: return "Waterfall Layout"
        case .equalWidth: return "Equal Width HStack"
        case .interactiveChart: return "Interactive Chart"
        }
    }
    
    var id: String {
        return rawValue
    }
    
    @ViewBuilder
    var preview: some View {
        switch self {
        case .waterfall: WaterfallLayout_Previews.previews
        case .equalWidth: EqualWidthHStack_Previews.previews
        case .interactiveChart: InteractiveWeatherChart_Previews.previews
        }
    }
}
