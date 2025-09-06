Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "1.0.0"
  spec.summary      = "AdChain SDK for iOS - Complete advertising and offerwall solution"
  spec.description  = <<-DESC
                       AdChain SDK provides a complete advertising solution including:
                       - Offerwall integration with WebView
                       - Quiz and Mission systems
                       - Native ad support
                       - Hub for centralized features
                       - Complete JavaScript bridge for web integration
                       DESC
  
  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  
  spec.platform     = :ios, "14.0"
  spec.ios.deployment_target = "14.0"
  
  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios.git", :tag => "#{spec.version}" }
  
  spec.source_files = "AdchainSDK/Sources/**/*.{swift,h,m}"
  spec.exclude_files = "AdchainSDK/Sources/Exclude"
  
  spec.frameworks = "UIKit", "Foundation", "WebKit", "AdSupport", "AppTrackingTransparency"
  
  spec.swift_version = "5.5"
  spec.requires_arc = true
  
  spec.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.5',
    'ENABLE_BITCODE' => 'NO'
  }
end