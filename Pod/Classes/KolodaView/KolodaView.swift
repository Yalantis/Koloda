//
//  KolodaView.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/24/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit
import pop

public enum SwipeResultDirection {
    case None
    case Left
    case Right
}

//Default values
private let defaultCountOfVisibleCards = 3
private let backgroundCardsTopMargin: CGFloat = 4.0
private let backgroundCardsScalePercent: CGFloat = 0.95
private let backgroundCardsLeftMargin: CGFloat = 8.0
private let backgroundCardFrameAnimationDuration: NSTimeInterval = 0.2

//Opacity values
private let defaultAlphaValueOpaque: CGFloat = 1.0
private let defaultAlphaValueTransparent: CGFloat = 0.0
private let defaultAlphaValueSemiTransparent: CGFloat = 0.7

//Animations constants
private let revertCardAnimationName = "revertCardAlphaAnimation"
private let revertCardAnimationDuration: NSTimeInterval = 1.0
private let revertCardAnimationToValue: CGFloat = 1.0
private let revertCardAnimationFromValue: CGFloat = 0.0

private let kolodaAppearScaleAnimationName = "kolodaAppearScaleAnimation"
private let kolodaAppearScaleAnimationFromValue = CGPoint(x: 0.1, y: 0.1)
private let kolodaAppearScaleAnimationToValue = CGPoint(x: 1.0, y: 1.0)
private let kolodaAppearScaleAnimationDuration: NSTimeInterval = 0.8
private let kolodaAppearAlphaAnimationName = "kolodaAppearAlphaAnimation"
private let kolodaAppearAlphaAnimationFromValue: CGFloat = 0.0
private let kolodaAppearAlphaAnimationToValue: CGFloat = 1.0
private let kolodaAppearAlphaAnimationDuration: NSTimeInterval = 0.8


public protocol KolodaViewDataSource:class {
    
    func koloda(kolodaNumberOfCards koloda:KolodaView) -> UInt
    func koloda(koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView?
}

public extension KolodaViewDataSource {
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView? {
        return nil
    }
}

public protocol KolodaViewDelegate:class {
    
    func koloda(koloda: KolodaView, didSwipedCardAtIndex index: UInt, inDirection direction: SwipeResultDirection)
    func koloda(kolodaDidRunOutOfCards koloda: KolodaView)
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt)
    func koloda(kolodaShouldApplyAppearAnimation koloda: KolodaView) -> Bool
    func koloda(kolodaShouldMoveBackgroundCard koloda: KolodaView) -> Bool
    func koloda(kolodaShouldTransparentizeNextCard koloda: KolodaView) -> Bool
    func koloda(kolodaBackgroundCardAnimation koloda: KolodaView) -> POPPropertyAnimation?
    func koloda(koloda: KolodaView, draggedCardWithFinishPercent finishPercent: CGFloat, inDirection direction: SwipeResultDirection)
    func koloda(kolodaDidResetCard koloda: KolodaView)
    func koloda(kolodaSwipeThresholdMargin koloda: KolodaView) -> CGFloat?
}

public extension KolodaViewDelegate {
    
    func koloda(koloda: KolodaView, didSwipedCardAtIndex index: UInt, inDirection direction: SwipeResultDirection) {}
    func koloda(kolodaDidRunOutOfCards koloda: KolodaView) {}
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt) {}
    func koloda(kolodaShouldApplyAppearAnimation koloda: KolodaView) -> Bool {return true}
    func koloda(kolodaShouldMoveBackgroundCard koloda: KolodaView) -> Bool {return true}
    func koloda(kolodaShouldTransparentizeNextCard koloda: KolodaView) -> Bool {return true}
    func koloda(kolodaBackgroundCardAnimation koloda: KolodaView) -> POPPropertyAnimation? {return nil}
    func koloda(koloda: KolodaView, draggedCardWithFinishPercent finishPercent: CGFloat, inDirection direction: SwipeResultDirection) {}
    func koloda(kolodaDidResetCard koloda: KolodaView) {}
    func koloda(kolodaSwipeThresholdMargin koloda: KolodaView) -> CGFloat? {return nil}
}

public class KolodaView: UIView, DraggableCardDelegate {
    
