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

public class KolodaViewAnimator {
    
    private weak var koloda: KolodaView?
    
    init(koloda: KolodaView) {
        self.koloda = koloda
    }
    
    public func animateAppearance(completion: ((Bool) -> Void)? = nil) {
        let kolodaAppearScaleAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        
        kolodaAppearScaleAnimation.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearScaleAnimation.duration = 0.8
        kolodaAppearScaleAnimation.fromValue = NSValue(CGPoint: CGPoint(x: 0.1, y: 0.1))
        kolodaAppearScaleAnimation.toValue = NSValue(CGPoint: CGPoint(x: 1.0, y: 1.0))
        kolodaAppearScaleAnimation.completionBlock = { (_, finished) in
            completion?(finished)
        }
        
        let kolodaAppearAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        
        kolodaAppearAlphaAnimation.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearAlphaAnimation.fromValue = NSNumber(float: 0.0)
        kolodaAppearAlphaAnimation.toValue = NSNumber(float: 1.0)
        kolodaAppearAlphaAnimation.duration = 0.8
        
        koloda?.pop_addAnimation(kolodaAppearAlphaAnimation, forKey: "kolodaAppearScaleAnimation")
        koloda?.layer.pop_addAnimation(kolodaAppearScaleAnimation, forKey: "kolodaAppearAlphaAnimation")
    }
    
    public func applyRevertAnimation(card: DraggableCardView, completion: (() -> Void)? = nil) {
        let firstCardAppearAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        
        firstCardAppearAnimation.toValue = NSNumber(float: 1.0)
        firstCardAppearAnimation.fromValue =  NSNumber(float: 0.0)
        firstCardAppearAnimation.duration = 1.0
        firstCardAppearAnimation.completionBlock = { (_, _) in
            completion?()
        }
        
        card.pop_addAnimation(firstCardAppearAnimation, forKey: "revertCardAlphaAnimation")
    }
    
    public func applyScaleAnimation(card: DraggableCardView, scale: CGSize, frame: CGRect, duration: NSTimeInterval, completion: ((Bool) -> Void)? = nil) {
        let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnimation.duration = duration
        scaleAnimation.toValue = NSValue(CGSize: scale)
        card.layer.pop_addAnimation(scaleAnimation, forKey: "scaleAnimation")
        
        let frameAnimation = POPBasicAnimation(propertyNamed: kPOPViewFrame)
        frameAnimation.duration = duration
        frameAnimation.toValue = NSValue(CGRect: frame)
        if let completion = completion {
            frameAnimation.completionBlock = { _, finished in
                completion(finished)
            }
        }
        card.pop_addAnimation(frameAnimation, forKey: "frameAnimation")
    }
    
    public func applyAlphaAnimation(card: DraggableCardView, alpha: CGFloat, duration: NSTimeInterval = 0.2, completion: ((Bool) -> Void)? = nil) {
        let alphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        alphaAnimation.toValue = alpha
        alphaAnimation.duration = duration
        card.pop_addAnimation(alphaAnimation, forKey: "alpha")
    }
    
    public func applyInsertionAnimation(cards: [DraggableCardView], completion: ((Bool) -> Void)? = nil) {
        cards.forEach { $0.alpha = 0.0 }
        UIView.animateWithDuration(
            0.2,
            animations: {
                cards.forEach { $0.alpha = 1.0 }
            },
            completion: { finished in
                completion?(finished)
            }
        )
    }
    
    public func applyRemovalAnimation(cards: [DraggableCardView], completion: ((Bool) -> Void)? = nil) {
        UIView.animateWithDuration(
            0.05,
            animations: {
                cards.forEach { $0.alpha = 0.0 }
            },
            completion: { finished in
                completion?(finished)
            }
        )
    }
    
    internal func resetBackgroundCards(completion: ((Bool) -> Void)? = nil) {
        UIView.animateWithDuration(
            0.2,
            delay: 0.0,
            options: .CurveLinear,
            animations: {
                self.koloda?.moveOtherCardsWithFinishPercent(0)
            },
            completion: { finished in
                completion?(finished)
        })
    }
    
}
