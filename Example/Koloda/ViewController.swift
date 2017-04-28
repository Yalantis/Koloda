//
//  ViewController.swift
//  Koloda
//
//  Created by Eugene Andreyev on 4/23/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit
import Koloda

private var numberOfCards: Int = 5

class ViewController: UIViewController {
    
    @IBOutlet weak var kolodaView: KolodaView!
    
    var dataSource: [UIImage] = []
    
    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var array: [UIImage] = []
        
        for index in 0..<numberOfCards {
            array.append(UIImage(named: "Card_like_\(index + 1)")!)
        }
        
        dataSource = array
        
        kolodaView.dataSource = self
        kolodaView.delegate = self
        
        self.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
    }
    
    
    // MARK: IBActions

    @IBAction func leftButtonTapped() {
        kolodaView?.swipe(.left)
    }
    
    @IBAction func rightButtonTapped() {
        kolodaView?.swipe(.right)
    }
    
    @IBAction func undoButtonTapped() {
        kolodaView?.revertAction()
    }
}

// MARK: KolodaViewDelegate

extension ViewController: KolodaViewDelegate {
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        
        print("ran out of cards")
        
        var allViews: [UIView] = []
        
        for each in dataSource {
            
            allViews.append(UIImageView(image: each) as UIView)
        }
        
        kolodaView.reset(cards: allViews)
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        
        print("selected card")
        
        UIApplication.shared.openURL(URL(string: "https://yalantis.com/")!)
    }

}

// MARK: KolodaViewDataSource

extension ViewController: KolodaViewDataSource {
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        return dataSource.count
    }
    
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
        return .default
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        return UIImageView(image: dataSource[Int(index)])
    }
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)?[0] as? OverlayView
    }
}

