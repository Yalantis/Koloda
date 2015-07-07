//
//  KolodaView.swift
//  TinderCardsSwift
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
private let alphaValueOpaque: CGFloat = 1.0
private let alphaValueTransparent: CGFloat = 0.0
private let alphaValueSemiTransparent: CGFloat = 0.7

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
    
    func kolodaNumberOfCards(koloda: KolodaView) -> UInt
    func kolodaViewForCardAtIndex(koloda: KolodaView, index: UInt) -> UIView
    func kolodaViewForCardOverlayAtIndex(koloda: KolodaView, index: UInt) -> OverlayView?
    
}

public protocol KolodaViewDelegate:class {
    
    func kolodaDidSwipedCardAtIndex(koloda: KolodaView,index: UInt, direction: SwipeResultDirection)
    func kolodaDidRunOutOfCards(koloda: KolodaView)
    func kolodaDidSelectCardAtIndex(koloda: KolodaView, index: UInt)
    func kolodaShouldApplyAppearAnimation(koloda: KolodaView) -> Bool
    
}

public class KolodaView: UIView, DraggableCardDelegate {
    
    public weak var dataSource: KolodaViewDataSource! {
        didSet {
            setupDeck()
        }
    }
    public weak var delegate: KolodaViewDelegate?
    
    private(set) public var currentCardNumber = 0
    private(set) public var countOfCards = 0
    
    var countOfVisibleCards = defaultCountOfVisibleCards
    private var visibleCards = [DraggableCardView]()
    private var animating = false
    private var configured = false
    
    //MARK: Lifecycle
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
    
    private func setupDeck() {
        countOfCards = Int(dataSource!.kolodaNumberOfCards(self))
        
        if countOfCards - currentCardNumber > 0 {
            
            let countOfNeededCards = min(countOfVisibleCards, countOfCards - currentCardNumber)
            
            for index in 0..<countOfNeededCards {
                if let nextCardContentView = dataSource?.kolodaViewForCardAtIndex(self, index: UInt(index)) {
                    let nextCardView = DraggableCardView(frame: frameForCardAtIndex(UInt(index)))
                    
                    nextCardView.delegate = self
                    nextCardView.alpha = index == 0 ? alphaValueOpaque : alphaValueSemiTransparent
                    nextCardView.userInteractionEnabled = index == 0
                    
                    let overlayView = overlayViewForCardAtIndex(UInt(index))
                    
                    nextCardView.configure(nextCardContentView, overlayView: overlayView!)
                    visibleCards.append(nextCardView)
                    index == 0 ? addSubview(nextCardView) : insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
                }
            }
        }
    }
    
    private func layoutDeck() {
        for (index, card) in enumerate(self.visibleCards) {
            card.frame = frameForCardAtIndex(UInt(index))
        }
    }
    
