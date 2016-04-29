//
//  KolodaView.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/24/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit
import pop

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
    
    func kolodaNumberOfCards(koloda: KolodaView) -> UInt
    func koloda(koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView?
}

public extension KolodaViewDataSource {
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView? {
        return nil
    }
}

public protocol KolodaViewDelegate:class {
    
    func koloda(koloda: KolodaView, allowedDirectionsForIndex index: UInt) -> [SwipeResultDirection]
    func koloda(koloda: KolodaView, shouldSwipeCardAtIndex index: UInt, inDirection direction: SwipeResultDirection) -> Bool
    func koloda(koloda: KolodaView, didSwipeCardAtIndex index: UInt, inDirection direction: SwipeResultDirection)
    func kolodaDidRunOutOfCards(koloda: KolodaView)
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt)
    func kolodaShouldApplyAppearAnimation(koloda: KolodaView) -> Bool
    func kolodaShouldMoveBackgroundCard(koloda: KolodaView) -> Bool
    func kolodaShouldTransparentizeNextCard(koloda: KolodaView) -> Bool
    func koloda(koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, inDirection direction: SwipeResultDirection)
    func kolodaDidResetCard(koloda: KolodaView)
    func kolodaSwipeThresholdRatioMargin(koloda: KolodaView) -> CGFloat?
    func koloda(koloda: KolodaView, didShowCardAtIndex index: UInt)
    func koloda(koloda: KolodaView, shouldDragCardAtIndex index: UInt ) -> Bool
}

public extension KolodaViewDelegate {
    func koloda(koloda: KolodaView, shouldSwipeCardAtIndex index: UInt, inDirection direction: SwipeResultDirection) -> Bool { return true }

    func koloda(koloda: KolodaView, allowedDirectionsForIndex index: UInt) -> [SwipeResultDirection] { return [.Left, .Right] }
    func koloda(koloda: KolodaView, didSwipeCardAtIndex index: UInt, inDirection direction: SwipeResultDirection) {}
    func kolodaDidRunOutOfCards(koloda: KolodaView) {}
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt) {}
    func kolodaShouldApplyAppearAnimation(koloda: KolodaView) -> Bool { return true }
    func kolodaShouldMoveBackgroundCard(koloda: KolodaView) -> Bool { return true }
    func kolodaShouldTransparentizeNextCard(koloda: KolodaView) -> Bool { return true }
    func koloda(koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, inDirection direction: SwipeResultDirection) {}
    func kolodaDidResetCard(koloda: KolodaView) {}
    func kolodaSwipeThresholdRatioMargin(koloda: KolodaView) -> CGFloat? { return nil}
    func koloda(koloda: KolodaView, didShowCardAtIndex index: UInt) {}
    func koloda(koloda: KolodaView, shouldDragCardAtIndex index: UInt ) -> Bool { return true }
}

public class KolodaView: UIView, DraggableCardDelegate {
    
    public weak var dataSource: KolodaViewDataSource? {
        didSet {
            setupDeck()
        }
    }
    
    public weak var delegate: KolodaViewDelegate?
    
    private(set) public var currentCardIndex = 0
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
        return delegate?.kolodaShouldTransparentizeNextCard(self) ?? true
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
            countOfCards = Int(dataSource.kolodaNumberOfCards(self))
            