    public weak var dataSource: KolodaViewDataSource? {
        didSet {
            setupDeck()
        }
    }
    public weak var delegate: KolodaViewDelegate?
    
    private(set) public var currentCardNumber = 0
    private(set) public var countOfCards = 0
    
    public var countOfVisibleCards = defaultCountOfVisibleCards
    private var visibleCards = [DraggableCardView]()
    private var animating = false
    private var configured = false
    
    public var alphaValueOpaque: CGFloat = defaultAlphaValueOpaque
    public var alphaValueTransparent: CGFloat = defaultAlphaValueTransparent
    public var alphaValueSemiTransparent: CGFloat = defaultAlphaValueSemiTransparent
    
    //MARK: Lifecycle
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    deinit {
        unsubsribeFromNotifications()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !self.configured {
            
            if self.visibleCards.isEmpty {
                reloadData()
            } else {
                layoutDeck()
            }
            
            self.configured = true
        }
    }
    
    //MARK: Configurations
    
    private func subscribeForNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "layoutDeck", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    private func unsubsribeFromNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func configure() {
        subscribeForNotifications()
    }
    
    private func setupDeck() {
        if let dataSource = dataSource {
            countOfCards = Int(dataSource.koloda(kolodaNumberOfCards: self))
            
            if countOfCards - currentCardNumber > 0 {
                
                let countOfNeededCards = min(countOfVisibleCards, countOfCards - currentCardNumber)
                
                for index in 0..<countOfNeededCards {
                    let nextCardContentView = dataSource.koloda(self, viewForCardAtIndex: UInt(index+currentCardNumber))
                    let nextCardView = DraggableCardView(frame: frameForCardAtIndex(UInt(index)))
                    
                    nextCardView.delegate = self
                    nextCardView.alpha = index == 0 ? alphaValueOpaque : alphaValueSemiTransparent
                    nextCardView.userInteractionEnabled = index == 0
                    
                    let overlayView = overlayViewForCardAtIndex(UInt(index+currentCardNumber))
                    
                    nextCardView.configure(nextCardContentView, overlayView: overlayView)
                    visibleCards.append(nextCardView)
                    index == 0 ? addSubview(nextCardView) : insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
                }
            }
        }
    }
    
    public func layoutDeck() {
        for (index, card) in self.visibleCards.enumerate() {
            card.frame = frameForCardAtIndex(UInt(index))
        }
    }
    
    //MARK: Frames
    public func frameForCardAtIndex(index: UInt) -> CGRect {
        let bottomOffset:CGFloat = 0
        let topOffset = backgroundCardsTopMargin * CGFloat(self.countOfVisibleCards - 1)
        let scalePercent = backgroundCardsScalePercent
        let width = CGRectGetWidth(self.frame) * pow(scalePercent, CGFloat(index))
        let xOffset = (CGRectGetWidth(self.frame) - width) / 2
        let height = (CGRectGetHeight(self.frame) - bottomOffset - topOffset) * pow(scalePercent, CGFloat(index))
        let multiplier: CGFloat = index > 0 ? 1.0 : 0.0
        let previousCardFrame = index > 0 ? frameForCardAtIndex(max(index - 1, 0)) : CGRectZero
        let yOffset = (CGRectGetHeight(previousCardFrame) - height + previousCardFrame.origin.y + backgroundCardsTopMargin) * multiplier
        let frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        
        return frame
    }
    
    private func moveOtherCardsWithFinishPercent(percent: CGFloat) {
        if visibleCards.count > 1 {
            
            for index in 1..<visibleCards.count {
                let previousCardFrame = frameForCardAtIndex(UInt(index - 1))
                var frame = frameForCardAtIndex(UInt(index))
                let distanceToMoveY: CGFloat = (frame.origin.y - previousCardFrame.origin.y) * (percent / 100)
                
                frame.origin.y -= distanceToMoveY
                
                let distanceToMoveX: CGFloat = (previousCardFrame.origin.x - frame.origin.x) * (percent / 100)
                
                frame.origin.x += distanceToMoveX
                
                let widthScale = (previousCardFrame.size.width - frame.size.width) * (percent / 100)
                let heightScale = (previousCardFrame.size.height - frame.size.height) * (percent / 100)
                
                frame.size.width += widthScale
                frame.size.height += heightScale
                
                let card = visibleCards[index]
                
                card.pop_removeAllAnimations()
                card.frame = frame
                card.layoutIfNeeded()
                
                //For fully visible next card, when moving top card
                if let shouldTransparentize = delegate?.koloda(kolodaShouldTransparentizeNextCard: self) where shouldTransparentize == true {
                    if index == 1 {
                        card.alpha = alphaValueSemiTransparent + (alphaValueOpaque - alphaValueSemiTransparent) * percent/100
                    }
                }
            }
        }
    }
    
