KolodaView
--------------

[![Yalantis](https://raw.githubusercontent.com/Yalantis/PullToMakeSoup/master/PullToMakeSoupDemo/Resouces/badge_dark.png)](http://Yalantis.com/?utm_source=github)

Check this [article on our blog](https://yalantis.com/blog/how-we-built-tinder-like-koloda-in-swift/). 
And another one [article on our blog](https://yalantis.com/blog/koloda-tinder-like-animation-version-2-prototyping-in-pixate-and-development-in-swift/)

![Preview](https://github.com/Yalantis/Koloda/blob/master/Koloda_v2_example_animation.gif)
![Preview](https://github.com/Yalantis/Koloda/blob/master/Koloda_v1_example_animation.gif)

Purpose
--------------

KolodaView is a class designed to simplify the implementation of Tinder like cards on iOS. It adds convenient functionality such as a UITableView-style dataSource/delegate interface for loading views dynamically, and efficient view loading, unloading .

Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 9.0 (Xcode 7)


ARC Compatibility
------------------

KolodaView requires ARC. 

Сocoapods version
------------------

```ruby
pod 'Koloda', '~> 2.0.3'
```

Thread Safety
--------------

KolodaView is subclassed from UIView and - as with all UIKit components - it should only be accessed from the main thread. You may wish to use threads for loading or updating KolodaView contents or items, but always ensure that once your content has loaded, you switch back to the main thread before updating the KolodaView.

Installation
--------------
To install via CocoaPods add this line to your Podfile
```ruby
use_frameworks!
pod "Koloda"
```

To install manually the KolodaView class in an app, just drag the KolodaView, DraggableCardView, OverlayView class files (demo files and assets are not needed) into your project. Also you need to install facebook-pop. Or add bridging header if you are using CocoaPods.


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
    public var currentCardNumber
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
This reloads all KolodaView item views from the dataSource and refreshes the display.
```swift
	func revertAction()
```	
Applies undo animation and decrement currentCardNumber.
```swift
	func applyAppearAnimation()
```
Applies appear animation.
```swift
	func swipeLeft() 
```
Applies swipe left animation and action, increment currentCardNumber.
```swift
	func swipeRight()
```
Applies swipe right animation and action, increment currentCardNumber.

```swift
    public func frameForCardAtIndex(index: UInt) -> CGRect 
```
Calculates frames for cards. Useful for overriding. See example to learn more about it.

Protocols
---------------

The KolodaView follows the Apple convention for data-driven views by providing two protocol interfaces, KolodaViewDataSource and KolodaViewDelegate. The KolodaViewDataSource protocol has the following methods:
```swift
	func kolodaNumberOfCards(koloda: KolodaView) -> UInt
```
Return the number of items (views) in the KolodaView.
```swift
	func kolodaViewForCardAtIndex(koloda: KolodaView, index: UInt) -> UIView
```
Return a view to be displayed at the specified index in the KolodaView. 
```swift
   func kolodaViewForCardOverlayAtIndex(koloda: KolodaView, index: UInt) -> OverlayView?
```   
Return a view for card overlay at the specified index. For setting custom overlay action on swiping(left/right), you should override didSet of overlayState property in OverlayView. (See Example)

The KolodaViewDelegate protocol has the following methods:
```swift    
    func kolodaDidSwipedCardAtIndex(koloda: KolodaView,index: UInt, direction: SwipeResultDirection)
```    
This method is called whenever the KolodaView swipes card. It is called regardless of whether the card was swiped programatically or through user interaction.
```swift
    func kolodaDidRunOutOfCards(koloda: KolodaView)
```    
This method is called when the KolodaView has no cards to display.
```swift
	func kolodaDidSelectCardAtIndex(koloda: KolodaView, index: UInt)
```
This method is called when one of cards is tapped.
```swift
    func kolodaShouldApplyAppearAnimation(koloda: KolodaView) -> Bool
```
This method is fired on reload, when any cards are displayed. If you return YES from the method, the koloda will apply appear animation.
```swift
    func kolodaShouldMoveBackgroundCard(koloda: KolodaView) -> Bool
```
This method is fired on start of front card swipping. If you return YES from the method, the koloda will move background card with dragging of front card.
```swift
    func kolodaShouldTransparentizeNextCard(koloda: KolodaView) -> Bool
```
This method is fired on koloda's layout and after swiping. If you return YES from the method, the koloda will transparentize next card below front card.
```swift
    func kolodaBackgroundCardAnimation(koloda: KolodaView) -> POPPropertyAnimation?
```
Return a pop frame animation to be applied to backround cards after swipe. This method is fired on swipping, when any cards are displayed. If you don't return frame animation, or return nil, the koloda will apply default animation.


Release Notes
----------------

Version 2.0

- Swift 2.0 support

Version 1.1

- New delegate methods
- Fixed minor issues

Version 1.0

- Release version.

License
----------------

    The MIT License (MIT)

    Copyright © 2015 Yalantis

    Permission is hereby granted free of charge to any person obtaining a copy of this software and associated documentation files (the "Software") to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

