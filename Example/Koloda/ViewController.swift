//
//  ViewController.swift
//  TinderCardsSwift
//
//  Created by Eugene Andreyev on 4/23/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit
import Koloda

private var numberOfCards: UInt = 5

class ViewController: UIViewController, CardDeckViewDataSource, CardDeckViewDelegate {
    
    @IBOutlet weak var deckView: KolodaView!
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deckView.dataSource = self
        deckView.delegate = self
    }
    
    
    //MARK: IBActions
    @IBAction func leftButtonTapped() {
        deckView?.swipeLeft()
    }
    
    @IBAction func rightButtonTapped() {
        deckView?.swipeRight()
    }
    
    @IBAction func undoButtonTapped() {
        deckView?.revertAction()
    }
    
    //MARK: CardDeckViewDataSource
    func deckNumberOfCards(deck: KolodaView) -> UInt {
        return numberOfCards
    }
    
    func deckViewForCardAtIndex(deck: KolodaView, index: UInt) -> UIView {
        return UIImageView(image: UIImage(named: "Card_like_\(index + 1)"))
    }
    func deckViewForCardOverlayAtIndex(deck: KolodaView, index: UInt) -> OverlayView? {
        return NSBundle.mainBundle().loadNibNamed("OverlayView",
            owner: self, options: nil)[0] as? OverlayView
    }
    
    //MARK: CardDeckViewDelegate
    
    func deckDidSwipedCardAtIndex(deck: KolodaView, index: UInt, direction: SwipeResultDirection) {
    //Example: loading more cards
        if index >= 3 {
            numberOfCards = 6
            deckView.reloadData()
        }
    }
    
    func deckDidRunOutOfCards(deck: KolodaView) {
    //Example: reloading
        deckView.resetCurrentCardNumber()
    }
    
    func deckDidSelectCardAtIndex(deck: KolodaView, index: UInt) {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://yalantis.com/")!)
    }
    
    func deckShouldApplyAppearAnimation(deck: KolodaView) -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

}

