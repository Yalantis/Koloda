

Pod::Spec.new do |s|
s.name             = "Koloda"
s.version          = "1.1.2"
s.summary          = "KolodaView is a class designed to simplify the implementation of Tinder like cards on iOS. "

s.homepage         = "https://github.com/Yalantis/Koloda"
s.license          = 'MIT'
s.author           = "Yalantis"
s.source           = { :git => "https://github.com/Yalantis/Koloda.git", :tag => "1.1.2" }
s.social_media_url = 'https://twitter.com/yalantis'

s.platform     = :ios, '8.0'
s.requires_arc = true

s.source_files = 'Pod/Classes/**/*'

s.frameworks = 'UIKit'
s.dependency 'pop', '~> 1.0'
end
