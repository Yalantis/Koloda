//
//  OverlayView.swift
//  TinderCardsSwift
//
//  Created by Eugene Andreyev on 4/24/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit
import pop

public enum OverlayMode{
    case None
    case Left
    case Right
}


public class OverlayView: UIView {
    
    public var overlayState:OverlayMode = OverlayMode.None

}
