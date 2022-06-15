//
//  WWDC22App.swift
//  WWDC22
//
//  Created by liang2kl on 2022/6/15.
//

import SwiftUI

@main
struct WWDC22App: App {
    @State var selectedDemo: DemoType = .waterfall
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List(DemoType.allCases, selection: $selectedDemo) { demoType in
                    // FIXME: There is (possibly) a bug with NavigationLink which will prompt with a runtime warning
                    NavigationLink(demoType.description, value: demoType)
                }
                .navigationDestination(for: DemoType.self) { $0.preview }
            } detail: {
                selectedDemo.preview
            }
        }
    }
}

enum DemoType: String, CustomStringConvertible, CaseIterable, Identifiable {
    case waterfall
    case equalWidth
    
    var description: String {
        switch self {
        case .waterfall: return "WaterfallLayout"
        case .equalWidth: return "EqualWidthHStack"
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
        }
    }
}
