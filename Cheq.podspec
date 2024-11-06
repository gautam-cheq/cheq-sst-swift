Pod::Spec.new do |spec|
    spec.name         = "Cheq"
    spec.version      = "0.2.1"
    spec.summary      = "CHEQ Swift Server-Side Tagging (SST)"
    spec.description  = "CHEQ Swift Server-Side Tagging (SST)"
    spec.homepage     = "https://github.com/cheq-ai/cheq-sst-swift"
    spec.license      = { :type => "APACHE", :file => "LICENSE" }
    spec.author       = "CHEQ"
    spec.platform     = :ios, "14.0"
    spec.source       = { :git => "https://github.com/gautam-cheq/cheq-sst-swift.git", :tag => "#{spec.version}" }
    spec.source_files = "Sources/**/*.swift"
    spec.swift_version = "5.0"
    spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '' }
  end
