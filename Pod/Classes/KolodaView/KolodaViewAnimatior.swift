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
    
    func animateAppearance(completion: ((Bool) -> Void)?) {
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
    
}
