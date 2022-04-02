//
//  DraggableCardView.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/23/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//

import UIKit

public enum DragSpeed: TimeInterval {
    case slow = 2.0
    case moderate = 1.5
    case `default` = 0.8
    case fast = 0.4
}

protocol DraggableCardDelegate: AnyObject {
    
    func card(_ card: DraggableCardView, wasDraggedWithFinishPercentage percentage: CGFloat, inDirection direction: SwipeResultDirection)
    func card(_ card: DraggableCardView, wasSwipedIn direction: SwipeResultDirection)
    func card(_ card: DraggableCardView, shouldSwipeIn direction: SwipeResultDirection) -> Bool
    func card(cardWasReset card: DraggableCardView)
    func card(cardWasTapped card: DraggableCardView)
    func card(cardSwipeThresholdRatioMargin card: DraggableCardView) -> CGFloat?
    func card(cardAllowedDirections card: DraggableCardView) -> [SwipeResultDirection]
    func card(cardShouldDrag card: DraggableCardView) -> Bool
    func card(cardSwipeSpeed card: DraggableCardView) -> DragSpeed
    func card(cardPanBegan card: DraggableCardView)
    func card(cardPanFinished card: DraggableCardView)
}

//Drag animation constants
private let defaultRotationMax: CGFloat = 1.0
private let defaultRotationAngle = CGFloat(Double.pi) / 10.0
private let defaultScaleMin: CGFloat = 0.8

private let screenSize = UIScreen.main.bounds.size

//Reset animation constants
private let cardResetAnimationSpringBounciness: CGFloat = 10.0
private let cardResetAnimationSpringSpeed: CGFloat = 20.0
private let cardResetAnimationKey = "resetPositionAnimation"
private let cardResetAnimationDuration: TimeInterval = 0.2
internal var cardSwipeActionAnimationDuration: TimeInterval = DragSpeed.default.rawValue

public class DraggableCardView: UIView, UIGestureRecognizerDelegate {

    //Drag animation constants
    public var rotationMax = defaultRotationMax
    public var rotationAngle = defaultRotationAngle
    public var scaleMin = defaultScaleMin
    
    weak var delegate: DraggableCardDelegate? {
        didSet {
            configureSwipeSpeed()
        }
    }

    internal var dragBegin = false
    
    private var overlayView: OverlayView?
    public private(set) var contentView: UIView?
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var animationDirectionY: CGFloat = 1.0
    private var dragDistance = CGPoint.zero
    
    private var swipePercentageMargin: CGFloat {
        let percentage = delegate?.card(cardSwipeThresholdRatioMargin: self) ?? 0.0
        
        return percentage != 0.0 ? percentage : 1.0
    }

    
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
    
