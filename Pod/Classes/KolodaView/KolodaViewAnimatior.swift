//
//  KolodaViewAnimatior.swift
//  Koloda
//
//  Created by Eugene Andreyev on 3/30/16.
//
//

import Foundation
import UIKit

open class KolodaViewAnimator {
    
    public typealias AnimationCompletionBlock = ((Bool) -> Void)?
    
    private weak var koloda: KolodaView?
    
    public init(koloda: KolodaView) {
        self.koloda = koloda
    }
    
    open func animateAppearance(_ duration: TimeInterval, completion: AnimationCompletionBlock = nil) {

        koloda?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        koloda?.alpha = 0

        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: cardSwipeActionAnimationDuration, options: []) {
            self.koloda?.transform = CGAffineTransform(scaleX: 1, y: 1)
        } completion: { position in
            completion?(position == .end)
        }
        
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: cardSwipeActionAnimationDuration, options: []) {
            self.koloda?.alpha = 1
        }
    }
    
    open func applyReverseAnimation(_ card: DraggableCardView, direction: SwipeResultDirection?, duration: TimeInterval, completion: AnimationCompletionBlock = nil) {

        card.alpha = 0

        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: direction != nil ? duration : 1.0, delay: 0, options: []) {
            card.alpha = 1
        } completion: { position in
            completion?(position == .end)
            card.alpha = 1.0
        }
        
        guard let direction = direction else { return }

        let animationPoint = card.animationPointForDirection(direction)
        let animationRotation = card.animationRotationForDirection(direction)
        card.transform = CGAffineTransform(translationX: animationPoint.x, y: animationPoint.y)
            .rotated(by: animationRotation)

        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: 0, options: []) {
            card.transform = .identity
        }
    }
    
    open func applyScaleAnimation(_ card: DraggableCardView, scale: CGSize, frame: CGRect, duration: TimeInterval, completion: AnimationCompletionBlock = nil) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: 0, options: []) {
            card.transform = CGAffineTransform(scaleX: scale.width, y: scale.height)
            card.frame = frame
        } completion: { position in
            completion?(position == .end)
        }
    }
    
    open func applyAlphaAnimation(_ card: DraggableCardView, alpha: CGFloat, duration: TimeInterval = 0.2, completion: AnimationCompletionBlock = nil) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: 0, options: []) {
            card.alpha = alpha
        } completion: { position in
            completion?(position == .end)
        }
    }
    
    open func applyInsertionAnimation(_ cards: [DraggableCardView], completion: AnimationCompletionBlock = nil) {
        let initialAlphas = cards.map { $0.alpha }
        cards.forEach { $0.alpha = 0.0 }
        UIView.animate(
            withDuration: 0.2,
            animations: {
                for (i, card) in cards.enumerated() {
                    card.alpha = initialAlphas[i]
                }
            },
            completion: { finished in
                completion?(finished)
            }
        )
    }
    
    open func applyRemovalAnimation(_ cards: [DraggableCardView], completion: AnimationCompletionBlock = nil) {
        UIView.animate(
            withDuration: 0.05,
            animations: {
                cards.forEach { $0.alpha = 0.0 }
            },
            completion: { finished in
                completion?(finished)
            }
        )
    }
    
    internal func resetBackgroundCardsWithCompletion(_ completion: AnimationCompletionBlock = nil) {
        UIView.animate(
            withDuration: 0.2,
            delay: 0.0,
            options: .curveLinear,
            animations: {
                self.koloda?.moveOtherCardsWithPercentage(0)
            },
            completion: { finished in
                completion?(finished)
        })
    }
    
}
