Pod::Spec.new do |spec|
    spec.name         = "cheq-sst-swift"
    spec.version      = "0.2.1"
    spec.summary      = "A short description of MySwiftPackage."
    spec.description  = <<-DESC
                     A longer description of MySwiftPackage in Markdown format.
                     DESC
    spec.homepage     = "https://github.com/cheq-ai/cheq-sst-swift"
    spec.license      = { :type => "APACHE", :file => "LICENSE" }
    spec.author       = { "Your Name" => "your-email@example.com" }
    spec.platform     = :ios, "14.0"
    spec.source       = { :git => "https://github.com/gautam-cheq/cheq-sst-swift.git", :tag => "#{spec.version}" }
    spec.source_files = "Sources/**/*.swift"
    spec.swift_version = "5.0"
  end
