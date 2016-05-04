//
//  DraggableCardView.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/23/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//

import UIKit
import pop

protocol DraggableCardDelegate: class {
    
    func card(card: DraggableCardView, wasDraggedWithFinishPercentage percentage: CGFloat, inDirection direction: SwipeResultDirection)
    func card(card: DraggableCardView, wasSwipedInDirection direction: SwipeResultDirection)
    func card(card: DraggableCardView, shouldSwipeInDirection direction: SwipeResultDirection) -> Bool
    func card(cardWasReset card: DraggableCardView)
    func card(cardWasTapped card: DraggableCardView)
    func card(cardSwipeThresholdRatioMargin card: DraggableCardView) -> CGFloat?
    func card(cardAllowedDirections card: DraggableCardView) -> [SwipeResultDirection]
    func card(cardShouldDrag card: DraggableCardView) -> Bool
}

//Drag animation constants
private let rotationMax: CGFloat = 1.0
private let defaultRotationAngle = CGFloat(M_PI) / 10.0
private let scaleMin: CGFloat = 0.8
public let cardSwipeActionAnimationDuration: NSTimeInterval  = 0.4

private let screenSize = UIScreen.mainScreen().bounds.size

//Reset animation constants
private let cardResetAnimationSpringBounciness: CGFloat = 10.0
private let cardResetAnimationSpringSpeed: CGFloat = 20.0
private let cardResetAnimationKey = "resetPositionAnimation"
private let cardResetAnimationDuration: NSTimeInterval = 0.2

public class DraggableCardView: UIView, UIGestureRecognizerDelegate {
    
    weak var delegate: DraggableCardDelegate?
    
