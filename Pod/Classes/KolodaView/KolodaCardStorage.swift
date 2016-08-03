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
    
    func createCardAtIndex(_ index: UInt, frame: CGRect? = nil) -> DraggableCardView {
        let cardView = generateCard(frame ?? frameForTopCard())
        configureCard(cardView, atIndex: index)
        
        return cardView
    }
    
    func generateCard(_ frame: CGRect) -> DraggableCardView {
        let cardView = DraggableCardView(frame: frame)
        cardView.delegate = self
        
        return cardView
    }
    
    func configureCard(_ card: DraggableCardView, atIndex index: UInt) {
        let contentView = dataSource!.koloda(self, viewForCardAtIndex: index)
        card.configure(contentView, overlayView: dataSource?.koloda(self, viewForCardOverlayAtIndex: index))
    }
    
}
