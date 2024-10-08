# 3.2.2 (Aug 19, 2024)

# Changelog

- Android: Bumped Android compile sdk to 34

## Enhancements
- Support new analytics events including for video metadata
- Improve the sample app

## Updated Native SDK Dependencies

- Apple SDK v3.2.2- [Release Notes](https://github.com/namiml/nami-apple/wiki/Nami-SDK-Stable-Releases#322-aug-7-2024)
- Android SDK v3.2.2- [Release Notes](https://github.com/namiml/nami-android/wiki/Nami-SDK-Stable-Releases#322-aug-8-2024)

# 3.1.1 (Nov 8, 2023)

# Changelog

## Bug Fixes
- Update sample app with additional improvements for `NamiPaywallManager.buySkuComplete`

## Enhancements
- Support the following methods in NamiCustomerManager

  - setCustomerAttribute
  - getCustomerAttribute
  - clearCustomerAttribute
  - clearAllCustomerAttributes

# 3.1.0 (Nov 6, 2023)

#Changelog

- Update bridge to support Apple SDk 3.1.17 and Android SDK 3.1.17

## Bug Fixes
- Fix compile time errors for Android and iOS

## Enhancements
- Add NamiPaywallEvent for paywall action callback
- Implement NamiPaywallManager.buySkuComplete
- Implement NamiPaywallManager.buySkuCancel
- Add url support for NamiCampaignManager.launch
- Add Sample app example for deeplinks using url style of NamiCampaignManager.launch
- Add url style of NamiCampaignManager.isCampaignAvailable
- Add NamiPurchaseSuccessGoogle
- Demonstrate use of NamiPaywallManager.registerBuySkuHandler and NamiPaywallManager.buySkuComplete and NamiPaywallManager.buySkuCancel to sample app.

# 3.0.9 (May 15, 2023)

# Changelog

- Update bridge to support Apple SDK 3.0.9 and Android SDK 3.0.9

# 3.0.7 (Apr 20, 2023)

## Changelog

### Bugfixes

- Handle native Android launch result case LaunchCampaignResult.PurchaseChanged 
- Fix several bridge references

### Maintenance

- Update native SDK dependencies
- Improve sample app

# 3.0.0-alpha.03 (Oct 29, 2022)

## Changelog

This Nami Flutter release utilizes the following native iOS and Android SDKs.

- Apple SDK v3.0.0-rc.05 - [Release Notes](https://github.com/namiml/nami-apple/wiki/Nami-SDK-Early-Access-Releases#v300-rc05-oct-25-2022)
- Android SDK v3.0.0-alpha.10 - [Release Notes](https://github.com/namiml/nami-android/wiki/Nami-SDK-Early-Access-Releases#v300-alpha10-october-25-2022)

### Bugfixes

- Resolve `dart analyze` warnings

### Maintenance

- Improve project CI/CD workflow

# 3.0.0-alpha.02 (Oct 25, 2022)

## Changelog

This Nami Flutter release utilizes the following native iOS and Android SDKs.

- Apple SDK v3.0.0-rc.05 - [Release Notes](https://github.com/namiml/nami-apple/wiki/Nami-SDK-Early-Access-Releases#v300-rc05-oct-25-2022)
- Android SDK v3.0.0-alpha.10 - [Release Notes](https://github.com/namiml/nami-android/wiki/Nami-SDK-Early-Access-Releases#v300-alpha10-october-25-2022)

### Bugfixes

- Resolve campaign launch on iOS when analytics handler registered
- Resolve SKU reference crash on Android

### Enhancements

- Includes a more robust sample app in `example/testnami`

# 3.0.0-alpha.01 (Oct 14, 2022)

## Changelog

The first Nami Flutter release incorporating the 3.x series of iOS and Android SDKs.

- Apple SDK v3.0.0-rc.03 - [Release Notes](https://github.com/namiml/nami-apple/wiki/Nami-SDK-Early-Access-Releases#v300-rc03-sep-30-2022)
- Android SDK v3.0.0-alpha.07 - [Release Notes](https://github.com/namiml/nami-android/wiki/Nami-SDK-Early-Access-Releases#v300-alpha07-september-30-2022)

### New Features

- Support for a growing library of native paywall templates
- Support for paywall A/B testing
- and much more!  See iOS and Android release notes for more details

### Enhancements

- Improved support for registered users
- Simplified API interfaces, error handling, and more
- Implements Nami's V3 API specification
