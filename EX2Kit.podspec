#
#  Be sure to run `pod spec lint EX2Kit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "EX2Kit"
  s.version      = "0.0.1"
  s.summary      = "A short description of EX2Kit."
  s.description  = <<-DESC
  EX2Kit does stuff and things.
                   DESC

  s.license      = "MIT"
  s.homepage	 = "http://isubapp.com"
  s.author             = { "Ben Baron" => "ben@einsteinx2.com" }

  s.platform	 = :ios, "7.0"
  s.source       = { :git => "http://github.com/einsteinx2/EX2Kit.git", :tag => "#{s.version}" }

  noarc_files = "EX2Kit/Categories/Foundation/NSString/GTMNSString+HTML.m",
				"EX2Kit/Categories/UIKit/UIImage+RoundedImage.m",
				"EX2Kit/Components/EX2Reachability.m"

  s.subspec 'noarc' do |noarc|
	noarc.source_files = noarc_files
	noarc.requires_arc = false
  end

  s.subspec 'arc' do |arc|
	arc.source_files  = "EX2Kit", "EX2Kit/**/*.{h,m}"
	arc.exclude_files = noarc_files
	arc.requires_arc = true
  end



  s.framework  = "Foundation"
  s.dependency "CocoaLumberjack"
  s.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(GCC_PREPROCESSOR_DEFINITIONS) IOS=1' }

end