    //MARK: Animations
    
    public func applyAppearAnimation() {
        userInteractionEnabled = false
        animating = true
        
        let kolodaAppearScaleAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        
        kolodaAppearScaleAnimation.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearScaleAnimation.duration = kolodaAppearScaleAnimationDuration
        kolodaAppearScaleAnimation.fromValue = NSValue(CGPoint: kolodaAppearScaleAnimationFromValue)
        kolodaAppearScaleAnimation.toValue = NSValue(CGPoint: kolodaAppearScaleAnimationToValue)
        kolodaAppearScaleAnimation.completionBlock = {
            (_, _) in
            
            self.userInteractionEnabled = true
            self.animating = false
        }
        
        let kolodaAppearAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        
        kolodaAppearAlphaAnimation.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearAlphaAnimation.fromValue = NSNumber(float: Float(kolodaAppearAlphaAnimationFromValue))
        kolodaAppearAlphaAnimation.toValue = NSNumber(float: Float(kolodaAppearAlphaAnimationToValue))
        kolodaAppearAlphaAnimation.duration = kolodaAppearAlphaAnimationDuration
        
        pop_addAnimation(kolodaAppearAlphaAnimation, forKey: kolodaAppearAlphaAnimationName)
        layer.pop_addAnimation(kolodaAppearScaleAnimation, forKey: kolodaAppearScaleAnimationName)
    }
    
    func applyRevertAnimation(card: DraggableCardView) {
        animating = true
        
        let firstCardAppearAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        
        firstCardAppearAnimation.toValue = NSNumber(float: Float(revertCardAnimationToValue))
        firstCardAppearAnimation.fromValue =  NSNumber(float: Float(revertCardAnimationFromValue))
        firstCardAppearAnimation.duration = revertCardAnimationDuration
        firstCardAppearAnimation.completionBlock = {
            (_, _) in
            
            self.animating = false
        }
        
        card.pop_addAnimation(firstCardAppearAnimation, forKey: revertCardAnimationName)
    }
    
    //MARK: DraggableCardDelegate
    
    func card(card: DraggableCardView, wasDraggedWithFinishPercent percent: CGFloat, inDirection direction: SwipeResultDirection) {
        animating = true
        
        if let shouldMove = delegate?.koloda(kolodaShouldMoveBackgroundCard: self) where shouldMove == true {
            self.moveOtherCardsWithFinishPercent(percent)
        }
        delegate?.koloda(self, draggedCardWithFinishPercent: percent, inDirection: direction)
    }
    
    func card(card: DraggableCardView, wasSwipedInDirection direction: SwipeResultDirection) {
        swipedAction(direction)
    }
    
    func card(cardWasReset card: DraggableCardView) {
        if visibleCards.count > 1 {
            
            UIView.animateWithDuration(backgroundCardFrameAnimationDuration,
                delay: 0.0,
                options: .CurveLinear,
                animations: {
                    self.moveOtherCardsWithFinishPercent(0)
                },
                completion: {
                    _ in
                    self.animating = false
                    
                    for index in 1..<self.visibleCards.count {
                        let card = self.visibleCards[index]
                        card.alpha = self.alphaValueSemiTransparent
                    }
            })
        } else {
            animating = false
        }
        
        delegate?.koloda(kolodaDidResetCard: self)
    }
    
    func card(cardWasTapped card: DraggableCardView) {
        let index = currentCardNumber + visibleCards.indexOf(card)!
        
        delegate?.koloda(self, didSelectCardAtIndex: UInt(index))
    }
    
