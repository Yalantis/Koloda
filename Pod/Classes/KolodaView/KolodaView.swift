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

public protocol KolodaViewDataSource:class {
    
    func koloda(kolodaNumberOfCards koloda: KolodaView) -> UInt
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
    func koloda(koloda: KolodaView, draggedCardWithFinishPercent finishPercent: CGFloat, inDirection direction: SwipeResultDirection)
    func koloda(kolodaDidResetCard koloda: KolodaView)
    func koloda(kolodaSwipeThresholdMargin koloda: KolodaView) -> CGFloat?
    func koloda(koloda: KolodaView, didShowCardAtIndex index: UInt)
}

public extension KolodaViewDelegate {
    
    func koloda(koloda: KolodaView, didSwipedCardAtIndex index: UInt, inDirection direction: SwipeResultDirection) {}
    func koloda(kolodaDidRunOutOfCards koloda: KolodaView) {}
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt) {}
    func koloda(kolodaShouldApplyAppearAnimation koloda: KolodaView) -> Bool {return true}
    func koloda(kolodaShouldMoveBackgroundCard koloda: KolodaView) -> Bool {return true}
    func koloda(kolodaShouldTransparentizeNextCard koloda: KolodaView) -> Bool {return true}
    func koloda(koloda: KolodaView, draggedCardWithFinishPercent finishPercent: CGFloat, inDirection direction: SwipeResultDirection) {}
    func koloda(kolodaDidResetCard koloda: KolodaView) {}
    func koloda(kolodaSwipeThresholdMargin koloda: KolodaView) -> CGFloat? {return nil}
    func koloda(koloda: KolodaView, didShowCardAtIndex index: UInt) {}
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
    internal var animating = false
    
    public var alphaValueOpaque: CGFloat = defaultAlphaValueOpaque
    public var alphaValueTransparent: CGFloat = defaultAlphaValueTransparent
    public var alphaValueSemiTransparent: CGFloat = defaultAlphaValueSemiTransparent
    
    public lazy var animator: KolodaViewAnimator = {
       return KolodaViewAnimator(koloda: self)
    }()
    
    internal var shouldTransparentizeNextCard: Bool {
        return delegate?.koloda(kolodaShouldTransparentizeNextCard: self) ?? true
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !animating {
            layoutDeck()
        }
    }
    
    //MARK: Configurations
    
    private func setupDeck() {
        if let dataSource = dataSource {
            countOfCards = Int(dataSource.koloda(kolodaNumberOfCards: self))
            
            if countOfCards - currentCardNumber > 0 {
                let countOfNeededCards = min(countOfVisibleCards, countOfCards - currentCardNumber)
                
                for index in 0..<countOfNeededCards {
                    let actualIndex = UInt(index + currentCardNumber)
                    let nextCardView = createCardAtIndex(actualIndex)
                    let isTop = index == 0
                    nextCardView.userInteractionEnabled = isTop
                    nextCardView.alpha = alphaValueOpaque
                    if shouldTransparentizeNextCard && !isTop {
                        nextCardView.alpha = alphaValueSemiTransparent
                    }
                    visibleCards.append(nextCardView)
                    isTop ? addSubview(nextCardView) : insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
                }
                self.delegate?.koloda(self, didShowCardAtIndex: UInt(currentCardNumber))
            }
        }
    }
    
    public func layoutDeck() {
        for (index, card) in visibleCards.enumerate() {
            layoutCard(card, AtIndex: UInt(index))
        }
    }
    
    private func layoutCard(card: DraggableCardView, AtIndex index: UInt) {
        if index == 0 {
            card.layer.transform = CATransform3DIdentity
            card.frame = frameForTopCard()
        } else {
            let cardParameters = backgroundCardParametersForFrame(frameForCardAtIndex(UInt(index)))
            
            let scale = cardParameters.scale
            card.layer.transform = CATransform3DScale(CATransform3DIdentity, scale.width, scale.height, 1.0)
            
            card.frame = cardParameters.frame
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
    
    internal func frameForTopCard() -> CGRect {
        return frameForCardAtIndex(0)
    }
    
    internal func backgroundCardParametersForFrame(initialFrame: CGRect) -> (frame: CGRect, scale: CGSize) {
        var finalFrame = frameForTopCard()
        finalFrame.origin = initialFrame.origin
        
        var scale = CGSize.zero
        scale.width = initialFrame.width / finalFrame.width
        scale.height = initialFrame.height / finalFrame.height

        return (finalFrame, scale)
    }
    
    internal func moveOtherCardsWithFinishPercent(percent: CGFloat) {
        if visibleCards.count > 1 {
            for index in 1..<visibleCards.count {
                let previousCardFrame = frameForCardAtIndex(UInt(index - 1))
                var frame = frameForCardAtIndex(UInt(index))
                let percentage = percent / 100
                
                let distanceToMoveY: CGFloat = (frame.origin.y - previousCardFrame.origin.y) * percentage
                
                frame.origin.y -= distanceToMoveY
                
                let distanceToMoveX: CGFloat = (previousCardFrame.origin.x - frame.origin.x) * percentage
                
                frame.origin.x += distanceToMoveX
                
                let widthDelta = (previousCardFrame.size.width - frame.size.width) * percentage
                let heightDelta = (previousCardFrame.size.height - frame.size.height) * percentage
                
                frame.size.width += widthDelta
                frame.size.height += heightDelta
                
                let cardParameters = backgroundCardParametersForFrame(frame)
                let scale = cardParameters.scale
                
                let card = visibleCards[index]

                card.layer.transform = CATransform3DScale(CATransform3DIdentity, scale.width, scale.height, 1.0)
                card.frame = cardParameters.frame
                
                //For fully visible next card, when moving top card
                if shouldTransparentizeNextCard {
                    if index == 1 {
                        card.alpha = alphaValueSemiTransparent + (alphaValueOpaque - alphaValueSemiTransparent) * percentage
                    }
                }
            }
        }
    }
    
    //MARK: Animations
    
    public func applyAppearAnimationIfNeeded() {
        if let shouldApply = delegate?.koloda(kolodaShouldApplyAppearAnimation: self) where shouldApply == true {
            self.alpha = 0
            userInteractionEnabled = false
            animating = true
            
            animator.animateAppearance { [weak self] _ in
                self?.userInteractionEnabled = true
                self?.animating = false
            }
        }
    }
    
    //MARK: DraggableCardDelegate
    
    func card(card: DraggableCardView, wasDraggedWithFinishPercent percent: CGFloat, inDirection direction: SwipeResultDirection) {
        animating = true
        
        if let shouldMove = delegate?.koloda(kolodaShouldMoveBackgroundCard: self) where shouldMove {
            self.moveOtherCardsWithFinishPercent(percent)
        }
        delegate?.koloda(self, draggedCardWithFinishPercent: percent, inDirection: direction)
    }
    
    func card(card: DraggableCardView, wasSwipedInDirection direction: SwipeResultDirection) {
        swipedAction(direction)
    }
    
    func card(cardWasReset card: DraggableCardView) {
        if visibleCards.count > 1 {
            animating = true
            animator.resetBackgroundCards { [weak self] _ in
                if let _self = self {
                    _self.animating = false
                    
                    for index in 1..<_self.visibleCards.count {
                        let card = _self.visibleCards[index]
                        if _self.shouldTransparentizeNextCard {
                            card.alpha = index == 0 ? _self.alphaValueOpaque : _self.alphaValueSemiTransparent
                        }
                    }
                }
            }
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
    
    //MARK: Actions
    private func swipedAction(direction: SwipeResultDirection) {
        animating = true
        visibleCards.removeFirst()
        
        currentCardNumber++
        let shownCardsCount = currentCardNumber + countOfVisibleCards
        if shownCardsCount - 1 < countOfCards {
            loadNextCard()
        }
        
        if !visibleCards.isEmpty {
            animateCardsAfterLoading { [weak self] in
                if let _self = self {
                    _self.visibleCards.last?.hidden = false
                    _self.animating = false
                    _self.delegate?.koloda(_self, didSwipedCardAtIndex: UInt(_self.currentCardNumber - 1), inDirection: direction)
                    _self.delegate?.koloda(_self, didShowCardAtIndex: UInt(_self.currentCardNumber))
                }
            }
        } else {
            animating = false
            delegate?.koloda(self, didSwipedCardAtIndex: UInt(self.currentCardNumber - 1), inDirection: direction)
            delegate?.koloda(kolodaDidRunOutOfCards: self)
        }
    }
    
    private func loadNextCard() {
        if let dataSource = dataSource {
            let cardParameters = backgroundCardParametersForFrame(frameForCardAtIndex(UInt(visibleCards.count)))
            let lastCard = createCardAtIndex(UInt(currentCardNumber + countOfVisibleCards - 1), frame: cardParameters.frame)
            
            let scale = cardParameters.scale
            lastCard.layer.transform = CATransform3DScale(CATransform3DIdentity, scale.width, scale.height, 1.0)
            lastCard.hidden = true
            lastCard.userInteractionEnabled = true
            
            if let card = visibleCards.last {
                insertSubview(lastCard, belowSubview: card)
            } else {
                addSubview(lastCard)
            }
            visibleCards.append(lastCard)
        }
    }
    
    private func animateCardsAfterLoading(completion: (Void -> Void)? = nil) {
        for (index, currentCard) in visibleCards.enumerate() {
            currentCard.removeAnimations()
            
            currentCard.userInteractionEnabled = index == 0
            let cardParameters = backgroundCardParametersForFrame(frameForCardAtIndex(UInt(index)))
            var animationCompletion: ((Bool) -> Void)? = nil
            if index != 0 {
                if shouldTransparentizeNextCard {
                    currentCard.alpha = alphaValueSemiTransparent
                }
            } else {
                animationCompletion = { finished in
                    completion?()
                }
                
                if shouldTransparentizeNextCard {
                    animator.applyAlphaAnimation(currentCard, alpha: alphaValueOpaque)
                } else {
                    currentCard.alpha = alphaValueOpaque
                }
            }
            
            animator.applyScaleAnimation(
                currentCard,
                scale: cardParameters.scale,
                frame: cardParameters.frame,
                duration: backgroundCardFrameAnimationDuration,
                completion: animationCompletion
            )
        }
    }
    
    public func revertAction() {
        if currentCardNumber > 0 && !animating {
            
            if countOfCards - currentCardNumber >= countOfVisibleCards {
                
                if let lastCard = visibleCards.last {
                    
                    lastCard.removeFromSuperview()
                    visibleCards.removeLast()
                }
            }
            
            currentCardNumber--
            
            if let dataSource = self.dataSource {
                let firstCardView = createCardAtIndex(UInt(currentCardNumber), frame: frameForTopCard())
                
                if shouldTransparentizeNextCard {
                    firstCardView.alpha = alphaValueTransparent
                }
                
                firstCardView.delegate = self
                
                addSubview(firstCardView)
                visibleCards.insert(firstCardView, atIndex: 0)
                
                
                animating = true
                animator.applyRevertAnimation(firstCardView, completion: { [weak self] in
                    if let _self = self {
                        _self.animating = false
                        _self.delegate?.koloda(_self, didShowCardAtIndex: UInt(_self.currentCardNumber))
                    }
                })
            }

            for (index, card) in visibleCards.dropFirst().enumerate() {
                if shouldTransparentizeNextCard {
                    card.alpha = alphaValueSemiTransparent
                }
                card.userInteractionEnabled = false
                
                let cardParameters = backgroundCardParametersForFrame(frameForCardAtIndex(UInt(index + 1)))
                animator.applyScaleAnimation(
                    card,
                    scale: cardParameters.scale,
                    frame: cardParameters.frame,
                    duration: backgroundCardFrameAnimationDuration,
                    completion: nil
                )
            }
        }
    }
    
    private func loadMissingCards(missingCardsCount: Int) {
        if missingCardsCount > 0 {
            let cardsToAdd = min(missingCardsCount, countOfCards - currentCardNumber)
            let startIndex = visibleCards.count
            let endIndex = startIndex + cardsToAdd - 1
            
            for index in startIndex...endIndex {
                let nextCardView = generateCard(frameForTopCard())
                layoutCard(nextCardView, AtIndex: UInt(index))
                nextCardView.alpha = shouldTransparentizeNextCard ? alphaValueSemiTransparent : alphaValueOpaque
                
                visibleCards.append(nextCardView)
                configureCard(nextCardView, atIndex: UInt(currentCardNumber + index))
                insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
            }
        }
    }
    
    private func reconfigureCards() {
        for (index, card) in visibleCards.enumerate() {
            if let dataSource = self.dataSource {
                let actualIndex = UInt(currentCardNumber + index)
                configureCard(card, atIndex: actualIndex)
            }
        }
    }
    
    private func calculateMissingCardsCount() -> Int {
       return min(countOfVisibleCards - visibleCards.count, countOfCards - (currentCardNumber + 1))
    }
    
    // MARK: Public
    
    public func reloadData() {
        guard let numberOfCards = dataSource?.koloda(kolodaNumberOfCards: self) where numberOfCards > 0 else {
            clear()
            return
        }
        
        if currentCardNumber == 0 {
            clear()
        }
        
        countOfCards = Int(numberOfCards)
        if countOfCards - (currentCardNumber + visibleCards.count) > 0 {
            if !visibleCards.isEmpty {
                let missingCards = calculateMissingCardsCount()
                loadMissingCards(missingCards)
            } else {
                setupDeck()
                layoutDeck()
                applyAppearAnimationIfNeeded()
            }
        } else {
            reconfigureCards()
        }
    }
    
    public func swipe(direction: SwipeResultDirection) {
        if !animating {
            if let frontCard = visibleCards.first {
                animating = true
                
                if visibleCards.count > 1 {
                    let nextCard = visibleCards[1]
                    nextCard.alpha = shouldTransparentizeNextCard ? alphaValueSemiTransparent : alphaValueOpaque
                }
                frontCard.swipe(direction)
                frontCard.delegate = nil
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
    
    // MARK: Cards managing - Insertion

    private func insertVisibleCardsWithIndexes(visibleIndexes: [Int]) -> [DraggableCardView] {
        var insertedCards: [DraggableCardView] = []
        visibleIndexes.forEach { insertionIndex in
            let card = createCardAtIndex(UInt(insertionIndex))
            let visibleCardIndex = insertionIndex - currentCardNumber
            visibleCards.insert(card, atIndex: visibleCardIndex)
            if visibleCardIndex == 0 {
                card.frame = frameForTopCard()
                card.layer.transform = CATransform3DIdentity
                card.alpha = alphaValueOpaque
                insertSubview(card, atIndex: visibleCards.count - 1)
            } else {
                insertSubview(card, belowSubview: visibleCards[visibleCardIndex - 1])
            }
            insertedCards.append(card)
        }
        
        return insertedCards
    }
    
    private func removeCards(cards: [DraggableCardView]) {
        cards.forEach { card in
            card.delegate = nil
            card.removeFromSuperview()
        }
        visibleCards.removeLast(cards.count)
    }
    
    private func removeCards(cards: [DraggableCardView], animated: Bool) {
        if animated {
            animator.applyRemovalAnimation(
                cards,
                completion: { _ in
                    self.removeCards(cards)
                }
            )
        } else {
            self.removeCards(cards)
        }
    }
    
    public func insertCardAtIndexSet(indexRange: Range<Int>, animated: Bool = true) {
        if let dataSource = dataSource {
            let currentItemsCount = countOfCards
            let visibleIndexes = [Int](indexRange).filter { $0 >= currentCardNumber && $0 < currentCardNumber + countOfVisibleCards }
            let insertedCards = insertVisibleCardsWithIndexes(visibleIndexes.sort())
            removeCards(visibleCards.dropFirst(countOfVisibleCards).map { $0 }, animated: animated)
            for (index, card) in visibleCards.enumerate() {
                card.alpha = shouldTransparentizeNextCard && index != 0 ? alphaValueSemiTransparent : alphaValueOpaque
                card.userInteractionEnabled = index == 0
            }
            animator.resetBackgroundCards()
            if animated {
               animator.applyInsertionAnimation(insertedCards)
            }
            
            countOfCards = Int(dataSource.koloda(kolodaNumberOfCards: self))
            assert(
                currentItemsCount + indexRange.count == countOfCards,
                "Cards count after update is not equal to data source count"
            )
        }
    }
    
    // MARK: Cards managing - Deletion
    
    private func proceedDeletion(range: Range<Int>) {
        let deletionIndexes = [Int](range)
        deletionIndexes.sort { $0 > $1 }.forEach { deletionIndex in
            let visibleCardIndex = deletionIndex - currentCardNumber
            let card = visibleCards[visibleCardIndex]
            card.delegate = nil
            card.swipe(.Right)
            visibleCards.removeAtIndex(visibleCardIndex)
        }
    }
    
    public func removeCardAtIndexRange(indexRange: Range<Int>, animated: Bool) {
        if let dataSource = dataSource {
            animating = true
            let currentItemsCount = countOfCards
            let visibleIndexes = [Int](indexRange).filter { $0 >= currentCardNumber && $0 < currentCardNumber + countOfVisibleCards }
            if !visibleIndexes.isEmpty {
                proceedDeletion(visibleIndexes[0]...visibleIndexes[visibleIndexes.count - 1])
            }
            loadMissingCards(calculateMissingCardsCount())
            layoutDeck()
            for (index, card) in visibleCards.enumerate() {
                card.alpha = shouldTransparentizeNextCard && index != 0 ? alphaValueSemiTransparent : alphaValueOpaque
                card.userInteractionEnabled = index == 0
            }
            animating = false
            
            countOfCards = Int(dataSource.koloda(kolodaNumberOfCards: self))
            assert(
                currentItemsCount - indexRange.count == countOfCards,
                "Cards count after update is not equal to data source count"
            )
        }
    }
    
}
