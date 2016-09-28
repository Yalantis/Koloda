//
//  ViewController.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/23/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit
import Koloda

private var numberOfCards: UInt = 5

class ViewController: UIViewController {
    
    @IBOutlet weak var kolodaView: KolodaView!
    
    fileprivate var dataSource: Array<UIImage> = {
        var array: Array<UIImage> = []
        for index in 0..<numberOfCards {
            array.append(UIImage(named: "Card_like_\(index + 1)")!)
        }
        
        return array
    }()
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        kolodaView.dataSource = self
        kolodaView.delegate = self
        
        self.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
    }
    
    
    //MARK: IBActions
    @IBAction func leftButtonTapped() {
        kolodaView?.swipe(SwipeResultDirection.Left)
    }
    
    @IBAction func rightButtonTapped() {
        kolodaView?.swipe(SwipeResultDirection.Right)
    }
    
    @IBAction func undoButtonTapped() {
        kolodaView?.revertAction()
    }
}

//MARK: KolodaViewDelegate
extension ViewController: KolodaViewDelegate {
    
    func kolodaDidRunOutOfCards(koloda: KolodaView) {
        dataSource.insert(UIImage(named: "Card_like_6")!, at: kolodaView.currentCardIndex - 1)
        let position = kolodaView.currentCardIndex
//        let range = CountableClosedRange()v
//        range.lowerBound = position
        kolodaView.insertCardAtIndexRange(position ... position, animated: true)
    }
    
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt) {
        UIApplication.shared.openURL(NSURL(string: "http://yalantis.com/")! as URL)
    }
}

//MARK: KolodaViewDataSource
extension ViewController: KolodaViewDataSource {
    
    func kolodaNumberOfCards(_ koloda:KolodaView) -> UInt {
        return UInt(dataSource.count)
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView {
        return UIImageView(image: dataSource[Int(index)])
    }
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView",
            owner: self, options: nil)?[0] as? OverlayView
    }
}

