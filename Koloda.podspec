#
# Be sure to run `pod lib lint KolodaView.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = "Koloda"
s.version          = "1.0.0"
s.summary          = "KolodaView is a class designed to simplify the implementation of Tinder like cards on iOS. "

s.homepage         = "https://github.com/Yalantis/Koloda"
s.license          = 'MIT'
s.author           = "Yalantis"
s.source           = { :git => "https://github.com/Yalantis/Koloda.git", :tag => "1.0.1" }
s.social_media_url = 'https://twitter.com/yalantis'

s.platform     = :ios, '8.0'
s.requires_arc = true

s.source_files = 'Pod/Classes/**/*'

s.frameworks = 'UIKit'
s.dependency 'pop', '~> 1.0'
end
