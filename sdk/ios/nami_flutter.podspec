#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'nami_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Subscription and in-app purchase (IAP) marketing platform for Flutter.'
  s.description      = <<-DESC
Integrate with a few lines of code. Analytics, CRM, and create customized purchase experiences in the cloud. Generous free usage tier. 
                       DESC
  s.homepage         = 'https://www.namiml.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'namiml' => 'hello@namiml.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.dependency 'Nami', '2.7.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