            if countOfCards - currentCardIndex > 0 {
                let countOfNeededCards = min(countOfVisibleCards, countOfCards - currentCardIndex)
                
                for index in 0..<countOfNeededCards {
                    let actualIndex = UInt(index + currentCardIndex)
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
                self.delegate?.koloda(self, didShowCardAtIndex: UInt(currentCardIndex))
            }
        }
    }
    
    public func layoutDeck() {
        for (index, card) in visibleCards.enumerate() {
            layoutCard(card, atIndex: UInt(index))
        }
    }
    
    private func layoutCard(card: DraggableCardView, atIndex index: UInt) {
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
    
    internal func moveOtherCardsWithPercentage(percentage: CGFloat) {
        if visibleCards.count > 1 {
            for index in 1..<visibleCards.count {
                let previousCardFrame = frameForCardAtIndex(UInt(index - 1))
                var frame = frameForCardAtIndex(UInt(index))
                let fraction = percentage / 100
                
                let distanceToMoveY: CGFloat = (frame.origin.y - previousCardFrame.origin.y) * fraction
                
                frame.origin.y -= distanceToMoveY
                
                let distanceToMoveX: CGFloat = (previousCardFrame.origin.x - frame.origin.x) * fraction
                
                frame.origin.x += distanceToMoveX
                
                let widthDelta = (previousCardFrame.size.width - frame.size.width) * fraction
                let heightDelta = (previousCardFrame.size.height - frame.size.height) * fraction
                
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
                        card.alpha = alphaValueSemiTransparent + (alphaValueOpaque - alphaValueSemiTransparent) * fraction
                    }
                }
            }
        }
    }
    
    //MARK: Animations
    
    private func applyAppearAnimation() {
        alpha = 0
        userInteractionEnabled = false
        animating = true
        
        animator.animateAppearanceWithCompletion { [weak self] _ in
            self?.userInteractionEnabled = true
            self?.animating = false
        }
    }
    
    public func applyAppearAnimationIfNeeded() {
        if let shouldApply = delegate?.kolodaShouldApplyAppearAnimation(self) where shouldApply == true {
            applyAppearAnimation()
        }
    }
    
    //MARK: DraggableCardDelegate
    
    func card(card: DraggableCardView, wasDraggedWithFinishPercentage percentage: CGFloat, inDirection direction: SwipeResultDirection) {
        animating = true
        
        if let shouldMove = delegate?.kolodaShouldMoveBackgroundCard(self) where shouldMove {
            self.moveOtherCardsWithPercentage(percentage)
        }
        delegate?.koloda(self, draggedCardWithPercentage: percentage, inDirection: direction)
    }
    
    func card(card: DraggableCardView, shouldSwipeInDirection direction: SwipeResultDirection) -> Bool {
        return delegate?.koloda(self, shouldSwipeCardAtIndex: UInt(self.currentCardIndex), inDirection: direction) ?? true
    }
    
    func card(cardAllowedDirections card: DraggableCardView) -> [SwipeResultDirection] {
        let index = currentCardIndex + visibleCards.indexOf(card)!
        return delegate?.koloda(self, allowedDirectionsForIndex: UInt(index)) ?? [.Left, .Right]
    }
    
    func card(card: DraggableCardView, wasSwipedInDirection direction: SwipeResultDirection) {
        swipedAction(direction)
    }
    
    func card(cardWasReset card: DraggableCardView) {
        if visibleCards.count > 1 {
            animating = true
            animator.resetBackgroundCardsWithCompletion { [weak self] _ in
                guard let _self = self else {
                    return
                }
                
                _self.animating = false
                
                for index in 1..<_self.visibleCards.count {
                    let card = _self.visibleCards[index]
                    if _self.shouldTransparentizeNextCard {
                        card.alpha = index == 0 ? _self.alphaValueOpaque : _self.alphaValueSemiTransparent
                    }
                }
            }
        } else {
            animating = false
        }
        
        delegate?.kolodaDidResetCard(self)
    }
    
    func card(cardWasTapped card: DraggableCardView) {
        guard let visibleIndex = visibleCards.indexOf(card) else { return }
        
        let index = currentCardIndex + visibleIndex
        delegate?.koloda(self, didSelectCardAtIndex: UInt(index))
    }
    
    func card(cardSwipeThresholdRatioMargin card: DraggableCardView) -> CGFloat? {
        return delegate?.kolodaSwipeThresholdRatioMargin(self)
    }
    
    func card(cardShouldDrag card: DraggableCardView) -> Bool {
        guard let visibleIndex = visibleCards.indexOf(card) else { return true}
        
        let index = currentCardIndex + visibleIndex
        return delegate?.koloda(self, shouldDragCardAtIndex: UInt(index)) ?? true
    }
    
    //MARK: Private
    private func clear() {
        currentCardIndex = 0
        
        for card in visibleCards {
            card.removeFromSuperview()
        }
        
        visibleCards.removeAll(keepCapacity: true)
    }
    
    //MARK: Actions
    private func swipedAction(direction: SwipeResultDirection) {
        animating = true
        visibleCards.removeFirst()
        
        currentCardIndex += 1
        let shownCardsCount = currentCardIndex + countOfVisibleCards
        if shownCardsCount - 1 < countOfCards {
            loadNextCard()
        }
        
        if !visibleCards.isEmpty {
            animateCardsAfterLoadingWithCompletion { [weak self] in
                guard let _self = self else {
                    return
                }
                
                _self.visibleCards.last?.hidden = false
                _self.animating = false
                _self.delegate?.koloda(_self, didSwipeCardAtIndex: UInt(_self.currentCardIndex - 1), inDirection: direction)
                _self.delegate?.koloda(_self, didShowCardAtIndex: UInt(_self.currentCardIndex))
            }
        } else {
            animating = false
            delegate?.koloda(self, didSwipeCardAtIndex: UInt(self.currentCardIndex - 1), inDirection: direction)
            delegate?.kolodaDidRunOutOfCards(self)
        }
    }
    
    private func loadNextCard() {
        guard dataSource != nil else {
            return
        }
        
        let cardParameters = backgroundCardParametersForFrame(frameForCardAtIndex(UInt(visibleCards.count)))
        let lastCard = createCardAtIndex(UInt(currentCardIndex + countOfVisibleCards - 1), frame: cardParameters.frame)
        
        let scale = cardParameters.scale
        lastCard.layer.transform = CATransform3DScale(CATransform3DIdentity, scale.width, scale.height, 1)
        lastCard.hidden = true
        lastCard.userInteractionEnabled = true
        
        if let card = visibleCards.last {
            insertSubview(lastCard, belowSubview: card)
        } else {
            addSubview(lastCard)
        }
        visibleCards.append(lastCard)
    }
    
    private func animateCardsAfterLoadingWithCompletion(completion: (Void -> Void)? = nil) {
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
        if currentCardIndex > 0 && !animating {
            
            if countOfCards - currentCardIndex >= countOfVisibleCards {
                if let lastCard = visibleCards.last {
                    lastCard.removeFromSuperview()
                    visibleCards.removeLast()
                }
            }
            currentCardIndex -= 1
            
            if dataSource != nil {
                let firstCardView = createCardAtIndex(UInt(currentCardIndex), frame: frameForTopCard())
                
                if shouldTransparentizeNextCard {
                    firstCardView.alpha = alphaValueTransparent
                }
                firstCardView.delegate = self
                
                addSubview(firstCardView)
                visibleCards.insert(firstCardView, atIndex: 0)
                
                animating = true
                animator.applyReverseAnimation(firstCardView, completion: { [weak self] _ in
                    guard let _self = self else {
                        return
                    }
                    
                    _self.animating = false
                    _self.delegate?.koloda(_self, didShowCardAtIndex: UInt(_self.currentCardIndex))
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
            let cardsToAdd = min(missingCardsCount, countOfCards - currentCardIndex)
            let startIndex = visibleCards.count
            let endIndex = startIndex + cardsToAdd - 1
            
            for index in startIndex...endIndex {
                let nextCardView = generateCard(frameForTopCard())
                layoutCard(nextCardView, atIndex: UInt(index))
                nextCardView.alpha = shouldTransparentizeNextCard ? alphaValueSemiTransparent : alphaValueOpaque
                
                visibleCards.append(nextCardView)
                configureCard(nextCardView, atIndex: UInt(currentCardIndex + index))
                insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
            }
        }
    }
    
    private func reconfigureCards() {
        if dataSource != nil {
            for (index, card) in visibleCards.enumerate() {
                let actualIndex = UInt(currentCardIndex + index)
                configureCard(card, atIndex: actualIndex)
            }
        }
    }
    
    private func missingCardsCount() -> Int {
       return min(countOfVisibleCards - visibleCards.count, countOfCards - (currentCardIndex + 1))
    }
    
    // MARK: Public
    
    public func reloadData() {
        guard let numberOfCards = dataSource?.kolodaNumberOfCards(self) where numberOfCards > 0 else {
            clear()
            return
        }
        
        if currentCardIndex == 0 {
            clear()
        }
        
        countOfCards = Int(numberOfCards)
        if countOfCards - (currentCardIndex + visibleCards.count) > 0 {
            if !visibleCards.isEmpty {
                let missingCards = missingCardsCount()
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
        
        let validDirection = delegate?.koloda(self, allowedDirectionsForIndex: UInt(currentCardIndex)).contains(direction) ?? true
        guard validDirection else { return }
        
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
    
    public func resetCurrentCardIndex() {
        clear()
        reloadData()
    }
    
    public func viewForCardAtIndex(index: Int) -> UIView? {
        if visibleCards.count + currentCardIndex > index && index >= currentCardIndex {
            return visibleCards[index - currentCardIndex].contentView
        } else {
            return nil
        }
    }
    
    // MARK: Cards managing - Insertion

    private func insertVisibleCardsWithIndexes(visibleIndexes: [Int]) -> [DraggableCardView] {
        var insertedCards: [DraggableCardView] = []
        visibleIndexes.forEach { insertionIndex in
            let card = createCardAtIndex(UInt(insertionIndex))
            let visibleCardIndex = insertionIndex - currentCardIndex
            visibleCards.insert(card, atIndex: visibleCardIndex)
            if visibleCardIndex == 0 {
                card.userInteractionEnabled = true
                card.alpha = alphaValueOpaque
                insertSubview(card, atIndex: visibleCards.count - 1)
            } else {
                card.userInteractionEnabled = false
                card.alpha = shouldTransparentizeNextCard ? alphaValueSemiTransparent : alphaValueOpaque
                insertSubview(card, belowSubview: visibleCards[visibleCardIndex - 1])
            }
            layoutCard(card, atIndex: UInt(visibleCardIndex))
            insertedCards.append(card)
        }
        
        return insertedCards
    }
    
    private func removeCards(cards: [DraggableCardView]) {
        cards.forEach { card in
            card.delegate = nil
            card.removeFromSuperview()
        }
    }
    
    private func removeCards(cards: [DraggableCardView], animated: Bool) {
        visibleCards.removeLast(cards.count)
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
    
    public func insertCardAtIndexRange(indexRange: Range<Int>, animated: Bool = true) {
        guard let dataSource = dataSource else {
            return
        }
        
        let currentItemsCount = countOfCards
        let visibleIndexes = [Int](indexRange).filter { $0 >= currentCardIndex && $0 < currentCardIndex + countOfVisibleCards }
        let insertedCards = insertVisibleCardsWithIndexes(visibleIndexes.sort())
        let cardsToRemove = visibleCards.dropFirst(countOfVisibleCards).map { $0 }
        removeCards(cardsToRemove, animated: animated)
        animator.resetBackgroundCardsWithCompletion()
        if animated {
            animating = true
            animator.applyInsertionAnimation(
                insertedCards,
                completion: { _ in
                    self.animating = false
                }
            )
        }
        
        countOfCards = Int(dataSource.kolodaNumberOfCards(self))
        assert(
            currentItemsCount + indexRange.count == countOfCards,
            "Cards count after update is not equal to data source count"
        )
    }
    
    // MARK: Cards managing - Deletion
    
    private func proceedDeletionInRange(range: Range<Int>) {
        let deletionIndexes = [Int](range)
        deletionIndexes.sort { $0 > $1 }.forEach { deletionIndex in
            let visibleCardIndex = deletionIndex - currentCardIndex
            let card = visibleCards[visibleCardIndex]
            card.delegate = nil
            card.swipe(.Right)
            visibleCards.removeAtIndex(visibleCardIndex)
        }
    }
    
    public func removeCardInIndexRange(indexRange: Range<Int>, animated: Bool) {
        guard let dataSource = dataSource else {
            return
        }
        
        animating = true
        let currentItemsCount = countOfCards
        let visibleIndexes = [Int](indexRange).filter { $0 >= currentCardIndex && $0 < currentCardIndex + countOfVisibleCards }
        if !visibleIndexes.isEmpty {
            proceedDeletionInRange(visibleIndexes[0]..<visibleIndexes[visibleIndexes.count])
        }
        loadMissingCards(missingCardsCount())
        layoutDeck()
        for (index, card) in visibleCards.enumerate() {
            card.alpha = shouldTransparentizeNextCard && index != 0 ? alphaValueSemiTransparent : alphaValueOpaque
            card.userInteractionEnabled = index == 0
        }
        animating = false
        
        countOfCards = Int(dataSource.kolodaNumberOfCards(self))
        assert(
            currentItemsCount - indexRange.count == countOfCards,
            "Cards count after update is not equal to data source count"
        )
    }
    
    // MARK: Cards managing - Reloading
    
    public func reloadCardsInIndexRange(indexRange: Range<Int>) {
        guard dataSource != nil else {
            return
        }
        
        let visibleIndexes = [Int](indexRange).filter { $0 >= currentCardIndex && $0 < currentCardIndex + countOfVisibleCards }
        visibleIndexes.forEach { index in
            let visibleCardIndex = index - currentCardIndex
            if visibleCards.count > visibleCardIndex {
                let card = visibleCards[visibleCardIndex]
                configureCard(card, atIndex: UInt(index))
            }
        }
    }
    
}
