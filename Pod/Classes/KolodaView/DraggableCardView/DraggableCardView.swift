//
//  DraggableCardView.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/23/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//

import UIKit
import pop

public enum DragSpeed: TimeInterval {
    case slow = 2.0
    case moderate = 1.5
    case `default` = 0.8
    case fast = 0.4
}

protocol DraggableCardDelegate: class {
    
    func card(_ card: DraggableCardView, wasDraggedWithFinishPercentage percentage: CGFloat, inDirection direction: SwipeResultDirection)
    func card(_ card: DraggableCardView, wasSwipedIn direction: SwipeResultDirection)
    func card(_ card: DraggableCardView, shouldSwipeIn direction: SwipeResultDirection) -> Bool
    func card(cardWasReset card: DraggableCardView)
    func card(cardWasTapped card: DraggableCardView)
    func card(cardSwipeThresholdRatioMargin card: DraggableCardView) -> CGFloat?
    func card(cardAllowedDirections card: DraggableCardView) -> [SwipeResultDirection]
    func card(cardShouldDrag card: DraggableCardView) -> Bool
    func card(cardSwipeSpeed card: DraggableCardView) -> DragSpeed
}

//Drag animation constants
private let rotationMax: CGFloat = 1.0
private let defaultRotationAngle = CGFloat(Double.pi) / 10.0
private let scaleMin: CGFloat = 0.8

private let screenSize = UIScreen.main.bounds.size

//Reset animation constants
private let cardResetAnimationSpringBounciness: CGFloat = 10.0
private let cardResetAnimationSpringSpeed: CGFloat = 20.0
private let cardResetAnimationKey = "resetPositionAnimation"
private let cardResetAnimationDuration: TimeInterval = 0.2
internal var cardSwipeActionAnimationDuration: TimeInterval = DragSpeed.default.rawValue

public class DraggableCardView: UIView, UIGestureRecognizerDelegate {
    
    weak var delegate: DraggableCardDelegate?
    
