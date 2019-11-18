Pod::Spec.new do |s|
	s.name             = 'WKKoloda'
	s.version          = '5.0.2'
	s.summary          = 'KolodaView is a class designed to simplify the implementation of Tinder like cards on iOS. '

	s.homepage         = 'https://github.com/DevilGene/WKKoloda'
	s.license          = 'MIT'
	s.author           = 'DevilGene'
	s.source           = { :git => 'https://github.com/DevilGene/WKKoloda.git', :tag => s.version }
	s.social_media_url = 'https://twitter.com/yalantis'

	s.platform     = :ios, '8.0'
	s.source_files = 'Pod/Classes/**/*'

	s.frameworks = 'UIKit'
	s.dependency 'pop', '~> 1.0'
end
