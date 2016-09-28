//
//  OverlayView.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/24/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit

open class OverlayView: UIView {
    
    open var overlayState: SwipeResultDirection?
    
    @available(*, unavailable, message: "Use updateWithProgress(percentage:) instead")
    open var overlayStrength: CGFloat = 0.0
    
    @available(*, introduced: 3.1.2)
    open func updateWithProgress(_ percentage: CGFloat) {
        alpha = percentage
    }

}
