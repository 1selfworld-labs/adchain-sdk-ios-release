Pod::Spec.new do |s|
  s.name         = "AdchainSDK"
  s.version      = "1.0.0"
  s.summary      = "AdchainSDK Binary XCFramework"
  s.description  = "Compiled binary framework. No source code included."
  s.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  s.license      = { :type => "Proprietary", :text => "© 2024 1selfworld Labs" }
  s.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  s.platform     = :ios, "14.0"
  s.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "1.0.0" }
  s.vendored_frameworks = "AdchainSDK.xcframework"
  s.swift_version = "5.5"
end
