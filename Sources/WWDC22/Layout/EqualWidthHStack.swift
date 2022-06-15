//
//  EqualWidthHStack.swift
//  WWDC22
//
//  Created by liang2kl on 2022/6/15.
//

import SwiftUI


/// An HStack whose children have equal widths to the widest child.
///
/// This is a example from WWDC session
/// [Compose custom layouts with SwiftUI](https://developer.apple.com/videos/play/wwdc2022/10056/).
struct EqualWidthHStack: Layout {
    /// The calculation result to be cached in layout process.
    struct CacheData {
        let maxSize: CGSize
        let spacing: [CGFloat]
        let totalSpacing: CGFloat
    }

    /// Make calculation cache for given subviews.
    func makeCache(subviews: Subviews) -> CacheData {
        // Finds the largest ideal size of the subviews.
        let subviewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxSize: CGSize = subviewSizes.reduce(.zero) { currentMax, subviewSize in
            CGSize(
                width: max(currentMax.width, subviewSize.width),
                height: max(currentMax.height, subviewSize.height))
        }
        
        // Calculate the spacing between subviews.
        let spacing: [CGFloat] = subviews.indices.map { index in
            // The last subview has zero spacing to the end.
            guard index < subviews.count - 1 else { return 0 }
            // Use `distance()` to calculate the preferred distance between
            // two subviews.
            return subviews[index].spacing.distance(
                to: subviews[index + 1].spacing,
                along: .horizontal)
        }
        
        // Get the total spacing
        let totalSpacing = spacing.reduce(0) { $0 + $1 }
        
        return CacheData(maxSize: maxSize, spacing: spacing, totalSpacing: totalSpacing)
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) -> CGSize {
        // Use the cached result without re-calculation.
        return CGSize(
            width: cache.maxSize.width * CGFloat(subviews.count) + cache.totalSpacing,
            height: cache.maxSize.height
        )
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) {
        guard !subviews.isEmpty else { return }

        let maxSize = cache.maxSize
        let spacing = cache.spacing

        // Pass this proposed size to subviews.
        let placementProposal = ProposedViewSize(width: maxSize.width, height: maxSize.height)
        var nextX = bounds.minX + maxSize.width / 2

        for index in subviews.indices {
            // Place the subview
            subviews[index].place(
                at: CGPoint(x: nextX, y: bounds.midY),
                anchor: .center,
                proposal: placementProposal)
            nextX += maxSize.width + spacing[index]
        }
    }
}

struct EqualWidthHStack_Previews: PreviewProvider {
    @Environment(\.openURL) static var openURL
    
    static var previews: some View {
        EqualWidthHStack().callAsFunction {
            Group {
                Text("Short Text")
                Text("Long.............. Text")
            }
            .frame(maxWidth: .infinity)
            .background(.orange)
            .cornerRadius(5)
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
