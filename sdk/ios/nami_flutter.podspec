#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'nami_flutter'
  s.version          = '3.0.0-alpha.01'
  s.summary          = 'Easy subscriptions & in-app purchases for Flutter, with powerful built-in paywalls and A/B testing.'
  s.description      = <<-DESC
  This library helps you offer subscriptions & IAPs for Flutter apps published to the App Store and Google Play.

  - No IAP code to write.
  - Focus on your app experience.
  - All edge cases are handled and no server is required.
  - Includes is powerful built-in paywalls templates, rendered via native iOS and Android UI
  - Update paywalls easily using a browser-based paywall CMS.
  - Conduct paywall A/B tests, to improve your conversion rate.
  - Robust subscription analytics, webhooks, and much more.

Requires an account with Nami. The free tier is generous and includes everything you need to get up and running.

See https://www.namiml.com for more details and to create a free account.
                       DESC
  s.homepage         = 'https://www.namiml.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'namiml' => 'hello@namiml.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.dependency 'Nami', '3.0.0-rc.03'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
