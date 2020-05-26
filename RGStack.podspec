Pod::Spec.new do |s|

  s.name          = "RGStack"
  s.version       = "1.0"
  s.summary       = "SwiftUI View Component"
  s.description   = "This UI attempts to capture the Quibi Card Stack and the associated User Interaction."
  
  s.author        = "Robera Geleta"
  s.license       = {:type => 'MIT', :file => 'LICENSE'}
  s.homepage      = "https://github.com/terminatorover/RGStack"
  
  s.platform      = :ios, "13.0"
  s.source        = { :git => "https://github.com/terminatorover/RGStack.git", :tag => "v1.0" }
  s.frameworks    = "SwiftUI", "Foundation"
  s.source_files  = "RGStack/*.swift"
  s.module_name = "RGStack"
  s.swift_version = '4.0'
end