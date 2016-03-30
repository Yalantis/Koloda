//
//  KolodaCardStorage.swift
//  Pods
//
//  Created by Eugene Andreyev on 3/30/16.
//
//

import Foundation
import UIKit

extension KolodaView {
    
    func createCardAtIndex(index: UInt, frame: CGRect? = nil) -> DraggableCardView {
        let nextCardContentView = dataSource!.koloda(self, viewForCardAtIndex: index)
        let nextCardView = DraggableCardView(frame: frame ?? frameForTopCard())
        
        nextCardView.delegate = self
        if shouldTransparentizeNextCard {
            nextCardView.alpha = index == 0 ? alphaValueOpaque : alphaValueSemiTransparent
        }
        
        nextCardView.configure(nextCardContentView, overlayView: dataSource?.koloda(self, viewForCardOverlayAtIndex: index))
        
        return nextCardView
    }
    
}