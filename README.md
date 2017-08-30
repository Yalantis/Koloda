KolodaView [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![Swift 3.0.x](https://img.shields.io/badge/Swift-3.0.x-orange.svg)
--------------

[![Yalantis](https://raw.githubusercontent.com/Yalantis/PullToMakeSoup/master/PullToMakeSoupDemo/Resouces/badge_dark.png)](https://Yalantis.com/?utm_source=github)

Check this [article on our blog](https://yalantis.com/blog/how-we-built-tinder-like-koloda-in-swift/).
And another one [article on our blog](https://yalantis.com/blog/koloda-tinder-like-animation-version-2-prototyping-in-pixate-and-development-in-swift/)

![Preview](https://github.com/Yalantis/Koloda/blob/master/Koloda_v2_example_animation.gif)
![Preview](https://github.com/Yalantis/Koloda/blob/master/Koloda_v1_example_animation.gif)

Purpose
--------------

KolodaView is a class designed to simplify the implementation of Tinder like cards on iOS. It adds convenient functionality such as a UITableView-style dataSource/delegate interface for loading views dynamically, and efficient view loading, unloading .

Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 9.0 (Xcode 7.3)

ARC Compatibility
------------------

KolodaView requires ARC.

Сocoapods version
------------------

```ruby
pod 'Koloda', '~> 4.0'
```

Thread Safety
--------------

KolodaView is subclassed from UIView and - as with all UIKit components - it should only be accessed from the main thread. You may wish to use threads for loading or updating KolodaView contents or items, but always ensure that once your content has loaded, you switch back to the main thread before updating the KolodaView.

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

##Usage

1. Import `Koloda` module to your `MyKolodaViewController` class

    ```swift
    import Koloda
    ```
2. Add `KolodaView` to `MyKolodaViewController`, then set dataSource and delegate for it
    ```swift
    class ViewController: UIViewController {
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
        func kolodaDidRunOutOfCards(koloda: KolodaView) {
            dataSource.reset()
        }

        func koloda(koloda: KolodaView, didSelectCardAt index: Int) {
            UIApplication.sharedApplication().openURL(NSURL(string: "https://yalantis.com/")!)
        }
    }
    ```
4. Conform `MyKolodaViewController` to `KolodaViewDataSource` protocol and implement all the methods , e.g.
    ```swift
    extension MyKolodaViewController: KolodaViewDataSource {

        func kolodaNumberOfCards(koloda:KolodaView) -> Int {
            return images.count
        }

        func koloda(koloda: KolodaView, viewForCardAt index: Int) -> UIView {
            return UIImageView(image: images[index])
        }

        func koloda(koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
            return NSBundle.mainBundle().loadNibNamed("OverlayView",
                owner: self, options: nil)[0] as? OverlayView
        }
    }
    ```
5. `KolodaView` works with default implementation. Override it to customize its behavior

Also check out [an example project with carthage](https://github.com/serejahh/Koloda-Carthage-usage).

Properties
--------------

The KolodaView has the following properties:
```swift
weak var dataSource: KolodaViewDataSource!
```
An object that supports the KolodaViewDataSource protocol and can provide views to populate the KolodaView.
```swift
weak var delegate: KolodaViewDelegate?
```
An object that supports the KolodaViewDelegate protocol and can respond to KolodaView events.
```swift
public var currentCardIndex
```
The index of front card in the KolodaView (read only).
```swift
public var countOfCards
```
The count of cards in the KolodaView (read only). To set this, implement the `kolodaNumberOfCards:` dataSource method.
```swift
var countOfVisibleCards
```
The count of displayed cards in the KolodaView.
Methods
--------------

The KolodaView class has the following methods:
```swift
func reloadData()
```

This method reloads all KolodaView item views from the dataSource and refreshes the display.
```swift
func resetCurrentCardNumber()
```

This method resets currentCardNumber and calls reloadData, so KolodaView loads from the beginning.
```swift
func revertAction()
```
Applies undo animation and decrement currentCardNumber.
```swift
func applyAppearAnimation()
```
Applies appear animation.
```swift
func swipe(.left)
```
Applies swipe left animation and action, increment currentCardNumber.
```swift
func swipe(.right)
```
Applies swipe right animation and action, increment currentCardNumber.

```swift
public func frameForCardAtIndex(index: Int) -> CGRect
```
Calculates frames for cards. Useful for overriding. See example to learn more about it.

Protocols
---------------

The KolodaView follows the Apple convention for data-driven views by providing two protocol interfaces, KolodaViewDataSource and KolodaViewDelegate. The KolodaViewDataSource protocol has the following methods:
```swift
func koloda(kolodaNumberOfCards koloda: KolodaView) -> Int
```
Return the number of items (views) in the KolodaView.
```swift
func koloda(koloda: KolodaView, viewForCardAt index: Int) -> UIView
```
Return a view to be displayed at the specified index in the KolodaView.
```swift
func koloda(koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView?
```
Return a view for card overlay at the specified index. For setting custom overlay action on swiping(left/right), you should override didSet of overlayState property in OverlayView. (See Example)

The KolodaViewDelegate protocol has the following methods:
```swift
func koloda(koloda: KolodaView, allowedDirectionsForIndex index: Int) -> [SwipeResultDirection]
```
Return the allowed directions for a given card, defaults to `[.left, .right]`
```swift
func koloda(koloda: KolodaView, shouldSwipeCardAt index: Int, in direction: SwipeResultDirection) -> Bool
```
This method is called before the KolodaView swipes card. Return `true` or `false` to allow or deny the swipe.

```swift
func koloda(koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection)
```
This method is called whenever the KolodaView swipes card. It is called regardless of whether the card was swiped programatically or through user interaction.
```swift
func kolodaDidRunOutOfCards(koloda: KolodaView)
```
This method is called when the KolodaView has no cards to display.
```swift
func koloda(koloda: KolodaView, didSelectCardAt index: Int)
```
This method is called when one of cards is tapped.
```swift
func kolodaShouldApplyAppearAnimation(koloda: KolodaView) -> Bool
```
This method is fired on reload, when any cards are displayed. If you return YES from the method or don't implement it, the koloda will apply appear animation.
```swift
func kolodaShouldMoveBackgroundCard(koloda: KolodaView) -> Bool
```
This method is fired on start of front card swipping. If you return YES from the method or don't implement it, the koloda will move background card with dragging of front card.
```swift
func kolodaShouldTransparentizeNextCard(koloda: KolodaView) -> Bool
```
This method is fired on koloda's layout and after swiping. If you return YES from the method or don't implement it, the koloda will transparentize next card below front card.
```swift
func koloda(koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, in direction: SwipeResultDirection)
```
This method is called whenever the KolodaView recognizes card dragging event.
```swift
func kolodaSwipeThresholdRatioMargin(koloda: KolodaView) -> CGFloat?
```
Return the percentage of the distance between the center of the card and the edge at the drag direction that needs to be dragged in order to trigger a swipe. The default behavior (or returning NIL) will set this threshold to half of the distance
```swift
func kolodaDidResetCard(koloda: KolodaView)
```
This method is fired after resetting the card.
```swift
func koloda(koloda: KolodaView, didShowCardAt index: Int)
```
This method is called after a card has been shown, after animation is complete
```swift
func koloda(koloda: KolodaView, shouldDragCardAt index: Int) -> Bool
```
This method is called when the card is beginning to be dragged. If you return YES from the method or
don't implement it, the card will move in the direction of the drag. If you return NO the card will
not move.

Release Notes
----------------

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


#### Let us know!

We’d be really happy if you sent us links to your projects where you use our component. Just send an email to github@yalantis.com And do let us know if you have any questions or suggestion regarding the animation.

P.S. We’re going to publish more awesomeness wrapped in code and a tutorial on how to make UI for iOS (Android) better than better. Stay tuned!

License
----------------

The MIT License (MIT)

Copyright © 2017 Yalantis

Permission is hereby granted free of charge to any person obtaining a copy of this software and associated documentation files (the "Software") to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
