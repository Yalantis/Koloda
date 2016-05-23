//
//  OverlayView.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/24/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit

public class OverlayView: UIView {
    
    public var overlayState: SwipeResultDirection?
    
    @available(*, deprecated=3.1.2)
    public var overlayStrength: CGFloat = 0.0 {
        didSet {
            self.alpha = overlayStrength
        }
    }
    
    @available(*, introduced=3.1.2)
    public func updateWithProgress(percentage: CGFloat) {
        overlayStrength = percentage
    }

}
