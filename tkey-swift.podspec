Pod::Spec.new do |spec|
  spec.name         = "tkey-swift"
  spec.version      = "2.0.1"
  spec.platform = :ios, "14.0"
  spec.summary      = "SDK allows you to create threshold key setup natively"
  spec.homepage     = "https://web3auth.io/"
  spec.license      = { :type => 'BSD', :file  => 'License.md' }
  spec.swift_version   = "5.3"
  spec.author       = { "Torus Labs" => "hello@tor.us" }
  spec.module_name = "tkey"
  spec.source       = { :git => "https://github.com/tkey/tkey-swift.git", :tag => spec.version }
  spec.vendored_framework = "Sources/libtkey/libtkey.xcframework"
  spec.source_files = "Sources/**/*.{swift,c,h}"
end
