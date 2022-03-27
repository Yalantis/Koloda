KolodaView ![cocoapods](https://img.shields.io/cocoapods/v/Koloda.svg)[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)
--------------

[![Yalantis](https://raw.githubusercontent.com/Yalantis/PullToMakeSoup/master/PullToMakeSoupDemo/Resouces/badge_dark.png)](https://Yalantis.com/?utm_source=github)

Our designer Dmitry Goncharov decided to create an animation that follows Tinder’s trend. We called our Tinder-style card-based animation Koloda which is a Ukrainian word for the deck (of cards).
The component can be used in different local event apps, and even in Tinder if it adds a possibility to choose dating places. The concept created by Dmitriy was implemented by Eugene Andreyev, our iOS developer.

![Preview](https://github.com/Yalantis/Koloda/blob/master/Koloda_v2_example_animation.gif)
![Preview](https://github.com/Yalantis/Koloda/blob/master/Koloda_v1_example_animation.gif)

Purpose
--------------

KolodaView is a class designed to simplify the implementation of Tinder like cards on iOS. It adds convenient functionality such as a UITableView-style dataSource/delegate interface for loading views dynamically, and efficient view loading, unloading .

Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 11.0 (Xcode 9)

ARC Compatibility
------------------

KolodaView requires ARC.

Thread Safety
--------------

KolodaView is subclassed from UIView and - as with all UIKit components - it should only be accessed from the main thread. You may wish to use threads for loading or updating KolodaView contents or items, but always ensure that once your content has loaded, you switch back to the main thread before updating the KolodaView.

Prototype of Koloda in Pixate
--------------

Our designer created the mock-up in Photoshop and used [Pixate](http://www.pixate.com) for prototyping Koloda. The prototype we created reproduced the behavior of cards exactly how we wanted it.

The main Pixate toolset includes layers, an action kit, and animations. After the assets are loaded and located on the artboard, you can start working on layers, and then proceed to reproduce interactions.

At first, we made the cards move horizontally and fly away from the screen once they cross a certain vertical line. The designer also made the cards change their transparency and spin a bit during interactions.

Then, we needed to make a new card appear in a way as if it collects itself from the background, so we had to stretch and scale it. We set a scale for the prototype from 3.5x (the size, when a card is still on the background) to 1x.

![Preview](https://github.com/Yalantis/Koloda/blob/master/assets/content_tips.png)

For a better effect, we added a few bounce animations and that was it! The prototype was ready for development.

Building Koloda animation
--------------

There are a few ready-made mobile libraries and iOS animation examples out there that an app developer can use.

We wanted the animation to be as simple and convenient as views like UITableView. Therefore, we created a custom component for the animation. It consists of the three main parts:

1. `DraggableCardView` – a card that displays content.
2. `OverlayView` – a dynamic view that changes depending on where a user drags a card (to the left or to the right).
3. `KolodaView` – a view that controls loading and interactions between cards.

DraggableCardView implementation
--------------

We implemented DraggableCardView with the help of `UIPanGestureRecognizer` and `CGAffineTransform`. See the coding part below:

```swift
func panGestureRecognized(gestureRecognizer: UIPanGestureRecognizer) {
    xDistanceFromCenter = gestureRecognizer.translationInView(self).x
    yDistanceFromCenter = gestureRecognizer.translationInView(self).y

    let touchLocation = gestureRecognizer.locationInView(self)
    switch gestureRecognizer.state {
    case .Began:
        originalLocation = center

        animationDirection = touchLocation.y >= frame.size.height / 2 ? -1.0 : 1.0      
        layer.shouldRasterize = true
        break

    case .Changed:

        let rotationStrength = min(xDistanceFromCenter! / self.frame.size.width, rotationMax)
        let rotationAngle = animationDirection! * defaultRotationAngle * rotationStrength
        let scaleStrength = 1 - ((1 - scaleMin) * fabs(rotationStrength))
        let scale = max(scaleStrength, scaleMin)

        layer.rasterizationScale = scale * UIScreen.mainScreen().scale
 
        let transform = CGAffineTransformMakeRotation(rotationAngle)
        let scaleTransform = CGAffineTransformScale(transform, scale, scale)

        self.transform = scaleTransform
        center = CGPoint(x: originalLocation!.x + xDistanceFromCenter!, y: originalLocation!.y + yDistanceFromCenter!)
           
        updateOverlayWithFinishPercent(xDistanceFromCenter! / frame.size.width)
        //100% - for proportion
        delegate?.cardDraggedWithFinishPercent(self, percent: min(fabs(xDistanceFromCenter! * 100 / frame.size.width), 100))

        break
    case .Ended:
        swipeMadeAction()

        layer.shouldRasterize = false
    default:
        break
    }
}
```

The overlay gets updated with every move. It changes transparency in the process of animation ( 5% –  hardly seen, 100% – clearly seen).

In order to avoid a card’s edges becoming sharp during movement, we used the `shouldRasterize` layer option.

We had to consider a reset situation which happens once a card fails to reach the action margin (ending point) and comes back to the initial state. We used the Facebook Pop framework for this situation, and also for the “undo” action.

OverlayView implementation
--------------

`OverlayView` is a view that is added on top of a card during animation. It has only one variable called `overlayState` with two options: when a user drags a card to the left, the `overlayState` adds a red hue to the card, and when a card is moved to the right, the variable uses the other option to make the UI become green.

To implement custom actions for the overlay, we should inherit from `OverlayView`, and reload the operation `didSet` in the `overlayState`:

```swift
public enum OverlayMode{
   case None
   case Left
   case Right
}

public class OverlayView: UIView {
    public var overlayState:OverlayMode = OverlayMode.None
}

class ExampleOverlayView: OverlayView {
override var overlayState:OverlayMode  {
    didSet {
        switch overlayState {
           case .Left :
               overlayImageView.image = UIImage(named: overlayLeftImageName)
           case .Right :
               overlayImageView.image = UIImage(named: overlayRightImageName)
           default:
               overlayImageView.image = nil
           }          

       }

   }

}
```

KolodaView implementation
--------------

The `KolodaView` class does a card loading and card management job. You can either implement it in the code or in the Interface Builder. Then, you should specify a data source and add a delegate (optional). After that, you should implement the following methods of the `KolodaViewDataSource` protocol in the data source-class:

```swift
func kolodaNumberOfCards(koloda: KolodaView) -> UInt
    func kolodaViewForCardAtIndex(koloda: KolodaView, index: UInt) -> UIView
    func kolodaViewForCardOverlayAtIndex(koloda: KolodaView, index: UInt) -> OverlayView?
```

`KolodaView` had to display a correct number of cards below the top card and make them occupy the right positions when the animation starts. To make it possible, we had to calculate frames for all the cards by adding the corresponding indexes to each element. For example, the first card has an [i] index, the second one would have an [i+1] index, the third – [i+2], and so on:

```swift
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
```

Now, since we know the indexes, card frames, and also the percent at which the animation ends (from the `DraggableCardView`), we can easily find out where the cards below will go once an upper card is swiped. After that, we can implement `PercentDrivenAnimation`.

Building Koloda v.2
--------------

The main difference between the first and second versions of the Koloda animation is in the cards’ layout. The front card in the new version is placed in the middle of the screen and the back card is stretched on the background. In addition, the back card does not respond to the movement of the front card and arrives with a bounce effect after the front card is swiped.

Also, the second version of Koloda was easier to build thanks to the prototype of it in Pixate.

![Preview](https://github.com/Yalantis/Koloda/blob/master/Koloda_v1_example_animation.gif)

Implementation of KolodaView v.2
--------------

To implement KolodaView v.2, we had to place the cards differently, so we put the method `frameForCardAtIndex` in the public interface.

In `KolodaView` inheritor we overrode the method and put the cards in the following order:

```swift
override func frameForCardAtIndex(index: UInt) -> CGRect {
    if index == 0 {
        let bottomOffset:CGFloat = defaultBottomOffset
        let topOffset:CGFloat = defaultTopOffset
        let xOffset:CGFloat = defaultHorizontalOffset
        let width = CGRectGetWidth(self.frame ) - 2 * defaultHorizontalOffset
        let height = width * defaultHeightRatio
        let yOffset:CGFloat = topOffset
        let frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        return frame
    } else if index == 1 {
        let horizontalMargin = -self.bounds.width * backgroundCardHorizontalMarginMultiplier
        let width = self.bounds.width * backgroundCardScalePercent
        let height = width * defaultHeightRatio
        return CGRect(x: horizontalMargin, y: 0, width: width, height: height)
    }
    return CGRectZero
}
```

We place `frontCard` in the middle of `KolodaView`, and stretch the background card with a scalePercent that equals 1.5.

![Preview](https://github.com/Yalantis/Koloda/blob/master/assets/states.jpeg)

Bounce animation for the background card
--------------

Since the background card arrives with a bounce effect and changes its transparency while moving, we created a new delegate method:

```swift
KolodaView - func kolodaBackgroundCardAnimation(koloda: KolodaView) -> POPPropertyAnimation?
```

In this method, `POPAnimation` is created and passed to Koloda. Then, Koloda uses it for animating frame changes after a user swipes a card. If the delegate returns `nil`, it means that Koloda uses default animation.

Below you can see the implementation of this method in the delegate:

```swift
func kolodaBackgroundCardAnimation(koloda: KolodaView) -> POPPropertyAnimation? {
    let animation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
    animation.springBounciness = frameAnimationSpringBounciness
    animation.springSpeed = frameAnimationSpringSpeed
    return animation
}
```

Installation
--------------
To install via CocoaPods add this lines to your Podfile. You need CocoaPods v. 1.1 or higher
```ruby
use_frameworks!
pod "Koloda"
```

To install via Carthage add this lines to your Cartfile
```ruby
github "Yalantis/Koloda"
```

To install manually the KolodaView class in an app, just drag the KolodaView, DraggableCardView, OverlayView class files (demo files and assets are not needed) into your project. Also you need to install facebook-pop. Or add bridging header if you are using CocoaPods.

Usage
--------------

1. Import `Koloda` module to your `MyKolodaViewController` class

    ```swift
    import Koloda
    ```
2. Add `KolodaView` to `MyKolodaViewController`, then set dataSource and delegate for it
    ```swift
    class MyKolodaViewController: UIViewController {
        @IBOutlet weak var kolodaView: KolodaView!

        override func viewDidLoad() {
            super.viewDidLoad()

            kolodaView.dataSource = self
            kolodaView.delegate = self
        }
    }
    ```
3. Conform your `MyKolodaViewController` to `KolodaViewDelegate` protocol and override some methods if you need, e.g.
    ```swift
    extension MyKolodaViewController: KolodaViewDelegate {
        func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
            koloda.reloadData()
        }

        func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
            UIApplication.shared.openURL(URL(string: "https://yalantis.com/")!)
        }
    }
    ```
4. Conform `MyKolodaViewController` to `KolodaViewDataSource` protocol and implement all the methods , e.g.
    ```swift
    extension MyKolodaViewController: KolodaViewDataSource {

        func kolodaNumberOfCards(_ koloda:KolodaView) -> Int {
            return images.count
        }

        func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
            return .fast
        }

        func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
            return UIImageView(image: images[index])
        }

        func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
            return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)[0] as? OverlayView
        }
    }
    ```
5. `KolodaView` works with default implementation. Override it to customize its behavior

Also check out [an example project with carthage](https://github.com/serejahh/Koloda-Carthage-usage).

Properties
--------------

The KolodaView has the following properties:
```swift
weak var dataSource: KolodaViewDataSource?
```
An object that supports the KolodaViewDataSource protocol and can provide views to populate the KolodaView.
```swift
weak var delegate: KolodaViewDelegate?
```
An object that supports the KolodaViewDelegate protocol and can respond to KolodaView events.
```swift
private(set) public var currentCardIndex
```
The index of front card in the KolodaView (read only).
```swift
private(set) public var countOfCards
```
The count of cards in the KolodaView (read only). To set this, implement the `kolodaNumberOfCards:` dataSource method.
```swift
public var countOfVisibleCards
```
The count of displayed cards in the KolodaView.

Methods
--------------

The KolodaView class has the following methods:
```swift
public func reloadData()
```
This method reloads all KolodaView item views from the dataSource and refreshes the display.
```swift
public func resetCurrentCardIndex()
```
This method resets currentCardIndex and calls reloadData, so KolodaView loads from the beginning.
```swift
public func revertAction()
```
Applies undo animation and decrement currentCardIndex.
```swift
public func applyAppearAnimationIfNeeded()
```
Applies appear animation if needed.
```swift
public func swipe(_ direction: SwipeResultDirection, force: Bool = false)
```
Applies swipe animation and action, increment currentCardIndex.

```swift
open func frameForCard(at index: Int) -> CGRect
```

Calculates frames for cards. Useful for overriding. See example to learn more about it.

Protocols
---------------

The KolodaView follows the Apple convention for data-driven views by providing two protocol interfaces, KolodaViewDataSource and KolodaViewDelegate.

#### The KolodaViewDataSource protocol has the following methods:
```swift
func koloda(_ kolodaNumberOfCards koloda: KolodaView) -> Int
```
Return the number of items (views) in the KolodaView.
```swift
func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView
```
Return a view to be displayed at the specified index in the KolodaView.
```swift
func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView?
```
Return a view for card overlay at the specified index. For setting custom overlay action on swiping(left/right), you should override didSet of overlayState property in OverlayView. (See Example)
```swift
func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed
```
Allow management of the swipe animation duration

#### The KolodaViewDelegate protocol has the following methods:
```swift
func koloda(_ koloda: KolodaView, allowedDirectionsForIndex index: Int) -> [SwipeResultDirection]
```
Return the allowed directions for a given card, defaults to `[.left, .right]`
```swift
func koloda(_ koloda: KolodaView, shouldSwipeCardAt index: Int, in direction: SwipeResultDirection) -> Bool
```
This method is called before the KolodaView swipes card. Return `true` or `false` to allow or deny the swipe.
```swift
func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection)
```
This method is called whenever the KolodaView swipes card. It is called regardless of whether the card was swiped programatically or through user interaction.
```swift
func kolodaDidRunOutOfCards(_ koloda: KolodaView)
```
This method is called when the KolodaView has no cards to display.
```swift
func koloda(_ koloda: KolodaView, didSelectCardAt index: Int)
```
This method is called when one of cards is tapped.
```swift
func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool
```
This method is fired on reload, when any cards are displayed. If you return YES from the method or don't implement it, the koloda will apply appear animation.
```swift
func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool
```
This method is fired on start of front card swipping. If you return YES from the method or don't implement it, the koloda will move background card with dragging of front card.
```swift
func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool
```
This method is fired on koloda's layout and after swiping. If you return YES from the method or don't implement it, the koloda will transparentize next card below front card.
```swift
func koloda(_ koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, in direction: SwipeResultDirection)
```
This method is called whenever the KolodaView recognizes card dragging event.
```swift
func kolodaSwipeThresholdRatioMargin(_ koloda: KolodaView) -> CGFloat?
```
Return the percentage of the distance between the center of the card and the edge at the drag direction that needs to be dragged in order to trigger a swipe. The default behavior (or returning NIL) will set this threshold to half of the distance
```swift
func kolodaDidResetCard(_ koloda: KolodaView)
```
This method is fired after resetting the card.
```swift
func koloda(_ koloda: KolodaView, didShowCardAt index: Int)
```
This method is called after a card has been shown, after animation is complete
```swift
func koloda(_ koloda: KolodaView, didRewindTo index: Int)
```
This method is called after a card was rewound, after animation is complete

```swift
func koloda(_ koloda: KolodaView, shouldDragCardAt index: Int) -> Bool
```
This method is called when the card is beginning to be dragged. If you return YES from the method or
don't implement it, the card will move in the direction of the drag. If you return NO the card will
not move.

Release Notes
----------------
Version 5.0.1
- added posibility to determine index of rewound card
- fixed crash after drugging card

Version 5.0
- Swift 5.0 via [@maxxfrazer](https://github.com/maxxfrazer)

Version 4.7
- fixed a bug with card responding during swiping via [@lixiang1994](https://github.com/lixiang1994)
- fixed a bug with inappropriate layouting via [@soundsmitten](https://github.com/soundsmitten)

Version 4.6
- update some properties to be publicitly settable via [@sroik](https://github.com/sroik) and [@leonardoherbert](https://github.com/leonardoherbert)
- Xcode 9 back compatibility via [@seriyvolk83](https://github.com/seriyvolk83)
- added posibility to have the card stack at the top or bottom via [@lorenzOliveto](https://github.com/lorenzOliveto)

Version 4.5
- Swift 4.2 via [@evilmint](https://github.com/evilmint)

Version 4.4
- Swift 4.1 via [@irace](https://github.com/irace)
- Added `isLoop` property via [@brownsoo](https://github.com/brownsoo)
- Take into account card's alpha channel via [@bwhtmn](https://github.com/bwhtmn)

Version 4.3
- Swift 4 support
- iOS 11 frame bugfix

Version 4.0
- Swift 3 support
- Get rid of UInt
- Common bugfix

Version 3.1

- Multiple Direction Support
- Delegate methods for swipe disabling

Version 3.0

- Ability to dynamically insert/delete/reload specific cards
- External animator
- Major refactoring. [More information](https://github.com/Yalantis/Koloda/releases/tag/3.0.0)
- Swift 2.2 support

Version 2.0

- Swift 2.0 support

Version 1.1

- New delegate methods
- Fixed minor issues

Version 1.0

- Release version.

#### Apps using KolodaView

- [BroApp](https://itunes.apple.com/ua/app/bro-social-networking-bromance/id1049979758?mt=8).

![Preview](https://github.com/Yalantis/Koloda/blob/master/Example/UsageExamples/bro.gif)
- [Storage Space Plus](https://itunes.apple.com/us/app/storage-space-plus-compress/id1086277462?mt=8).
- [Color Dating](https://itunes.apple.com/us/app/color-dating-free-app-for/id1100827439?mt=8).
- [Ao Dispor](https://itunes.apple.com/pt/app/ao-dispor/id1185556583)

#### Let us know!

We’d be really happy if you sent us links to your projects where you use our component. Just send an email to github@yalantis.com And do let us know if you have any questions or suggestion regarding the animation.

P.S. We’re going to publish more awesomeness wrapped in code and a tutorial on how to make UI for iOS (Android) better than better. Stay tuned!

License
----------------

The MIT License (MIT)

Copyright © 2019 Yalantis

Permission is hereby granted free of charge to any person obtaining a copy of this software and associated documentation files (the "Software") to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
