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
private let defaultBackgroundCardsTopMargin: CGFloat = 4.0
private let defaultBackgroundCardsScalePercent: CGFloat = 0.95
private let defaultBackgroundCardsLeftMargin: CGFloat = 8.0
private let defaultBackgroundCardFrameAnimationDuration: TimeInterval = 0.2
private let defaultAppearanceAnimationDuration: TimeInterval = 0.8

//Opacity values
private let defaultAlphaValueOpaque: CGFloat = 1.0
private let defaultAlphaValueTransparent: CGFloat = 0.0
private let defaultAlphaValueSemiTransparent: CGFloat = 0.7

public protocol KolodaViewDataSource: class {
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView?
}

public extension KolodaViewDataSource {
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return nil
    }
    
}

public protocol KolodaViewDelegate: class {
    
    func koloda(_ koloda: KolodaView, allowedDirectionsForIndex index: Int) -> [SwipeResultDirection]
    func koloda(_ koloda: KolodaView, shouldSwipeCardAt index: Int, in direction: SwipeResultDirection) -> Bool
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection)
    func kolodaDidRunOutOfCards(_ koloda: KolodaView)
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int)
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool
    func koloda(_ koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, in direction: SwipeResultDirection)
    func kolodaDidResetCard(_ koloda: KolodaView)
    func kolodaSwipeThresholdRatioMargin(_ koloda: KolodaView) -> CGFloat?
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int)
    func koloda(_ koloda: KolodaView, shouldDragCardAt index: Int ) -> Bool
    
}

public extension KolodaViewDelegate {
    
    func koloda(_ koloda: KolodaView, shouldSwipeCardAt index: Int, in direction: SwipeResultDirection) -> Bool { return true }
    func koloda(_ koloda: KolodaView, allowedDirectionsForIndex index: Int) -> [SwipeResultDirection] { return [.left, .right] }
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {}
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {}
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {}
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool { return true }
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool { return true }
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool { return true }
    func koloda(_ koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, in direction: SwipeResultDirection) {}
    func kolodaDidResetCard(_ koloda: KolodaView) {}
    func kolodaSwipeThresholdRatioMargin(_ koloda: KolodaView) -> CGFloat? { return nil}
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int) {}
    func koloda(_ koloda: KolodaView, shouldDragCardAt index: Int ) -> Bool { return true }
    
}

open class KolodaView: UIView, DraggableCardDelegate {

    //Opacity values
    public var alphaValueOpaque = defaultAlphaValueOpaque
    public var alphaValueTransparent = defaultAlphaValueTransparent
    public var alphaValueSemiTransparent = defaultAlphaValueSemiTransparent
    public var shouldPassthroughTapsWhenNoVisibleCards = false

    //Drag animation constants
    public var rotationMax: CGFloat?
    public var rotationAngle: CGFloat?
    public var scaleMin: CGFloat?

    public var appearanceAnimationDuration = defaultAppearanceAnimationDuration

    public weak var dataSource: KolodaViewDataSource? {
        didSet {
            setupDeck()
        }
    }
    
    public weak var delegate: KolodaViewDelegate?
    
    public var animator: KolodaViewAnimator {
        set {
            self._animator = newValue
        }
        get {
            return self._animator
        }
    }
    
    private lazy var _animator: KolodaViewAnimator = {
        return KolodaViewAnimator(koloda: self)
    }()
    
    internal var animating = false
    
    internal var shouldTransparentizeNextCard: Bool {
        return delegate?.kolodaShouldTransparentizeNextCard(self) ?? true
    }
    
    public var isRunOutOfCards: Bool {
        
        return visibleCards.isEmpty
    }
    
