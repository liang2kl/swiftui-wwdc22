//
//  WaterfallLayout.swift
//  WWDC22
//
//  Created by liang2kl on 2022/6/15.
//

import SwiftUI

/// A vertical multi-column layout that places subviews sequentially into
/// a column with minimum height.
struct WaterfallLayout: Layout {
    var column: Int = 2
    var spacing: CGFloat = 10
    
    func calculateGeometry(
        subviews: Subviews,
        proposal: ProposedViewSize
    ) -> (origins: [CGPoint], width: CGFloat, height: CGFloat) {
        guard let width = proposal.width, !subviews.isEmpty else {
            return (origins: [], width: 0, height: 0)
        }
        let columnWidth = (width - CGFloat(column - 1) * spacing) / CGFloat(column)
        let columnX = (0..<column).map { columnIndex in
            CGFloat(columnIndex) * (columnWidth + spacing)
        }
        var currentHeight = [CGFloat](repeating: 0, count: column)
        var origins = [CGPoint]()
        var maxHeight: CGFloat = -1;
        
        for index in subviews.indices {
            let subview = subviews[index]
            let height = subview.sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            ).height
            // Find the column with minimum height.
            // Alternative data structures can be adopted for better performace.
            let selectedColumn = (0..<column).reduce(0) { minColumn, index in
                return currentHeight[index] < currentHeight[minColumn]
                ? index : minColumn
            }
            origins.append(
                CGPoint(x: columnX[selectedColumn], y: currentHeight[selectedColumn])
            )
            currentHeight[selectedColumn] += height
            
            maxHeight = max(currentHeight[selectedColumn], maxHeight)
        }
        
        return (origins: origins, width: columnWidth, height: maxHeight)
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let (origins, _, maxHeight) = calculateGeometry(
            subviews: subviews, proposal: proposal
        )
        guard !origins.isEmpty else { return CGSize() }
        return CGSize(width: proposal.width ?? 0, height: maxHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let (origins, columnWidth, _) = calculateGeometry(
            subviews: subviews, proposal: proposal
        )
        
        let placementProposal = ProposedViewSize(width: columnWidth, height: nil)
        
        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(
                    // Be careful here: the bounds's origin is not always (0, 0)!
                    x: bounds.minX + origins[index].x,
                    y: bounds.minY + origins[index].y
                ),
                anchor: .topLeading,
                proposal: placementProposal
            )
        }
    }
}


struct WaterfallLayout_Previews: PreviewProvider {
    @Environment(\.openURL) static var openURL
    @State static var randomHeights = (0..<100).map { _ in Int.random(in: 20...200) }

    static var previews: some View {
        ScrollView {
            WaterfallLayout(column: 3, spacing: 0).callAsFunction {
                ForEach(0..<100) { index in
                    let height = randomHeights[index]
                    Rectangle()
                        .stroke()
                        .foregroundColor(.orange)
                        .overlay {
                            Text("**\(index)**: \(height)")
                        }
                        .frame(idealHeight: CGFloat(height), maxHeight: CGFloat(height))
                }
                
            }
            .padding()
        }
        .toolbar {
            Button {
                openURL(URL(string: "https://developer.apple.com/videos/play/wwdc2022/10056/")!)
            } label: {
                Image(systemName: "link")
            }
        }
    }
}