    private var overlayView: OverlayView?
    private(set) var contentView: UIView?
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var animationDirectionY: CGFloat = 1.0
    private var dragBegin = false
    private var dragDistance = CGPointZero
    private var swipePercentageMargin: CGFloat = 0.0
    
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
            if let ratio = delegate?.card(cardSwipeThresholdRatioMargin: self) where ratio != 0 {
                swipePercentageMargin = ratio
            } else {
                swipePercentageMargin = 1.0
            }
        }
    }
    
    deinit {
        removeGestureRecognizer(panGestureRecognizer)
        removeGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setup() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DraggableCardView.panGestureRecognized(_:)))
        addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DraggableCardView.tapRecognized(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: Configurations
    func configure(view: UIView, overlayView: OverlayView?) {
        self.overlayView?.removeFromSuperview()
        self.contentView?.removeFromSuperview()
        
        if let overlay = overlayView {
            self.overlayView = overlay
            overlay.alpha = 0;
            self.addSubview(overlay)
            configureOverlayView()
            self.insertSubview(view, belowSubview: overlay)
        } else {
            self.addSubview(view)
        }
        
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
    
    //MARK: GestureRecognizers
    func panGestureRecognized(gestureRecognizer: UIPanGestureRecognizer) {
        dragDistance = gestureRecognizer.translationInView(self)
        
        let touchLocation = gestureRecognizer.locationInView(self)
        
        switch gestureRecognizer.state {
        case .Began:
            
            let firstTouchPoint = gestureRecognizer.locationInView(self)
            let newAnchorPoint = CGPointMake(firstTouchPoint.x / bounds.width, firstTouchPoint.y / bounds.height)
            let oldPosition = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y)
            let newPosition = CGPoint(x: bounds.size.width * newAnchorPoint.x, y: bounds.size.height * newAnchorPoint.y)
            layer.anchorPoint = newAnchorPoint
            layer.position = CGPoint(x: layer.position.x - oldPosition.x + newPosition.x, y: layer.position.y - oldPosition.y + newPosition.y)
            removeAnimations()
            
            dragBegin = true
            
            animationDirectionY = touchLocation.y >= frame.size.height / 2 ? -1.0 : 1.0
            layer.rasterizationScale = UIScreen.mainScreen().scale
            layer.shouldRasterize = true
            
            break
        case .Changed:
            let rotationStrength = min(dragDistance.x / CGRectGetWidth(frame), rotationMax)
            let rotationAngle = animationDirectionY * defaultRotationAngle * rotationStrength
            let scaleStrength = 1 - ((1 - scaleMin) * fabs(rotationStrength))
            let scale = max(scaleStrength, scaleMin)
    
            var transform = CATransform3DIdentity
            transform = CATransform3DScale(transform, scale, scale, 1)
            transform = CATransform3DRotate(transform, rotationAngle, 0, 0, 1)
            transform = CATransform3DTranslate(transform, dragDistance.x, dragDistance.y, 0)
            layer.transform = transform
            
            let percentage = dragPercentage
            updateOverlayWithFinishPercent(percentage, direction:dragDirection)
            if let dragDirection = dragDirection {
                //100% - for proportion
                delegate?.card(self, wasDraggedWithFinishPercentage: min(fabs(100 * percentage), 100), inDirection: dragDirection)
            }
            
            break
        case .Ended:
            swipeMadeAction()
            
            layer.shouldRasterize = false
        default :
            break
        }
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return delegate?.card(cardShouldDrag: self) ?? true
    }
    
    func tapRecognized(recogznier: UITapGestureRecognizer) {
        delegate?.card(cardWasTapped: self)
    }
    
    //MARK: Private
    
    private var directions: [SwipeResultDirection] {
        return delegate?.card(cardAllowedDirections: self) ?? [.Left, .Right]
    }
    
    private var dragDirection: SwipeResultDirection? {
        //find closest direction
        let normalizedDragPoint = dragDistance.normalizedDistanceForSize(bounds.size)
        return directions.reduce((distance:CGFloat.infinity, direction:nil)) { closest, direction in
            let distance = direction.point.distanceTo(normalizedDragPoint)
            if distance < closest.distance {
                return (distance, direction)
            }
            return closest
        }.direction
    }
    
    private var dragPercentage: CGFloat {
        guard let dragDirection = dragDirection else { return 0 }
        // normalize dragDistance then convert project closesest direction vector
        let normalizedDragPoint = dragDistance.normalizedDistanceForSize(frame.size)
        let swipePoint = normalizedDragPoint.scalarProjectionPointWith(dragDirection.point)
        
        // rect to represent bounds of card in normalized coordinate system
        let rect = SwipeResultDirection.boundsRect
        
        // if point is outside rect, percentage of swipe in direction is over 100%
        if !rect.contains(swipePoint) {
            return 1.0
        } else {
            let centerDistance = swipePoint.distanceTo(.zero)
            let targetLine = (swipePoint, CGPoint.zero)
            
            // check 4 borders for intersection with line between touchpoint and center of card
            // return smallest percentage of distance to edge point or 0
            return rect.perimeterLines
                        .flatMap { CGPoint.intersectionBetweenLines(targetLine, line2: $0) }
                        .map { centerDistance / $0.distanceTo(.zero) }
                        .minElement() ?? 0
        }
    }
    
    
    private func updateOverlayWithFinishPercent(percent: CGFloat, direction: SwipeResultDirection?) {
        overlayView?.overlayState = direction
        overlayView?.overlayStrength = max(min(percent/swipePercentageMargin, 1.0), 0)
    }
    
    private func swipeMadeAction() {
        let shouldSwipe = { direction in
            return self.delegate?.card(self, shouldSwipeInDirection: direction) ?? true
        }
        if let dragDirection = dragDirection where shouldSwipe(dragDirection) && dragPercentage >= swipePercentageMargin && directions.contains(dragDirection) {
            swipeAction(dragDirection)
        } else {
            resetViewPositionAndTransformations()
        }
    }
    
    private func animationPointForDirection(direction: SwipeResultDirection) -> CGPoint {
        let point = direction.point
        let animatePoint = CGPoint(x: point.x * 4, y: point.y * 4) //should be 2
        let retPoint = animatePoint.screenPointForSize(screenSize)
        return retPoint
    }
    
    private func animationRotationForDirection(direction: SwipeResultDirection) -> CGFloat {
        return CGFloat(direction.bearing / 2.0 - M_PI_4)
    }

    
    private func swipeAction(direction: SwipeResultDirection) {
        overlayView?.overlayState = direction
        overlayView?.alpha = 1.0
        delegate?.card(self, wasSwipedInDirection: direction)
        let translationAnimation = POPBasicAnimation(propertyNamed: kPOPLayerTranslationXY)
        translationAnimation.duration = cardSwipeActionAnimationDuration
        translationAnimation.fromValue = NSValue(CGPoint: POPLayerGetTranslationXY(layer))
        translationAnimation.toValue = NSValue(CGPoint: animationPointForDirection(direction))
        translationAnimation.completionBlock = { _, _ in
            self.removeFromSuperview()
        }
        layer.pop_addAnimation(translationAnimation, forKey: "swipeTranslationAnimation")
    }
    
    private func resetViewPositionAndTransformations() {
        delegate?.card(cardWasReset: self)
        
        removeAnimations()
        
        let resetPositionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerTranslationXY)
        resetPositionAnimation.fromValue = NSValue(CGPoint:POPLayerGetTranslationXY(layer))
        resetPositionAnimation.toValue = NSValue(CGPoint: CGPointZero)
        resetPositionAnimation.springBounciness = cardResetAnimationSpringBounciness
        resetPositionAnimation.springSpeed = cardResetAnimationSpringSpeed
        resetPositionAnimation.completionBlock = {
            (_, _) in
            self.layer.transform = CATransform3DIdentity
            self.dragBegin = false
        }
        
        layer.pop_addAnimation(resetPositionAnimation, forKey: "resetPositionAnimation")
        
        let resetRotationAnimation = POPBasicAnimation(propertyNamed: kPOPLayerRotation)
        resetRotationAnimation.fromValue = POPLayerGetRotationZ(layer)
        resetRotationAnimation.toValue = CGFloat(0.0)
        resetRotationAnimation.duration = cardResetAnimationDuration
        
        layer.pop_addAnimation(resetRotationAnimation, forKey: "resetRotationAnimation")
        
        let overlayAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        overlayAlphaAnimation.toValue = 0.0
        overlayAlphaAnimation.duration = cardResetAnimationDuration
        overlayAlphaAnimation.completionBlock = { _, _ in
            self.overlayView?.alpha = 0
        }
        overlayView?.pop_addAnimation(overlayAlphaAnimation, forKey: "resetOverlayAnimation")
        
        let resetScaleAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        resetScaleAnimation.toValue = NSValue(CGPoint: CGPoint(x: 1.0, y: 1.0))
        resetScaleAnimation.duration = cardResetAnimationDuration
        layer.pop_addAnimation(resetScaleAnimation, forKey: "resetScaleAnimation")
    }
    
    //MARK: Public
    func removeAnimations() {
        pop_removeAllAnimations()
        layer.pop_removeAllAnimations()
    }
    
    func swipe(direction: SwipeResultDirection) {
        if !dragBegin {
            delegate?.card(self, wasSwipedInDirection: direction)
            
            let swipePositionAnimation = POPBasicAnimation(propertyNamed: kPOPLayerTranslationXY)
            swipePositionAnimation.fromValue = NSValue(CGPoint:POPLayerGetTranslationXY(layer))
            swipePositionAnimation.toValue = NSValue(CGPoint:animationPointForDirection(direction))
            swipePositionAnimation.duration = cardSwipeActionAnimationDuration
            swipePositionAnimation.completionBlock = {
                (_, _) in
                self.removeFromSuperview()
            }
            
            layer.pop_addAnimation(swipePositionAnimation, forKey: "swipePositionAnimation")
            
            let swipeRotationAnimation = POPBasicAnimation(propertyNamed: kPOPLayerRotation)
            swipeRotationAnimation.fromValue = POPLayerGetRotationZ(layer)
            swipeRotationAnimation.toValue = CGFloat(animationRotationForDirection(direction))
            swipeRotationAnimation.duration = cardSwipeActionAnimationDuration
            
            layer.pop_addAnimation(swipeRotationAnimation, forKey: "swipeRotationAnimation")
            
            overlayView?.overlayState = direction
            let overlayAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
            overlayAlphaAnimation.toValue = 1.0
            overlayAlphaAnimation.duration = cardSwipeActionAnimationDuration
            overlayView?.pop_addAnimation(overlayAlphaAnimation, forKey: "swipeOverlayAnimation")
        }
    }
}