    func card(cardSwipeThresholdMargin card: DraggableCardView) -> CGFloat? {
        return delegate?.koloda(kolodaSwipeThresholdMargin: self)
    }
    
    //MARK: Private
    private func clear() {
        currentCardNumber = 0
        
        for card in visibleCards {
            card.removeFromSuperview()
        }
        
        visibleCards.removeAll(keepCapacity: true)
        
    }
    
    private func overlayViewForCardAtIndex(index: UInt) -> OverlayView? {
        return dataSource?.koloda(self, viewForCardOverlayAtIndex: index)
    }
    
    //MARK: Actions
    
    private func swipedAction(direction: SwipeResultDirection) {
        animating = true
        visibleCards.removeAtIndex(0)
        
        currentCardNumber++
        let shownCardsCount = currentCardNumber + countOfVisibleCards
        if shownCardsCount - 1 < countOfCards {
            
            if let dataSource = dataSource {
                
                let lastCardContentView = dataSource.koloda(self, viewForCardAtIndex: UInt(shownCardsCount - 1))
                let lastCardOverlayView = dataSource.koloda(self, viewForCardOverlayAtIndex: UInt(shownCardsCount - 1))
                let lastCardFrame = frameForCardAtIndex(UInt(currentCardNumber + visibleCards.count))
                let lastCardView = DraggableCardView(frame: lastCardFrame)
                
                lastCardView.hidden = true
                lastCardView.userInteractionEnabled = true
                
                lastCardView.configure(lastCardContentView, overlayView: lastCardOverlayView)
                
                lastCardView.delegate = self
                
                if let lastCard = visibleCards.last {
                    insertSubview(lastCardView, belowSubview:lastCard)
                } else {
                    addSubview(lastCardView)
                }
                visibleCards.append(lastCardView)
            }
        }
        
        if !visibleCards.isEmpty {
            
            for (index, currentCard) in visibleCards.enumerate() {
                var frameAnimation: POPPropertyAnimation
                if let delegateAnimation = delegate?.koloda(kolodaBackgroundCardAnimation: self) where delegateAnimation.property.name == kPOPViewFrame {
                    frameAnimation = delegateAnimation
                } else {
                    frameAnimation = POPBasicAnimation(propertyNamed: kPOPViewFrame)
                    (frameAnimation as! POPBasicAnimation).duration = backgroundCardFrameAnimationDuration
                }
                
                let shouldTransparentize = delegate?.koloda(kolodaShouldTransparentizeNextCard: self)
                let cardFrame = frameForCardAtIndex(UInt(index))
                
                if index != 0 {
                    currentCard.alpha = alphaValueSemiTransparent
                } else {
                    frameAnimation.completionBlock = {(animation, finished) in
                        self.visibleCards.last?.hidden = false
                        self.animating = false
                        currentCard.frame = cardFrame
                        self.delegate?.koloda(self, didSwipedCardAtIndex: UInt(self.currentCardNumber - 1), inDirection: direction)
                        if (shouldTransparentize == false) {
                            currentCard.alpha = self.alphaValueOpaque
                        }
                        print(finished)
                    }
                    if (shouldTransparentize == true) {
                        currentCard.alpha = alphaValueOpaque
                    } else {
                        let alphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
                        alphaAnimation.toValue = alphaValueOpaque
                        alphaAnimation.duration = backgroundCardFrameAnimationDuration
                        currentCard.pop_addAnimation(alphaAnimation, forKey: "alpha")
                    }
                }
                
                currentCard.userInteractionEnabled = index == 0
                frameAnimation.toValue = NSValue(CGRect: cardFrame)
                currentCard.removeAnimations()
                currentCard.pop_addAnimation(frameAnimation, forKey: "frameAnimation")
            }
        } else {
            delegate?.koloda(self, didSwipedCardAtIndex: UInt(currentCardNumber - 1), inDirection: direction)
            animating = false
            delegate?.koloda(kolodaDidRunOutOfCards: self)
        }
        
    }
    