    private(set) public var currentCardIndex = 0
    private(set) public var countOfCards = 0
    public var countOfVisibleCards = defaultCountOfVisibleCards
    private var visibleCards = [DraggableCardView]()

    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if !animating {
            layoutDeck()
        }
    }
    
    // MARK: Configurations
    
    private func setupDeck() {
        if let dataSource = dataSource {
            countOfCards = dataSource.kolodaNumberOfCards(self)

            if countOfCards - currentCardIndex > 0 {
                let countOfNeededCards = min(countOfVisibleCards, countOfCards - currentCardIndex)
                
                for index in 0..<countOfNeededCards {
                    let actualIndex = index + currentCardIndex
                    let nextCardView = createCard(at: actualIndex)
                    let isTop = index == 0
                    nextCardView.isUserInteractionEnabled = isTop
                    nextCardView.alpha = alphaValueOpaque
                    if shouldTransparentizeNextCard && !isTop {
                        nextCardView.alpha = alphaValueSemiTransparent
                    }
                    visibleCards.append(nextCardView)
                    isTop ? addSubview(nextCardView) : insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
                }
                self.delegate?.koloda(self, didShowCardAt: currentCardIndex)
            }
        }
    }
    
    public func layoutDeck() {
        for (index, card) in visibleCards.enumerated() {
            layoutCard(card, at: index)
        }
    }
    
    private func layoutCard(_ card: DraggableCardView, at index: Int) {
        if index == 0 {
            card.layer.transform = CATransform3DIdentity
            card.frame = frameForTopCard()
        } else {
            let cardParameters = backgroundCardParametersForFrame(frameForCard(at: index))
            let scale = cardParameters.scale
            card.layer.transform = CATransform3DScale(CATransform3DIdentity, scale.width, scale.height, 1.0)
            card.frame = cardParameters.frame
        }
    }
    
    // MARK: Frames
    open func frameForCard(at index: Int) -> CGRect {
        let bottomOffset: CGFloat = 0
        let topOffset = defaultBackgroundCardsTopMargin * CGFloat(countOfVisibleCards - 1)
        let scalePercent = defaultBackgroundCardsScalePercent
        let width = self.frame.width * pow(scalePercent, CGFloat(index))
        let xOffset = (self.frame.width - width) / 2
        let height = (self.frame.height - bottomOffset - topOffset) * pow(scalePercent, CGFloat(index))
        let multiplier: CGFloat = index > 0 ? 1.0 : 0.0
        let prevCardFrame = index > 0 ? frameForCard(at: max(index - 1, 0)) : .zero
        let yOffset = (prevCardFrame.height - height + prevCardFrame.origin.y + defaultBackgroundCardsTopMargin) * multiplier
        let frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        
        return frame
    }
    
    internal func frameForTopCard() -> CGRect {
        return frameForCard(at: 0)
    }
    
    internal func backgroundCardParametersForFrame(_ initialFrame: CGRect) -> (frame: CGRect, scale: CGSize) {
        var finalFrame = frameForTopCard()
        finalFrame.origin = initialFrame.origin
        
        var scale = CGSize.zero
        scale.width = initialFrame.width / finalFrame.width
        scale.height = initialFrame.height / finalFrame.height
        
        if #available(iOS 11, *) {
            return (initialFrame, scale)
        } else {
            return (finalFrame, scale)
        }
    }
    
    internal func moveOtherCardsWithPercentage(_ percentage: CGFloat) {
        guard visibleCards.count > 1 else {
          return
        }
        for index in 1..<visibleCards.count {
          let previousCardFrame = frameForCard(at: index - 1)
          var frame = frameForCard(at: index)
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

    // MARK: Animations

    private func applyAppearAnimation() {
        alpha = 0
        isUserInteractionEnabled = false
        animating = true

        animator.animateAppearance(appearanceAnimationDuration) { [weak self] _ in
            self?.isUserInteractionEnabled = true
            self?.animating = false
        }
    }
    
    public func applyAppearAnimationIfNeeded() {
        if let shouldApply = delegate?.kolodaShouldApplyAppearAnimation(self), shouldApply == true {
            applyAppearAnimation()
        }
    }
    
    // MARK: DraggableCardDelegate
    
    func card(_ card: DraggableCardView, wasDraggedWithFinishPercentage percentage: CGFloat, inDirection direction: SwipeResultDirection) {
        animating = true
        
        if let shouldMove = delegate?.kolodaShouldMoveBackgroundCard(self), shouldMove {
            self.moveOtherCardsWithPercentage(percentage)
        }
        delegate?.koloda(self, draggedCardWithPercentage: percentage, in: direction)
    }
    
    func card(_ card: DraggableCardView, shouldSwipeIn direction: SwipeResultDirection) -> Bool {
        return delegate?.koloda(self, shouldSwipeCardAt: self.currentCardIndex, in: direction) ?? true
    }
    
    func card(cardAllowedDirections card: DraggableCardView) -> [SwipeResultDirection] {
        let index = currentCardIndex + visibleCards.index(of: card)!
        return delegate?.koloda(self, allowedDirectionsForIndex: index) ?? [.left, .right]
    }
    
    func card(_ card: DraggableCardView, wasSwipedIn direction: SwipeResultDirection) {
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
        guard let visibleIndex = visibleCards.index(of: card) else { return }
        
        let index = currentCardIndex + visibleIndex
        delegate?.koloda(self, didSelectCardAt: index)
    }
    
    func card(cardSwipeThresholdRatioMargin card: DraggableCardView) -> CGFloat? {
        return delegate?.kolodaSwipeThresholdRatioMargin(self)
    }
    
    func card(cardShouldDrag card: DraggableCardView) -> Bool {
        guard let visibleIndex = visibleCards.index(of: card) else { return true}
        
        let index = currentCardIndex + visibleIndex
        return delegate?.koloda(self, shouldDragCardAt: index) ?? true
    }

    func card(cardSwipeSpeed card: DraggableCardView) -> DragSpeed {
        return dataSource?.kolodaSpeedThatCardShouldDrag(self) ?? DragSpeed.default
    }
    
    // MARK: Private
    private func clear() {
        currentCardIndex = 0
        
        for card in visibleCards {
            card.removeFromSuperview()
        }
        
        visibleCards.removeAll(keepingCapacity: true)
    }
    
    // MARK: Actions
    private func swipedAction(_ direction: SwipeResultDirection) {
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
                
                _self.visibleCards.last?.isHidden = false
                _self.animating = false
                _self.delegate?.koloda(_self, didSwipeCardAt: _self.currentCardIndex - 1, in: direction)
                _self.delegate?.koloda(_self, didShowCardAt: _self.currentCardIndex)
            }
        } else {
            animating = false
            delegate?.koloda(self, didSwipeCardAt: self.currentCardIndex - 1, in: direction)
            delegate?.kolodaDidRunOutOfCards(self)
        }
    }
    
    private func loadNextCard() {
        guard dataSource != nil else {
            return
        }
        
        let cardParameters = backgroundCardParametersForFrame(frameForCard(at: visibleCards.count))
        let lastCard = createCard(at: currentCardIndex + countOfVisibleCards - 1, frame: cardParameters.frame)
        
        let scale = cardParameters.scale
        lastCard.layer.transform = CATransform3DScale(CATransform3DIdentity, scale.width, scale.height, 1)
        lastCard.isHidden = true
        lastCard.isUserInteractionEnabled = true
        
        if let card = visibleCards.last {
            insertSubview(lastCard, belowSubview: card)
        } else {
            addSubview(lastCard)
        }
        visibleCards.append(lastCard)
    }
    
    private func animateCardsAfterLoadingWithCompletion(_ completion: (() -> Void)? = nil) {
        for (index, currentCard) in visibleCards.enumerated() {
            currentCard.removeAnimations()
            
            currentCard.isUserInteractionEnabled = index == 0
            let cardParameters = backgroundCardParametersForFrame(frameForCard(at: index))
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
                duration: defaultBackgroundCardFrameAnimationDuration,
                completion: animationCompletion
            )
        }
    }
    
    public func revertAction() {
        guard currentCardIndex > 0 && !animating else {
          return
        }
        if countOfCards - currentCardIndex >= countOfVisibleCards {
            if let lastCard = visibleCards.last {
                lastCard.removeFromSuperview()
                visibleCards.removeLast()
            }
        }
        currentCardIndex -= 1
        
        if dataSource != nil {
            let firstCardView = createCard(at: currentCardIndex, frame: frameForTopCard())
            
            if shouldTransparentizeNextCard {
                firstCardView.alpha = alphaValueTransparent
            }
            firstCardView.delegate = self
            
            addSubview(firstCardView)
            visibleCards.insert(firstCardView, at: 0)
            
            animating = true
            animator.applyReverseAnimation(firstCardView, completion: { [weak self] _ in
                guard let _self = self else {
                    return
                }
                
                _self.animating = false
                _self.delegate?.koloda(_self, didShowCardAt: _self.currentCardIndex)
                })
        }
        
        for (index, card) in visibleCards.dropFirst().enumerated() {
            if shouldTransparentizeNextCard {
                card.alpha = alphaValueSemiTransparent
            }
            card.isUserInteractionEnabled = false
            
            let cardParameters = backgroundCardParametersForFrame(frameForCard(at: index + 1))
            animator.applyScaleAnimation(
                card,
                scale: cardParameters.scale,
                frame: cardParameters.frame,
                duration: defaultBackgroundCardFrameAnimationDuration,
                completion: nil
            )
        }
    }

    private func loadMissingCards(_ missingCardsCount: Int) {
        guard missingCardsCount > 0 else { return }
      
        let cardsToAdd = min(missingCardsCount, countOfCards - currentCardIndex)
        let startIndex = visibleCards.count
        let endIndex = startIndex + cardsToAdd - 1

        for index in startIndex...endIndex {
          let nextCardView = generateCard(frameForTopCard())
          layoutCard(nextCardView, at: index)
          nextCardView.alpha = shouldTransparentizeNextCard ? alphaValueSemiTransparent : alphaValueOpaque

          visibleCards.append(nextCardView)
          configureCard(nextCardView, at: currentCardIndex + index)
          if index > 0 {
            insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
          } else {
            insertSubview(nextCardView, at: 0)
          }
        }
    }

    private func reconfigureCards() {
        if dataSource != nil {
            for (index, card) in visibleCards.enumerated() {
                let actualIndex = currentCardIndex + index
                configureCard(card, at: actualIndex)
            }
        }
    }
    
    private func missingCardsCount() -> Int {
        return min(countOfVisibleCards - visibleCards.count, countOfCards - (currentCardIndex + visibleCards.count))
    }
    
    // MARK: Public
    
    public func reloadData() {
        guard let numberOfCards = dataSource?.kolodaNumberOfCards(self), numberOfCards > 0 else {
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

    public func swipe(_ direction: SwipeResultDirection, force: Bool = false) {
        let shouldSwipe = delegate?.koloda(self, shouldSwipeCardAt: currentCardIndex, in: direction) ?? true
        guard force || shouldSwipe else {
            return
        }
        
        let validDirection = delegate?.koloda(self, allowedDirectionsForIndex: currentCardIndex).contains(direction) ?? true
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
    
    public func viewForCard(at index: Int) -> UIView? {
        if visibleCards.count + currentCardIndex > index && index >= currentCardIndex {
            return visibleCards[index - currentCardIndex].contentView
        } else {
            return nil
        }
    }

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if !shouldPassthroughTapsWhenNoVisibleCards {
            return super.point(inside: point, with: event)
        }
        
        if super.point(inside: point, with: event) {
            return visibleCards.count > 0
        }
        else {
            return false
        }
    }
    
    // MARK: Cards managing - Insertion
    
    private func insertVisibleCardsWithIndexes(_ visibleIndexes: [Int]) -> [DraggableCardView] {
        var insertedCards: [DraggableCardView] = []
        visibleIndexes.forEach { insertionIndex in
            let card = createCard(at: insertionIndex)
            let visibleCardIndex = insertionIndex - currentCardIndex
            visibleCards.insert(card, at: visibleCardIndex)
            if visibleCardIndex == 0 {
                card.isUserInteractionEnabled = true
                card.alpha = alphaValueOpaque
                insertSubview(card, at: visibleCards.count - 1)
            } else {
                card.isUserInteractionEnabled = false
                card.alpha = shouldTransparentizeNextCard ? alphaValueSemiTransparent : alphaValueOpaque
                insertSubview(card, belowSubview: visibleCards[visibleCardIndex - 1])
            }
            layoutCard(card, at: visibleCardIndex)
            insertedCards.append(card)
        }
        
        return insertedCards
    }
    
    private func removeCards(_ cards: [DraggableCardView]) {
        cards.forEach { card in
            card.delegate = nil
            card.removeFromSuperview()
        }
    }
    
    private func removeCards(_ cards: [DraggableCardView], animated: Bool) {
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
    
    public func insertCardAtIndexRange(_ indexRange: CountableRange<Int>, animated: Bool = true) {
        guard let dataSource = dataSource else {
            return
        }
        
        let currentItemsCount = countOfCards
        countOfCards = dataSource.kolodaNumberOfCards(self)
        
        let visibleIndexes = [Int](indexRange).filter { $0 >= currentCardIndex && $0 < currentCardIndex + countOfVisibleCards }
        let insertedCards = insertVisibleCardsWithIndexes(visibleIndexes.sorted())
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
        
        assert(
            currentItemsCount + indexRange.count == countOfCards,
            "Cards count after update is not equal to data source count"
        )
    }
    
    // MARK: Cards managing - Deletion
    
    private func proceedDeletionInRange(_ range: CountableClosedRange<Int>) {
        let deletionIndexes = [Int](range)
        deletionIndexes.sorted { $0 > $1 }.forEach { deletionIndex in
            let visibleCardIndex = deletionIndex - currentCardIndex
            let card = visibleCards[visibleCardIndex]
            card.delegate = nil
            card.swipe(.right)
            visibleCards.remove(at: visibleCardIndex)
        }
    }
    
    public func removeCardInIndexRange(_ indexRange: CountableRange<Int>, animated: Bool) {
        guard let dataSource = dataSource else {
            return
        }
        
        animating = true
        let currentItemsCount = countOfCards
        countOfCards = dataSource.kolodaNumberOfCards(self)
        let visibleIndexes = [Int](indexRange).filter { $0 >= currentCardIndex && $0 < currentCardIndex + countOfVisibleCards }
        if !visibleIndexes.isEmpty {
            proceedDeletionInRange(visibleIndexes[0]...visibleIndexes[visibleIndexes.count - 1])
        }
        currentCardIndex -= Array(indexRange).filter { $0 < currentCardIndex }.count
        loadMissingCards(missingCardsCount())
        layoutDeck()
        for (index, card) in visibleCards.enumerated() {
            card.alpha = shouldTransparentizeNextCard && index != 0 ? alphaValueSemiTransparent : alphaValueOpaque
            card.isUserInteractionEnabled = index == 0
        }
        animating = false
        
        assert(
            currentItemsCount - indexRange.count == countOfCards,
            "Cards count after update is not equal to data source count"
        )
    }
    
    // MARK: Cards managing - Reloading
    
    public func reloadCardsInIndexRange(_ indexRange: CountableRange<Int>) {
        guard dataSource != nil else {
            return
        }
        
        let visibleIndexes = [Int](indexRange).filter { $0 >= currentCardIndex && $0 < currentCardIndex + countOfVisibleCards }
        visibleIndexes.forEach { index in
            let visibleCardIndex = index - currentCardIndex
            if visibleCards.count > visibleCardIndex {
                let card = visibleCards[visibleCardIndex]
                configureCard(card, at: index)
            }
        }
    }
}
