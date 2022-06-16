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
    var spacing: CGFloat = 0
    
    typealias CacheData = (origins: [CGPoint], columnWidth: CGFloat, height: CGFloat)
    
    func calculateGeometry(
        subviews: Subviews,
        proposal: ProposedViewSize
    ) -> CacheData {
        guard let width = proposal.width, !subviews.isEmpty else {
            return (origins: [], columnWidth: 0, height: 0)
        }
        
        // Calculate width and leading x coordinate for each column.
        let columnWidth = (width - CGFloat(column - 1) * spacing) / CGFloat(column)
        let columnX = (0..<column).map { columnIndex in
            CGFloat(columnIndex) * (columnWidth + spacing)
        }
        
        /// Stores currently allocated height for each column.
        var currentHeight = [CGFloat](repeating: 0, count: column)
        /// Stores the returned origins for each subview.
        var origins = [CGPoint]()
        /// Tracks the height of the heighest column.
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
        
        return (origins: origins, columnWidth: columnWidth, height: maxHeight)
    }
    
    func makeCache(subviews: Subviews) -> CacheData? {
        // As the cached data rely on view size proposal of the layout
        // and we cannot obtain that in `makeCache`, so we just clear
        // previous cache here.
        return nil
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData?
    ) -> CGSize {
        let cacheData = calculateGeometry(
            subviews: subviews, proposal: proposal
        )
        
        // Set cache (to be used in `placeSubviews()`).
        cache = cacheData

        guard !cacheData.origins.isEmpty else { return CGSize() }
        
        return CGSize(width: proposal.width ?? 0, height: cacheData.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData?
    ) {
        // Obtain cached data set by `sizeThatFits` so that we don't need to
        // re-calculate the geometry.
        let cacheData = cache ?? calculateGeometry(subviews: subviews, proposal: proposal)
        
        let placementProposal = ProposedViewSize(width: cacheData.columnWidth, height: nil)
        
        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(
                    // Be careful here: the bounds's origin is not always (0, 0)!
                    x: bounds.minX + cacheData.origins[index].x,
                    y: bounds.minY + cacheData.origins[index].y
                ),
                anchor: .topLeading,
                proposal: placementProposal
            )
        }
    }
}


struct WaterfallLayout_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
    
    struct Preview: View {
        @Environment(\.openURL) var openURL
        @State var randomHeights = Self.generateRandomHeights()
        @State var numberOfColumns = 3

        var body: some View {
            ScrollView {
                WaterfallLayout(column: numberOfColumns).callAsFunction {
                    ForEach(0..<100) { index in
                        let height = randomHeights[index]
                        ZStack {
                            Rectangle()
                                .stroke()
                                .foregroundColor(.orange)
                            Text("**\(index)**")
                        }
                        .frame(height: CGFloat(height))
                    }
                }
                .padding()
                .animation(.default, value: numberOfColumns)
                .animation(.default, value: randomHeights)
            }
            .toolbar {
                Picker("Column Number", selection: $numberOfColumns) {
                    ForEach(1..<6) { columns in
                        Text("\(columns)")
                            .tag(columns)
                    }
                }
                .pickerStyle(.menu)
                
                Button("Randomize") {
                    randomHeights = Self.generateRandomHeights()
                }
                Button {
                    openURL(URL(string: "https://developer.apple.com/videos/play/wwdc2022/10056/")!)
                } label: {
                    Image(systemName: "link")
                }

            }
            .navigationTitle("Waterfall Layout")
        }
        
        private static func generateRandomHeights() -> [Int] {
            (0..<100).map { _ in Int.random(in: 20...200) }
        }
    }

}