    private var overlayView: OverlayView?
    private(set) var contentView: UIView?
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var animationDirectionY: CGFloat = 1.0
    private var dragBegin = false
    private var dragDistance = CGPoint.zero
    private var swipePercentageMargin: CGFloat = 0.0

    
    //MARK: Lifecycle
    init() {
        super.init(frame: CGRect.zero)
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
            if let ratio = delegate?.card(cardSwipeThresholdRatioMargin: self) , ratio != 0 {
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
        tapGestureRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(tapGestureRecognizer)

        if let delegate = delegate {
            cardSwipeActionAnimationDuration = delegate.card(cardSwipeSpeed: self).rawValue
        }
    }
    
    //MARK: Configurations
    func configure(_ view: UIView, overlayView: OverlayView?) {
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
                attribute: NSLayoutAttribute.width,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.width,
                multiplier: 1.0,
                constant: 0)
            let height = NSLayoutConstraint(
                item: overlay,
                attribute: NSLayoutAttribute.height,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.height,
                multiplier: 1.0,
                constant: 0)
            let top = NSLayoutConstraint (
                item: overlay,
                attribute: NSLayoutAttribute.top,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.top,
                multiplier: 1.0,
                constant: 0)
            let leading = NSLayoutConstraint (
                item: overlay,
                attribute: NSLayoutAttribute.leading,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.leading,
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
                attribute: NSLayoutAttribute.width,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.width,
                multiplier: 1.0,
                constant: 0)
            let height = NSLayoutConstraint(
                item: contentView,
                attribute: NSLayoutAttribute.height,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.height,
                multiplier: 1.0,
                constant: 0)
            let top = NSLayoutConstraint (
                item: contentView,
                attribute: NSLayoutAttribute.top,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.top,
                multiplier: 1.0,
                constant: 0)
            let leading = NSLayoutConstraint (
                item: contentView,
                attribute: NSLayoutAttribute.leading,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.leading,
                multiplier: 1.0,
                constant: 0)
            
            addConstraints([width,height,top,leading])
        }
    }
    
    //MARK: GestureRecognizers
    func panGestureRecognized(_ gestureRecognizer: UIPanGestureRecognizer) {
        dragDistance = gestureRecognizer.translation(in: self)
        
        let touchLocation = gestureRecognizer.location(in: self)
        
        switch gestureRecognizer.state {
        case .began:
            
            let firstTouchPoint = gestureRecognizer.location(in: self)
            let newAnchorPoint = CGPoint(x: firstTouchPoint.x / bounds.width, y: firstTouchPoint.y / bounds.height)
            let oldPosition = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y)
            let newPosition = CGPoint(x: bounds.size.width * newAnchorPoint.x, y: bounds.size.height * newAnchorPoint.y)
            layer.anchorPoint = newAnchorPoint
            layer.position = CGPoint(x: layer.position.x - oldPosition.x + newPosition.x, y: layer.position.y - oldPosition.y + newPosition.y)
            removeAnimations()
            
            dragBegin = true
            
            animationDirectionY = touchLocation.y >= frame.size.height / 2 ? -1.0 : 1.0
            layer.rasterizationScale = UIScreen.main.scale
            layer.shouldRasterize = true
            
        case .changed:
            let rotationStrength = min(dragDistance.x / frame.width, rotationMax)
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
            
        case .ended:
            swipeMadeAction()
            
            layer.shouldRasterize = false
            
        default:
            layer.shouldRasterize = false
            resetViewPositionAndTransformations()
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return delegate?.card(cardShouldDrag: self) ?? true
    }
    
    func tapRecognized(_ recogznier: UITapGestureRecognizer) {
        delegate?.card(cardWasTapped: self)
    }
    
    //MARK: Private
    
    private var directions: [SwipeResultDirection] {
        return delegate?.card(cardAllowedDirections: self) ?? [.left, .right]
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
                        .min() ?? 0
        }
    }
    
    
    private func updateOverlayWithFinishPercent(_ percent: CGFloat, direction: SwipeResultDirection?) {
        overlayView?.overlayState = direction
        let progress = max(min(percent/swipePercentageMargin, 1.0), 0)
        overlayView?.update(progress: progress)
    }
    
    private func swipeMadeAction() {
        let shouldSwipe = { direction in
            return self.delegate?.card(self, shouldSwipeIn: direction) ?? true
        }
        if let dragDirection = dragDirection , shouldSwipe(dragDirection) && dragPercentage >= swipePercentageMargin && directions.contains(dragDirection) {
            swipeAction(dragDirection)
        } else {
            resetViewPositionAndTransformations()
        }
    }
    
    private func animationPointForDirection(_ direction: SwipeResultDirection) -> CGPoint {
        let point = direction.point
        let animatePoint = CGPoint(x: point.x * 4, y: point.y * 4) //should be 2
        let retPoint = animatePoint.screenPointForSize(screenSize)
        return retPoint
    }
    
    private func animationRotationForDirection(_ direction: SwipeResultDirection) -> CGFloat {
        return CGFloat(direction.bearing / 2.0 - Double.pi / 4)
    }

    
    private func swipeAction(_ direction: SwipeResultDirection) {
        overlayView?.overlayState = direction
        overlayView?.alpha = 1.0
        delegate?.card(self, wasSwipedIn: direction)
        let translationAnimation = POPBasicAnimation(propertyNamed: kPOPLayerTranslationXY)
        translationAnimation?.duration = cardSwipeActionAnimationDuration
        translationAnimation?.fromValue = NSValue(cgPoint: POPLayerGetTranslationXY(layer))
        translationAnimation?.toValue = NSValue(cgPoint: animationPointForDirection(direction))
        translationAnimation?.completionBlock = { _, _ in
            self.removeFromSuperview()
        }
        layer.pop_add(translationAnimation, forKey: "swipeTranslationAnimation")
    }
    
    private func resetViewPositionAndTransformations() {
        delegate?.card(cardWasReset: self)
        
        removeAnimations()
        
        let resetPositionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerTranslationXY)
        resetPositionAnimation?.fromValue = NSValue(cgPoint:POPLayerGetTranslationXY(layer))
        resetPositionAnimation?.toValue = NSValue(cgPoint: CGPoint.zero)
        resetPositionAnimation?.springBounciness = cardResetAnimationSpringBounciness
        resetPositionAnimation?.springSpeed = cardResetAnimationSpringSpeed
        resetPositionAnimation?.completionBlock = {
            (_, _) in
            self.layer.transform = CATransform3DIdentity
            self.dragBegin = false
        }
        
        layer.pop_add(resetPositionAnimation, forKey: "resetPositionAnimation")
        
        let resetRotationAnimation = POPBasicAnimation(propertyNamed: kPOPLayerRotation)
        resetRotationAnimation?.fromValue = POPLayerGetRotationZ(layer)
        resetRotationAnimation?.toValue = CGFloat(0.0)
        resetRotationAnimation?.duration = cardResetAnimationDuration
        
        layer.pop_add(resetRotationAnimation, forKey: "resetRotationAnimation")
        
        let overlayAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        overlayAlphaAnimation?.toValue = 0.0
        overlayAlphaAnimation?.duration = cardResetAnimationDuration
        overlayAlphaAnimation?.completionBlock = { _, _ in
            self.overlayView?.alpha = 0
        }
        overlayView?.pop_add(overlayAlphaAnimation, forKey: "resetOverlayAnimation")
        
        let resetScaleAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        resetScaleAnimation?.toValue = NSValue(cgPoint: CGPoint(x: 1.0, y: 1.0))
        resetScaleAnimation?.duration = cardResetAnimationDuration
        layer.pop_add(resetScaleAnimation, forKey: "resetScaleAnimation")
    }
    
    //MARK: Public
    func removeAnimations() {
        pop_removeAllAnimations()
        layer.pop_removeAllAnimations()
    }
    
    func swipe(_ direction: SwipeResultDirection) {
        if !dragBegin {
            delegate?.card(self, wasSwipedIn: direction)
            
            let swipePositionAnimation = POPBasicAnimation(propertyNamed: kPOPLayerTranslationXY)
            swipePositionAnimation?.fromValue = NSValue(cgPoint:POPLayerGetTranslationXY(layer))
            swipePositionAnimation?.toValue = NSValue(cgPoint:animationPointForDirection(direction))
            swipePositionAnimation?.duration = cardSwipeActionAnimationDuration
            swipePositionAnimation?.completionBlock = {
                (_, _) in
                self.removeFromSuperview()
            }
            
            layer.pop_add(swipePositionAnimation, forKey: "swipePositionAnimation")
            
            let swipeRotationAnimation = POPBasicAnimation(propertyNamed: kPOPLayerRotation)
            swipeRotationAnimation?.fromValue = POPLayerGetRotationZ(layer)
            swipeRotationAnimation?.toValue = CGFloat(animationRotationForDirection(direction))
            swipeRotationAnimation?.duration = cardSwipeActionAnimationDuration
            
            layer.pop_add(swipeRotationAnimation, forKey: "swipeRotationAnimation")
            
            overlayView?.overlayState = direction
            let overlayAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
            overlayAlphaAnimation?.toValue = 1.0
            overlayAlphaAnimation?.duration = cardSwipeActionAnimationDuration
            overlayView?.pop_add(overlayAlphaAnimation, forKey: "swipeOverlayAnimation")
        }
    }
}
