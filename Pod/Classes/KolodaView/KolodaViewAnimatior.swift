//
//  KolodaViewAnimatior.swift
//  Koloda
//
//  Created by Eugene Andreyev on 3/30/16.
//
//

import Foundation
import UIKit
import pop

open class KolodaViewAnimator {
    
    public typealias AnimationCompletionBlock = ((Bool) -> Void)?
    
    private weak var koloda: KolodaView?
    
    public init(koloda: KolodaView) {
        self.koloda = koloda
    }
    
    open func animateAppearance(_ duration: TimeInterval, completion: AnimationCompletionBlock = nil) {
        let kolodaAppearScaleAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        
        kolodaAppearScaleAnimation?.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearScaleAnimation?.duration = duration
        kolodaAppearScaleAnimation?.fromValue = NSValue(cgPoint: CGPoint(x: 0.1, y: 0.1))
        kolodaAppearScaleAnimation?.toValue = NSValue(cgPoint: CGPoint(x: 1.0, y: 1.0))
        kolodaAppearScaleAnimation?.completionBlock = { (_, finished) in
            completion?(finished)
        }
        
        let kolodaAppearAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        
        kolodaAppearAlphaAnimation?.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearAlphaAnimation?.fromValue = NSNumber(value: 0.0)
        kolodaAppearAlphaAnimation?.toValue = NSNumber(value: 1.0)
        kolodaAppearAlphaAnimation?.duration = duration
        
        koloda?.pop_add(kolodaAppearAlphaAnimation, forKey: "kolodaAppearScaleAnimation")
        koloda?.layer.pop_add(kolodaAppearScaleAnimation, forKey: "kolodaAppearAlphaAnimation")
    }
    
    open func applyReverseAnimation(_ card: DraggableCardView, direction: SwipeResultDirection?, duration: TimeInterval, completion: AnimationCompletionBlock = nil) {
        let alphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        alphaAnimation?.fromValue =  NSNumber(value: 0.0)
        alphaAnimation?.toValue = NSNumber(value: 1.0)
        alphaAnimation?.duration = direction != nil ? duration : 1.0
        alphaAnimation?.completionBlock = { _, finished in
            completion?(finished)
            card.alpha = 1.0
        }
        card.pop_add(alphaAnimation, forKey: "reverseCardAlphaAnimation")
        
        guard let direction = direction else { return }
        
        let translationAnimation = POPBasicAnimation(propertyNamed: kPOPLayerTranslationXY)
        translationAnimation?.fromValue = NSValue(cgPoint: card.animationPointForDirection(direction))
        translationAnimation?.toValue = NSValue(cgPoint: CGPoint.zero)
        translationAnimation?.duration = duration
        card.layer.pop_add(translationAnimation, forKey: "reverseCardTranslationAnimation")
        
        let rotationAnimation = POPBasicAnimation(propertyNamed: kPOPLayerRotation)
        rotationAnimation?.fromValue = CGFloat(card.animationRotationForDirection(direction))
        rotationAnimation?.toValue = CGFloat(0.0)
        rotationAnimation?.duration = duration
        card.layer.pop_add(rotationAnimation, forKey: "reverseCardRotationAnimation")
    }
    
    open func applyScaleAnimation(_ card: DraggableCardView, scale: CGSize, frame: CGRect, duration: TimeInterval, completion: AnimationCompletionBlock = nil) {
        let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnimation?.duration = duration
        scaleAnimation?.toValue = NSValue(cgSize: scale)
        card.layer.pop_add(scaleAnimation, forKey: "scaleAnimation")
        
        let frameAnimation = POPBasicAnimation(propertyNamed: kPOPViewFrame)
        frameAnimation?.duration = duration
        frameAnimation?.toValue = NSValue(cgRect: frame)
        if let completion = completion {
            frameAnimation?.completionBlock = { _, finished in
                completion(finished)
            }
        }
        card.pop_add(frameAnimation, forKey: "frameAnimation")
    }
    
    open func applyAlphaAnimation(_ card: DraggableCardView, alpha: CGFloat, duration: TimeInterval = 0.2, completion: AnimationCompletionBlock = nil) {
        let alphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        alphaAnimation?.toValue = alpha
        alphaAnimation?.duration = duration
        alphaAnimation?.completionBlock = { _, finished in
            completion?(finished)
        }
        card.pop_add(alphaAnimation, forKey: "alpha")
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
