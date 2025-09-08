Pod::Spec.new do |s|
  s.name         = "AdchainSDK"
  s.version      = "1.0.1"
  s.summary      = "AdChain SDK for iOS - Complete advertising and offerwall solution"
  s.description  = <<-DESC
                    AdChain SDK provides a complete advertising solution including:
                    - Offerwall integration with WebView
                    - Quiz and Mission systems
                    - Native ad support
                    - Hub for centralized features
                    - Complete JavaScript bridge for web integration
                    DESC
  s.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  s.platform     = :ios, "14.0"
  s.ios.deployment_target = "14.0"
  s.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "#{s.version}" }
  s.vendored_frameworks = "AdchainSDK.xcframework"
  s.frameworks = "UIKit", "Foundation", "WebKit", "AdSupport", "AppTrackingTransparency"
  s.swift_version = "5.5"
  s.requires_arc = true
end
