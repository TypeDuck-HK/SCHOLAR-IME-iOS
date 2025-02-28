//
//  CandidateCollectionViewFlowLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit

class CandidateCollectionViewFlowLayout: UICollectionViewFlowLayout {
    private weak var candidatePaneView: CandidatePaneView?
    
    private var rowHeight: CGFloat {
        candidatePaneView?.rowHeight ?? .zero
    }
    
    init(candidatePaneView: CandidatePaneView) {
        self.candidatePaneView = candidatePaneView
        super.init()
        sectionHeadersPinToVisibleBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var collectionViewContentSize: CGSize {
        var contentSize = super.collectionViewContentSize
        if let collectionView = collectionView,
           let candidatePaneView = candidatePaneView,
           candidatePaneView.mode == .table && candidatePaneView.groupByEnabled &&
           contentSize.height <= collectionView.bounds.height + rowHeight {
            // Expand the content size to let user to scroll upward to see the segment control.
            contentSize.height = collectionView.bounds.height + rowHeight
        }
        return contentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let allAttributes = super.layoutAttributesForElements(in: rect) ?? []
        
        var newLineIndices = [Int]()
        var maxY = -CGFloat.infinity
        for (i, attributes) in allAttributes.enumerated() {
            if attributes.representedElementKind == UICollectionView.elementKindSectionHeader {
                fixHeaderPosition(attributes)
            }
            if attributes.indexPath == [0, 0], let collectionViewSize = collectionView?.bounds {
                attributes.frame = CGRect(origin: .zero, size: CGSize(width: collectionViewSize.width, height: rowHeight))
            } else {
                let y = attributes.frame.origin.y
                if y > maxY {
                    newLineIndices.append(i)
                    maxY = y
                }
            }
        }
        let x = candidatePaneView?.headerWidth ?? 0
        for (i, index) in newLineIndices.enumerated() {
            if index + 1 == (newLineIndices[safe: i + 1] ?? allAttributes.count) {
                allAttributes[index].frame.origin.x = x
            }
        }
        
        return allAttributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        if let attributes = attributes, elementKind == UICollectionView.elementKindSectionHeader {
            fixHeaderPosition(attributes)
        }
        return attributes
    }
    
    private func fixHeaderPosition(_ headerAttributes: UICollectionViewLayoutAttributes) {
        guard let candidatePaneView = candidatePaneView,
              let collectionView = collectionView
            else { return }
        
        let section = headerAttributes.indexPath.section
        guard section < collectionView.numberOfSections else { return }
        
        var headerSizeInBytes = CGSize(width: candidatePaneView.sectionHeaderWidth, height: rowHeight)
        let numOfItemsInSection = collectionView.numberOfItems(inSection: section)
        var origin = headerAttributes.frame.origin
        if numOfItemsInSection > 0,
           let rectOfLastItemInSection = layoutAttributesForItem(at: [section, numOfItemsInSection - 1]) {
            origin.y = min(origin.y, rectOfLastItemInSection.frame.maxY - headerSizeInBytes.height)
            // Expand the header to cover the whole section vertically.
            headerSizeInBytes.height = rectOfLastItemInSection.frame.maxY - origin.y
        }
        headerAttributes.frame = CGRect(origin: origin, size: headerSizeInBytes)
    }
}
