//
//  BackgroundKolodaAnimator.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import Koloda
import pop

class BackgroundKolodaAnimator: KolodaViewAnimator {
    
    override func applyScaleAnimation(card: DraggableCardView, scale: CGSize, frame: CGRect, duration: NSTimeInterval, completion: AnimationCompletionBlock) {
        
        let scaleAnimation = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnimation.springBounciness = 9
        scaleAnimation.springSpeed = 16
        scaleAnimation.toValue = NSValue(CGSize: scale)
        card.layer.pop_addAnimation(scaleAnimation, forKey: "scaleAnimation")
        
        let frameAnimation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
        frameAnimation.springBounciness = 9
        frameAnimation.springSpeed = 16
        frameAnimation.toValue = NSValue(CGRect: frame)
        if let completion = completion {
            frameAnimation.completionBlock = { _, finished in
                completion(finished)
            }
        }
        card.pop_addAnimation(frameAnimation, forKey: "frameAnimation")
    }
    
}