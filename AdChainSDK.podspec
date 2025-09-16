Pod::Spec.new do |spec|
  spec.name         = "AdChainSDK"
  spec.version      = "1.0.14"
  spec.summary      = "AdChain SDK for iOS - Complete advertising and offerwall solution"
  spec.description  = <<-DESC
                       AdChain SDK provides a complete advertising solution including:
                       - Offerwall integration with WebView
                       - Quiz and Mission systems
                       - Native ad support
                       - Hub for centralized features
                       - Complete JavaScript bridge for web integration
                       DESC

  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "1selfworld-labs" => "dev@1selfworld.com" }

  spec.platform     = :ios, "14.0"
  spec.ios.deployment_target = "14.0"

  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "v#{spec.version}" }

  # Use vendored framework instead of source files
  spec.vendored_frameworks = 'AdChainSDK.xcframework'

  spec.resource_bundles = {
    'AdChainSDK' => ['AdchainSDK/PrivacyInfo.xcprivacy']
  }

  spec.frameworks = "UIKit", "Foundation", "WebKit", "AdSupport", "AppTrackingTransparency"

  spec.module_name = "AdChainSDK"
  spec.swift_version = "5.5"
  spec.requires_arc = true

  spec.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.5',
    'ENABLE_BITCODE' => 'NO',
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }
end