//
//  DraggableCardView.swift
//  TinderCardsSwift
//
//  Created by Eugene Andreyev on 4/23/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//

import UIKit
import JNWSpringAnimation

protocol DraggableCardDelegate: class {
    
    func cardDraggedWithFinishPercent(card: DraggableCardView, percent: CGFloat, direction: SwipeResultDirection)
    func cardSwippedInDirection(card: DraggableCardView, direction: SwipeResultDirection)
    func cardWasReset(card: DraggableCardView)
    func cardTapped(card: DraggableCardView)
    
}

//Drag animation constants
private let rotationMax: CGFloat = 1.0
private let defaultRotationAngle = CGFloat(M_PI) / 10.0
private let scaleMin: CGFloat = 0.8
public let cardSwipeActionAnimationDuration: NSTimeInterval  = 0.4

//Reset animation constants
private let cardResetAnimationDuration: NSTimeInterval = 0.2

public class DraggableCardView: UIView {
    
    weak var delegate: DraggableCardDelegate?
    
    private var overlayView: OverlayView?
    private(set) var contentView: UIView?
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var animationDirection: CGFloat = 1.0
    private var dragBegin = false
    private var dragDistance = CGPointZero
    private var actionMargin: CGFloat = 0.0
    private var firstTouch = true
    
    //MARK: Lifecycle
    init() {
        super.init(frame: CGRectZero)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override public var frame: CGRect {
        didSet {
            actionMargin = frame.size.width / 2.0
        }
    }
    
    deinit {
        removeGestureRecognizer(panGestureRecognizer)
        removeGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setup() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: Selector("panGestureRecognized:"))
        addGestureRecognizer(panGestureRecognizer)
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("tapRecognized:"))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: Configurations
    func configure(view: UIView, overlayView: OverlayView?) {
        self.overlayView?.removeFromSuperview()
        
        if let overlay = overlayView {
            self.overlayView = overlay
            overlay.alpha = 0;
            self.addSubview(overlay)
            configureOverlayView()
            self.insertSubview(view, belowSubview: overlay)
        } else {
            self.addSubview(view)
        }
        
        self.contentView?.removeFromSuperview()
        self.contentView = view
        configureContentView()
    }
    
    private func configureOverlayView() {
        if let overlay = self.overlayView {
            overlay.translatesAutoresizingMaskIntoConstraints = false
            
            let width = NSLayoutConstraint(
                item: overlay,
                attribute: NSLayoutAttribute.Width,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self,
                attribute: NSLayoutAttribute.Width,
                multiplier: 1.0,
                constant: 0)
            let height = NSLayoutConstraint(
                item: overlay,
                attribute: NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self,
                attribute: NSLayoutAttribute.Height,
                multiplier: 1.0,
                constant: 0)
            let top = NSLayoutConstraint (
                item: overlay,
                attribute: NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self,
                attribute: NSLayoutAttribute.Top,
                multiplier: 1.0,
                constant: 0)
            let leading = NSLayoutConstraint (
                item: overlay,
                attribute: NSLayoutAttribute.Leading,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self,
                attribute: NSLayoutAttribute.Leading,
                multiplier: 1.0,
                constant: 0)
            addConstraints([width,height,top,leading])
        }
    }
    
    private func configureContentView() {
        if let contentView = self.contentView {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            
            let width = NSLayoutConstraint(
                item: contentView,
                attribute: NSLayoutAttribute.Width,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self,
                attribute: NSLayoutAttribute.Width,
                multiplier: 1.0,
                constant: 0)
            let height = NSLayoutConstraint(
                item: contentView,
                attribute: NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self,
                attribute: NSLayoutAttribute.Height,
                multiplier: 1.0,
                constant: 0)
            let top = NSLayoutConstraint (
                item: contentView,
                attribute: NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self,
                attribute: NSLayoutAttribute.Top,
                multiplier: 1.0,
                constant: 0)
            let leading = NSLayoutConstraint (
                item: contentView,
                attribute: NSLayoutAttribute.Leading,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self,
                attribute: NSLayoutAttribute.Leading,
                multiplier: 1.0,
                constant: 0)
            
            addConstraints([width,height,top,leading])
        }
    }
    
