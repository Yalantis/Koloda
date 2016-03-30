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

extension KolodaView {
    
    func animateAppearance(completion: ((Bool) -> Void)? = nil) {
        let kolodaAppearScaleAnimationName = "kolodaAppearScaleAnimation"
        let kolodaAppearScaleAnimationFromValue = CGPoint(x: 0.1, y: 0.1)
        let kolodaAppearScaleAnimationToValue = CGPoint(x: 1.0, y: 1.0)
        let kolodaAppearScaleAnimationDuration: NSTimeInterval = 0.8
        let kolodaAppearAlphaAnimationName = "kolodaAppearAlphaAnimation"
        let kolodaAppearAlphaAnimationFromValue: CGFloat = 0.0
        let kolodaAppearAlphaAnimationToValue: CGFloat = 1.0
        let kolodaAppearAlphaAnimationDuration: NSTimeInterval = 0.8
        
        let kolodaAppearScaleAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        
        kolodaAppearScaleAnimation.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearScaleAnimation.duration = kolodaAppearScaleAnimationDuration
        kolodaAppearScaleAnimation.fromValue = NSValue(CGPoint: kolodaAppearScaleAnimationFromValue)
        kolodaAppearScaleAnimation.toValue = NSValue(CGPoint: kolodaAppearScaleAnimationToValue)
        kolodaAppearScaleAnimation.completionBlock = { (_, finished) in
            completion?(finished)
        }
        
        let kolodaAppearAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        
        kolodaAppearAlphaAnimation.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearAlphaAnimation.fromValue = NSNumber(float: Float(kolodaAppearAlphaAnimationFromValue))
        kolodaAppearAlphaAnimation.toValue = NSNumber(float: Float(kolodaAppearAlphaAnimationToValue))
        kolodaAppearAlphaAnimation.duration = kolodaAppearAlphaAnimationDuration
        
        pop_addAnimation(kolodaAppearAlphaAnimation, forKey: kolodaAppearAlphaAnimationName)
        layer.pop_addAnimation(kolodaAppearScaleAnimation, forKey: kolodaAppearScaleAnimationName)
    }
    
    func applyRevertAnimation(card: DraggableCardView, completion: (() -> Void)? = nil) {
        
        let revertCardAnimationName = "revertCardAlphaAnimation"
        let revertCardAnimationDuration: NSTimeInterval = 1.0
        let revertCardAnimationToValue: CGFloat = 1.0
        let revertCardAnimationFromValue: CGFloat = 0.0
        
        let firstCardAppearAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        
        firstCardAppearAnimation.toValue = NSNumber(float: Float(revertCardAnimationToValue))
        firstCardAppearAnimation.fromValue =  NSNumber(float: Float(revertCardAnimationFromValue))
        firstCardAppearAnimation.duration = revertCardAnimationDuration
        firstCardAppearAnimation.completionBlock = { (_, _) in
            completion?()
        }
        
        card.pop_addAnimation(firstCardAppearAnimation, forKey: revertCardAnimationName)
    }
    
    func applyScaleAnimation(card: DraggableCardView, scale: CGSize, frame: CGRect, duration: NSTimeInterval, completion: ((Bool) -> Void)? = nil) {
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
    
    func applyAlphaAnimation(card: DraggableCardView, alpha: CGFloat, duration: NSTimeInterval = 0.2, completion: ((Bool) -> Void)? = nil) {
        let alphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        alphaAnimation.toValue = alpha
        alphaAnimation.duration = duration
        card.pop_addAnimation(alphaAnimation, forKey: "alpha")
    }
    
    internal func resetBackgroundCards(completion: ((Bool) -> Void)? = nil) {
        UIView.animateWithDuration(
            0.2,
            delay: 0.0,
            options: .CurveLinear,
            animations: {
                self.moveOtherCardsWithFinishPercent(0)
            },
            completion: { finished in
                completion?(finished)
        })
    }
    
}