    deinit {
        removeGestureRecognizer(panGestureRecognizer)
        removeGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setup() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DraggableCardView.panGestureRecognized(_:)))
        addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DraggableCardView.tapRecognized(_:)))
        tapGestureRecognizer.delegate = self
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
                attribute: .width,
                relatedBy: .equal,
                toItem: self,
                attribute: .width,
                multiplier: 1.0,
                constant: 0)
            let height = NSLayoutConstraint(
                item: overlay,
                attribute: .height,
                relatedBy: .equal,
                toItem: self,
                attribute: .height,
                multiplier: 1.0,
                constant: 0)
            let top = NSLayoutConstraint (
                item: overlay,
                attribute: .top,
                relatedBy: .equal,
                toItem: self,
                attribute: .top,
                multiplier: 1.0,
                constant: 0)
            let leading = NSLayoutConstraint (
                item: overlay,
                attribute: .leading,
                relatedBy: .equal,
                toItem: self,
                attribute: .leading,
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
                attribute: .width,
                relatedBy: .equal,
                toItem: self,
                attribute: .width,
                multiplier: 1.0,
                constant: 0)
            let height = NSLayoutConstraint(
                item: contentView,
                attribute: .height,
                relatedBy: .equal,
                toItem: self,
                attribute: .height,
                multiplier: 1.0,
                constant: 0)
            let top = NSLayoutConstraint (
                item: contentView,
                attribute: .top,
                relatedBy: .equal,
                toItem: self,
                attribute: .top,
                multiplier: 1.0,
                constant: 0)
            let leading = NSLayoutConstraint (
                item: contentView,
                attribute: .leading,
                relatedBy: .equal,
                toItem: self,
                attribute: .leading,
                multiplier: 1.0,
                constant: 0)
            
            addConstraints([width,height,top,leading])
        }
    }
    
    func configureSwipeSpeed() {
        if let delegate = delegate {
            cardSwipeActionAnimationDuration = delegate.card(cardSwipeSpeed: self).rawValue
        }
    }
    
    //MARK: GestureRecognizers
    @objc func panGestureRecognized(_ gestureRecognizer: UIPanGestureRecognizer) {
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
            delegate?.card(cardPanBegan: self)
            
        case .changed:
            let rotationStrength = min(dragDistance.x / frame.width, rotationMax)
            let rotationAngle = animationDirectionY * self.rotationAngle * rotationStrength
            let scaleStrength = 1 - ((1 - scaleMin) * abs(rotationStrength))
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
                delegate?.card(self, wasDraggedWithFinishPercentage: min(abs(100 * percentage), 100), inDirection: dragDirection)
            }
            
        case .ended:
            swipeMadeAction()
            delegate?.card(cardPanFinished: self)
            layer.shouldRasterize = false
            
        default:
            layer.shouldRasterize = false
            resetViewPositionAndTransformations()
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer == tapGestureRecognizer, touch.view is UIControl else {
            return true
        }
        return false
    }
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else {
            return true
        }
        return delegate?.card(cardShouldDrag: self) ?? true
    }
    
    @objc func tapRecognized(_ recogznier: UITapGestureRecognizer) {
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
                .compactMap { CGPoint.intersectionBetweenLines(targetLine, line2: $0) }
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
    
    func animationPointForDirection(_ direction: SwipeResultDirection) -> CGPoint {
        guard let superview = self.superview else {
            return .zero
        }
        
        let superSize = superview.bounds.size
        let space = max(screenSize.width, screenSize.height)
        switch direction {
        case .left, .right:
            // Optimize left and right position
            let x = direction.point.x * (superSize.width + space)
            let y = 0.5 * superSize.height
            return CGPoint(x: x, y: y)
            
        default:
            let x = direction.point.x * (superSize.width + space)
            let y = direction.point.y * (superSize.height + space)
            return CGPoint(x: x, y: y)
        }
    }
    
    func animationRotationForDirection(_ direction: SwipeResultDirection) -> CGFloat {
        return CGFloat(direction.bearing / 2.0 - Double.pi / 4)
    }
    
    private func swipeAction(_ direction: SwipeResultDirection) {
        overlayView?.overlayState = direction
        overlayView?.alpha = 1.0
        delegate?.card(self, wasSwipedIn: direction)

        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: cardSwipeActionAnimationDuration, delay: 0, options: []) {
            let point = self.animationPointForDirection(direction)
            self.transform = CGAffineTransform(translationX: point.x, y: point.y)
        } completion: { position in
            self.removeFromSuperview()
        }
    }
    
    private func resetViewPositionAndTransformations() {
        delegate?.card(cardWasReset: self)
        
        removeAnimations()

        UIView.animate(withDuration: cardResetAnimationDuration, delay: 0, usingSpringWithDamping: (20 - cardResetAnimationSpringBounciness) / 20, initialSpringVelocity: cardResetAnimationSpringSpeed * 2, options: []) {
            self.transform = .identity
        } completion: { _ in
            self.layer.transform = CATransform3DIdentity
            self.dragBegin = false
        }

        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: cardResetAnimationDuration, delay: 0, options: []) {
            self.overlayView?.alpha = 0
        } completion: { position in
            self.overlayView?.alpha = 0
        }
    }
    
    //MARK: Public
    func removeAnimations() {
        layer.removeAllAnimations()
    }
    
    func swipe(_ direction: SwipeResultDirection, completionHandler: @escaping () -> Void) {
        if !dragBegin {
            delegate?.card(self, wasSwipedIn: direction)

            overlayView?.overlayState = direction

            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: cardSwipeActionAnimationDuration, delay: 0, options: []) {
                let point = self.animationPointForDirection(direction)
                self.transform = CGAffineTransform(translationX: point.x, y: point.y)
                    .rotated(by: self.animationRotationForDirection(direction))
                self.overlayView?.alpha = 1
            } completion: { position in
                self.removeFromSuperview()
                completionHandler()
            }
        }
    }
}