    //MARK: GestureRecozniers
    
    func panGestureRecognized(gestureRecognizer: UIPanGestureRecognizer) {
        dragDistance = gestureRecognizer.translationInView(self)
        
        let touchLocation = gestureRecognizer.locationInView(self)
        
        switch gestureRecognizer.state {
        case .Began:
            if firstTouch {
                firstTouch = false
                
                let firstTouchPoint = gestureRecognizer.locationInView(self)
                let newAnchorPoint = CGPointMake(firstTouchPoint.x / bounds.width, firstTouchPoint.y / bounds.height)
                
                let oldPosition = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y)
                let newPosition = CGPoint(x: bounds.size.width * newAnchorPoint.x, y: bounds.size.height * newAnchorPoint.y)
                
                layer.anchorPoint = newAnchorPoint
                layer.position = CGPoint(x: layer.position.x - oldPosition.x + newPosition.x, y: layer.position.y - oldPosition.y + newPosition.y)
            }
            dragBegin = true
            
            animationDirection = touchLocation.y >= frame.size.height / 2 ? -1.0 : 1.0
            
            layer.shouldRasterize = true
            
            layer.removeAllAnimations()
            break
        case .Changed:
            let rotationStrength = min(dragDistance.x / self.frame.size.width, rotationMax)
            let rotationAngle = animationDirection * defaultRotationAngle * rotationStrength
            let scaleStrength = 1 - ((1 - scaleMin) * fabs(rotationStrength))
            let scale = max(scaleStrength, scaleMin)
            
            layer.rasterizationScale = scale * UIScreen.mainScreen().scale
            
            var transform = CATransform3DIdentity
            transform = CATransform3DScale(transform, scale, scale, 1)
            transform = CATransform3DRotate(transform, rotationAngle, 0, 0, 1)
            transform = CATransform3DTranslate(transform, dragDistance.x, dragDistance.y, 0)
            
            layer.transform = transform
            
            updateOverlayWithFinishPercent(dragDistance.x / frame.size.width)
            //100% - for proportion
            delegate?.cardDraggedWithFinishPercent(self, percent: min(fabs(dragDistance.x * 100 / frame.size.width), 100), direction: dragDirection)
            
            break
        case .Ended:
            swipeMadeAction()
            
            layer.shouldRasterize = false
            firstTouch = true
        default :
            break
        }
    }
    
    func tapRecognized(recogznier: UITapGestureRecognizer) {
        delegate?.cardTapped(self)
    }
    
    //MARK: Private
    
    private var dragDirection: SwipeResultDirection {
        return dragDistance.x > 0 ? .Right : .Left
    }
    
    private func updateOverlayWithFinishPercent(percent: CGFloat) {
        if let overlayView = self.overlayView {
            overlayView.overlayState = percent > 0.0 ? OverlayMode.Right : OverlayMode.Left
            //Overlay is fully visible on half way
            let overlayStrength = min(fabs(2 * percent), 1.0)
            overlayView.alpha = overlayStrength
        }
    }
    
    private func swipeMadeAction() {
        if abs(dragDistance.x) > actionMargin {
            let xDistance = dragDirection == .Left ? -CGRectGetWidth(UIScreen.mainScreen().bounds) : CGRectGetWidth(UIScreen.mainScreen().bounds) * 2
            
            overlayView?.overlayState = dragDirection == .Left ? .Left : .Right
            overlayView?.alpha = 1.0
            delegate?.cardSwippedInDirection(self, direction: dragDirection)
            
            let newTransform = CATransform3DConcat(layer.transform, CATransform3DMakeTranslation(xDistance, 0, 0))
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            transformAnimation.duration = cardSwipeActionAnimationDuration
            transformAnimation.removedOnCompletion = true
            transformAnimation.fillMode = kCAFillModeForwards
            transformAnimation.fromValue = NSValue(CATransform3D: layer.transform)
            transformAnimation.toValue = NSValue(CATransform3D: newTransform)
            
            layer.transform = newTransform
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.dragBegin = false
                self.removeFromSuperview()
            }
            layer.addAnimation(transformAnimation, forKey: "transform")
            CATransaction.commit()
        } else {
            resetViewPositionAndTransformations()
        }
    }
    
    private func resetViewPositionAndTransformations() {
        self.delegate?.cardWasReset(self)
        
        let newAnchorPoint = CGPoint(x: 0.5, y: 0.5)
        let anchorPointAnimation = CABasicAnimation(keyPath: "anchorPoint")
        anchorPointAnimation.duration = cardResetAnimationDuration
        anchorPointAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        anchorPointAnimation.removedOnCompletion = true
        anchorPointAnimation.fillMode = kCAFillModeForwards
        anchorPointAnimation.fromValue = NSValue(CGPoint: layer.anchorPoint)
        anchorPointAnimation.toValue = NSValue(CGPoint: newAnchorPoint)
        

        let newPosition = CGPoint(x: layer.bounds.width / 2, y: layer.bounds.height / 2)
        let positionAnimation = CABasicAnimation(keyPath: "position")
        positionAnimation.duration = cardResetAnimationDuration
        positionAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        positionAnimation.removedOnCompletion = true
        positionAnimation.fillMode = kCAFillModeForwards
        positionAnimation.fromValue = NSValue(CGPoint: layer.position)
        positionAnimation.toValue = NSValue(CGPoint: newPosition)
        
        
        let newTransform = CATransform3DIdentity
        let transformAnimation = JNWSpringAnimation(keyPath: "transform")
        transformAnimation.stiffness = 600
        transformAnimation.damping = 60
        transformAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        transformAnimation.removedOnCompletion = true
        transformAnimation.fillMode = kCAFillModeForwards
        transformAnimation.fromValue = NSValue(CATransform3D: layer.transform)
        transformAnimation.toValue = NSValue(CATransform3D: newTransform)
        

        layer.anchorPoint = newAnchorPoint
        layer.position = newPosition
        layer.transform = newTransform
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.dragBegin = false
        }
        layer.addAnimation(anchorPointAnimation, forKey: "anchorPoint")
        layer.addAnimation(positionAnimation, forKey: "position")
        layer.addAnimation(transformAnimation, forKey: "transform")
        CATransaction.commit()
        
        UIView.animateWithDuration(cardResetAnimationDuration) {
            self.overlayView?.alpha = 0
        }
    }
    
    //MARK: Public
    
    func swipeLeft () {
        if !dragBegin {
            
            let finishPoint = CGPoint(x: -CGRectGetWidth(UIScreen.mainScreen().bounds), y: center.y)
            self.delegate?.cardSwippedInDirection(self, direction: SwipeResultDirection.Left)
            UIView.animateWithDuration(cardSwipeActionAnimationDuration,
                delay: 0.0,
                options: .CurveLinear,
                animations: {
                    self.center = finishPoint
                    self.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_4))
                    
                    return
                },
                completion: {
                    _ in
                    
                    self.removeFromSuperview()
                    
                    return
            })
        }
    }
    
    func swipeRight () {
        if !dragBegin {
            
            let finishPoint = CGPoint(x: CGRectGetWidth(UIScreen.mainScreen().bounds) * 2, y: center.y)
            self.delegate?.cardSwippedInDirection(self, direction: SwipeResultDirection.Right)
            UIView.animateWithDuration(cardSwipeActionAnimationDuration, delay: 0.0, options: .CurveLinear, animations: {
                    self.center = finishPoint
                    self.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_4))
                    
                    return
                },
                completion: {
                    _ in
                    
                    self.removeFromSuperview()
                    
                    return
            })
        }
    }
}