    //MARK: Frames
    private func frameForCardAtIndex(index: UInt) -> CGRect {
        let bottomOffset:CGFloat = 0
        let topOffset = backgroundCardsTopMargin * CGFloat(self.countOfVisibleCards - 1)
        let xOffset = backgroundCardsLeftMargin * CGFloat(index)
        let scalePercent = backgroundCardsScalePercent
        let width = CGRectGetWidth(self.frame) * pow(scalePercent, CGFloat(index))
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
                
                card.frame = frame
                card.layoutIfNeeded()
                
                //For fully visible next card, when moving top card
                if index == 1 {
                    card.alpha = alphaValueOpaque
                }
            }
        }
    }
    
    //MARK: Animations
    
    public func applyAppearAnimation() {
        userInteractionEnabled = false
        animating = true
        
        let kolodaAppearScaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
        
        kolodaAppearScaleAnimation.duration = kolodaAppearScaleAnimationDuration
        kolodaAppearScaleAnimation.fromValue = NSValue(CGPoint: kolodaAppearScaleAnimationFromValue)
        kolodaAppearScaleAnimation.toValue = NSValue(CGPoint: kolodaAppearScaleAnimationToValue)
        kolodaAppearScaleAnimation.completionBlock = {
            (_, _) in
            
            self.userInteractionEnabled = true
            self.animating = false
        }
        
        let kolodaAppearAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        
        kolodaAppearAlphaAnimation.fromValue = NSNumber(float: Float(kolodaAppearAlphaAnimationFromValue))
        kolodaAppearAlphaAnimation.toValue = NSNumber(float: Float(kolodaAppearAlphaAnimationToValue))
        kolodaAppearAlphaAnimation.duration = kolodaAppearAlphaAnimationDuration
        
        pop_addAnimation(kolodaAppearAlphaAnimation, forKey: kolodaAppearAlphaAnimationName)
        pop_addAnimation(kolodaAppearScaleAnimation, forKey: kolodaAppearScaleAnimationName)
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
    
    func cardDraggedWithFinishPercent(card: DraggableCardView, percent: CGFloat) {
        animating = true
        
        moveOtherCardsWithFinishPercent(percent)
    }
    
    func cardSwippedInDirection(card: DraggableCardView, direction: SwipeResultDirection) {
        swipedAction(direction)
    }
    
    func cardWasReset(card: DraggableCardView) {
        if visibleCards.count > 1 {
            
            UIView.animateWithDuration(0.2,
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
                        card.alpha = alphaValueSemiTransparent
                    }
            })
        } else {
            animating = false
        }
        
    }
    
    func cardTapped(card: DraggableCardView) {
        let index = currentCardNumber + find(visibleCards, card)!
        
        delegate?.kolodaDidSelectCardAtIndex(self, index: UInt(index))
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
        return dataSource.kolodaViewForCardOverlayAtIndex(self, index: index)
    }
    
    //MARK: Actions
    
    private func swipedAction(direction: SwipeResultDirection) {
        animating = true
        visibleCards.removeAtIndex(0)

        currentCardNumber++
        let shownCardsCount = currentCardNumber + countOfVisibleCards
        if shownCardsCount - 1 < countOfCards {
            
            if let dataSource = self.dataSource {
                
                let lastCardContentView = dataSource.kolodaViewForCardAtIndex(self, index: UInt(shownCardsCount - 1))
                let lastCardOverlayView = dataSource.kolodaViewForCardOverlayAtIndex(self, index: UInt(shownCardsCount - 1))
                let lastCardView = DraggableCardView()
                
                lastCardView.hidden = true
                lastCardView.userInteractionEnabled = true
                
                lastCardView.configure(lastCardContentView, overlayView: lastCardOverlayView)
                
                lastCardView.delegate = self
                
                insertSubview(lastCardView, belowSubview: visibleCards.last!)
                visibleCards.append(lastCardView)
            }
        }
        
        if !visibleCards.isEmpty {
            
            for (index, currentCard) in enumerate(visibleCards) {
                let frameAnimation = POPBasicAnimation(propertyNamed: kPOPViewFrame)
                frameAnimation.duration = backgroundCardFrameAnimationDuration
                
                if index != 0 {
                    currentCard.alpha = alphaValueSemiTransparent
                } else {
                    frameAnimation.completionBlock = {(_, _) in
                        self.visibleCards.last?.hidden = false
                        self.animating = false
                        self.delegate?.kolodaDidSwipedCardAtIndex(self, index: UInt(self.currentCardNumber - 1), direction: direction)
                    }
                    currentCard.alpha = alphaValueOpaque
                }
                
                currentCard.userInteractionEnabled = index == 0
                frameAnimation.toValue = NSValue(CGRect: frameForCardAtIndex(UInt(index)))
                
                currentCard.pop_addAnimation(frameAnimation, forKey: "frameAnimation")
            }
        } else {
            delegate?.kolodaDidSwipedCardAtIndex(self, index: UInt(currentCardNumber - 1), direction: direction)
            animating = false
            self.delegate?.kolodaDidRunOutOfCards(self)
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
                let firstCardContentView = dataSource.kolodaViewForCardAtIndex(self, index: UInt(currentCardNumber))
                let firstCardOverlayView = dataSource.kolodaViewForCardOverlayAtIndex(self, index: UInt(currentCardNumber))
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
                let nextCardIndex = countOfVisibleCards - cardsToAdd + index - 1
                let nextCardView = DraggableCardView(frame: frameForCardAtIndex(UInt(index)))
                
                nextCardView.alpha = alphaValueSemiTransparent
                nextCardView.delegate = self
                
                visibleCards.append(nextCardView)
                insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
            }
        }
        
        for index in 0..<visibleCards.count {
            if let dataSource = self.dataSource {
                
                let currentCardContentView = dataSource.kolodaViewForCardAtIndex(self, index: UInt(currentCardNumber + index))
                let overlayView = dataSource.kolodaViewForCardOverlayAtIndex(self, index: UInt(currentCardNumber + index))
                let currentCard = visibleCards[index]
                
                currentCard.configure(currentCardContentView, overlayView: overlayView)
            }
        }
    }
    
    public func reloadData() {
        countOfCards = Int(dataSource!.kolodaNumberOfCards(self))
        let missingCards = min(countOfVisibleCards - visibleCards.count, countOfCards - (currentCardNumber + 1))
        
        if countOfCards == 0 {
            return
        }
        
        if currentCardNumber == 0 {
            clear()
        }
        
        if countOfCards - (currentCardNumber + visibleCards.count) > 0 {
            
            if !visibleCards.isEmpty {
                loadMissingCards(missingCards)
            } else {
                setupDeck()
                layoutDeck()
                
                if let shouldApply = delegate?.kolodaShouldApplyAppearAnimation(self) where shouldApply == true {
                    applyAppearAnimation()
                }
            }
            
        } else {
            
            for index in 0..<visibleCards.count {
                if let dataSource = self.dataSource {
                    
                    let currentCardContentView = dataSource.kolodaViewForCardAtIndex(self, index: UInt(currentCardNumber + index))
                    let overlayView = dataSource.kolodaViewForCardOverlayAtIndex(self, index: UInt(currentCardNumber + index))
                    let currentCardView = visibleCards[index]
                    
                    currentCardView.configure(currentCardContentView, overlayView: overlayView)
                }
            }
        }
    }
    
    public func swipe(direction: SwipeResultDirection) {
        if (animating == false) {
            
            if let frontCard = visibleCards.first {
                
                animating = true
                
                switch direction {
                case SwipeResultDirection.None:
                    return
                case SwipeResultDirection.Left:
                    frontCard.swipeLeft()
                case SwipeResultDirection.Right:
                    frontCard.swipeRight()
                }
                
                if visibleCards.count > 1 {
                    let nextCard = visibleCards[1]
                    nextCard.alpha = alphaValueOpaque
                }
            }
        }
    }
    
    public func resetCurrentCardNumber() {
        clear()
        reloadData()
    }
    
}