    public func revertAction() {
        if currentCardNumber > 0 && animating == false {
            
            if countOfCards - currentCardNumber >= countOfVisibleCards {
                
                if let lastCard = visibleCards.last {
                    
                    lastCard.removeFromSuperview()
                    visibleCards.removeLast()
                }
            }
            
            currentCardNumber--
            
            
            if let dataSource = self.dataSource {
                let firstCardContentView = dataSource.koloda(self, viewForCardAtIndex: UInt(currentCardNumber))
                let firstCardOverlayView = dataSource.koloda(self, viewForCardOverlayAtIndex: UInt(currentCardNumber))
                let firstCardView = DraggableCardView()
                
                firstCardView.alpha = alphaValueTransparent
                
                firstCardView.configure(firstCardContentView, overlayView: firstCardOverlayView)
                firstCardView.delegate = self
                
                addSubview(firstCardView)
                visibleCards.insert(firstCardView, atIndex: 0)
                
                firstCardView.frame = frameForCardAtIndex(0)
                
                applyRevertAnimation(firstCardView)
            }
            
            for index in 1..<visibleCards.count {
                let currentCard = visibleCards[index]
                let frameAnimation = POPBasicAnimation(propertyNamed: kPOPViewFrame)
                
                frameAnimation.duration = backgroundCardFrameAnimationDuration
                currentCard.alpha = alphaValueSemiTransparent
                frameAnimation.toValue = NSValue(CGRect: frameForCardAtIndex(UInt(index)))
                currentCard.userInteractionEnabled = false
                
                currentCard.pop_addAnimation(frameAnimation, forKey: "frameAnimation")
            }
        }
    }
    
    private func loadMissingCards(missingCardsCount: Int) {
        if missingCardsCount > 0 {
            
            let cardsToAdd = min(missingCardsCount, countOfCards - currentCardNumber)
            
            for index in 1...cardsToAdd {
                let nextCardView = DraggableCardView(frame: frameForCardAtIndex(UInt(index)))
                
                nextCardView.alpha = alphaValueSemiTransparent
                nextCardView.delegate = self
                
                visibleCards.append(nextCardView)
                insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
            }
        }
        
        reconfigureCards()
    }
    
    private func reconfigureCards() {
        for index in 0..<visibleCards.count {
            if let dataSource = self.dataSource {
                
                let currentCardContentView = dataSource.koloda(self, viewForCardAtIndex: UInt(currentCardNumber + index))
                let overlayView = dataSource.koloda(self, viewForCardOverlayAtIndex: UInt(currentCardNumber + index))
                let currentCard = visibleCards[index]
                
                currentCard.configure(currentCardContentView, overlayView: overlayView)
            }
        }
    }
    
    public func reloadData() {
        guard let numberOfCards = dataSource?.koloda(kolodaNumberOfCards: self) where numberOfCards > 0 else {
            return
        }
        let countOfCards = Int(numberOfCards)
        
        let missingCards = min(countOfVisibleCards - visibleCards.count, countOfCards - (currentCardNumber + 1))
        
        
        if currentCardNumber == 0 {
            clear()
        }
        
        if countOfCards - (currentCardNumber + visibleCards.count) > 0 {
            
            if !visibleCards.isEmpty {
                loadMissingCards(missingCards)
            } else {
                setupDeck()
                layoutDeck()
                
                if let shouldApply = delegate?.koloda(kolodaShouldApplyAppearAnimation: self) where shouldApply == true {
                    self.alpha = 0
                    applyAppearAnimation()
                }
            }
            
        } else {
            
            reconfigureCards()
        }
    }
    
    public func swipe(direction: SwipeResultDirection) {
        if (animating == false) {
            
            if let frontCard = visibleCards.first {
                
                animating = true
                
                if visibleCards.count > 1 {
                    if let shouldTransparentize = delegate?.koloda(kolodaShouldTransparentizeNextCard: self) where shouldTransparentize == true {
                        let nextCard = visibleCards[1]
                        nextCard.alpha = alphaValueOpaque
                    }
                }
                frontCard.swipe(direction)
            }
        }
    }
    
    public func resetCurrentCardNumber() {
        clear()
        reloadData()
    }
    
    public func viewForCardAtIndex(index: Int) -> UIView? {
        if visibleCards.count + currentCardNumber > index && index >= currentCardNumber {
            return visibleCards[index - currentCardNumber].contentView
        } else {
            return nil
        }
    }
}
