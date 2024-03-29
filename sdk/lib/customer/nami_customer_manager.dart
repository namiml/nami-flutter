import 'dart:core';

import 'package:flutter/services.dart';

import 'package:nami_flutter/channel.dart';

/// Manager class which providing functionality related to managing customer/user information
class NamiCustomerManager {
  static const EventChannel _journeyStateEvent =
      const EventChannel('journeyStateEvent');

  static Stream<CustomerJourneyState> registerJourneyStateHandler() {
    var data = _journeyStateEvent
        .receiveBroadcastStream()
        .map((dynamic event) => CustomerJourneyState.fromMap(event));
    return data;
  }

  /// returns current customer's journey state
  static Future<CustomerJourneyState?> journeyState() async {
    Map<dynamic, dynamic>? map = await channel.invokeMethod("journeyState");
    if (map == null) {
      return null;
    }
    return CustomerJourneyState.fromMap(map);
  }

  static const EventChannel _accountStateEvent =
      const EventChannel('accountStateEvent');

  static Stream<AccountState> registerAccountStateHandler() {
    var data = _accountStateEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _mapToAccountState(event));

    return data;
  }

  static AccountState _mapToAccountState(Map<dynamic, dynamic> map) {
    return AccountState.fromMap(map);
  }

  /// Provide a unique identifier that is used to link different devices
  /// to the same customer in the [Nami] platform. This customer id will also
  /// be returned in any data sent from the [Nami] servers to your systems as well.
  ///
  /// The [ID] sent to Nami must be a valid [UUID] or you may hash any other
  /// identifier with [SHA256] and provide it in this call.
  ///
  /// Note that [Nami] platform will reject the [withId], and it
  /// will not get saved in case where [withId] value doesn't match
  /// a supported format.
  static Future<void> login({String withId = ""}) {
    return channel.invokeMethod("login", withId);
  }

  /// A string of the external identifier that Nami has stored. Returns [null]
  /// if no id has been stored, including if a string was passed to
  /// [login] that was not valid.
  static Future<String?> loggedInId() async {
    final String? loggedInId = await channel.invokeMethod("loggedInId");
    return loggedInId;
  }

  /// Returns whether the device is associated with an external identifier
  static Future<bool> isLoggedIn() async {
    final bool isLoggedIn = await channel.invokeMethod("isLoggedIn");
    return isLoggedIn;
  }

  /// Disassociate a device from an external id.
  static Future<void> logout() async {
    return await channel.invokeMethod("logout");
  }

  /// Provide the unique identifier that Nami uses to identifier this device.
  /// Note: this identifier does not persist across app re-installs.
  static Future<String> deviceId() async {
    final String deviceId = await channel.invokeMethod("deviceId");
    return deviceId;
  }

  static Future<void> setCustomerAttribute(Map<String, dynamic> map) async {
    return await channel.invokeMethod("setCustomerAttribute", map);
  }

  static Future<String?> getCustomerAttribute(String attributeName) async {
    final String? data =
        await channel.invokeMethod("getCustomerAttribute", attributeName);
    return data;
  }

  static Future<void> clearCustomerAttribute(String attributeName) async {
    await channel.invokeMethod("clearCustomerAttribute", attributeName);
  }

  static Future<void> clearAllCustomerAttribute() async {
    return await channel.invokeMethod("clearAllCustomerAttribute");
  }

  static Future<void> setCustomerDataPlatformId(String withId) async {
    return await channel.invokeMethod("setCustomerDataPlatformId", withId);
  }

  static Future<void> clearCustomerDataPlatformId() async {
    return await channel.invokeMethod("clearCustomerDataPlatformId");
  }

  static Future<void> setAnonymousMode(bool anonymousMode) async {
    return await channel.invokeMethod("setAnonymousMode", anonymousMode);
  }

  static Future<bool> inAnonymousMode() async {
    return await channel.invokeMethod("inAnonymousMode").then((value) => value);
  }
}

/// This data class represents a customer's subscription journey state
class CustomerJourneyState {
  final bool formerSubscriber;
  final bool inGracePeriod;
  final bool inTrialPeriod;
  final bool inIntroOfferPeriod;
  final bool isCancelled;
  final bool inPause;
  final bool inAccountHold;

  CustomerJourneyState(
      this.formerSubscriber,
      this.inGracePeriod,
      this.inTrialPeriod,
      this.inIntroOfferPeriod,
      this.isCancelled,
      this.inPause,
      this.inAccountHold);

  factory CustomerJourneyState.fromMap(Map<dynamic, dynamic> map) {
    return CustomerJourneyState(
        map['former_subscriber'],
        map['in_grace_period'],
        map['in_trial_period'],
        map['in_intro_offer_period'],
        map['is_cancelled'],
        map['in_pause'],
        map['in_account_hold']);
  }
}

// This class represents possible account state related to login/logout
class AccountState {
  final AccountStateAction accountStateAction;
  final bool success;
  final String? error;

  AccountState(this.accountStateAction, this.success, this.error);

  factory AccountState.fromMap(Map<dynamic, dynamic> map) {
    return AccountState(
        (map['accountStateAction'] as String)._toAccountStateAction(),
        map['success'],
        map['error']);
  }
}

enum AccountStateAction {
  /// The account state being required relates to [NamiCustomerManager.login]
  login,

  /// The account state being required relates to [NamiCustomerManager.logout]
  logout,
  advertising_id_set,
  advertising_id_cleared,
  vendor_id_set,
  vendor_id_cleared,
  customer_data_platform_id_set,
  customer_data_platform_id_cleared,
  nami_device_id_set,
  nami_device_id_cleared,
  anonymous_mode_on,
  anonymous_mode_off,

  /// Unknown account state
  unknown
}

extension on String {
  AccountStateAction _toAccountStateAction() {
    if (this == "login") {
      return AccountStateAction.login;
    } else if (this == "logout") {
      return AccountStateAction.logout;
    } else if (this == "advertising_id_set") {
      return AccountStateAction.advertising_id_set;
    } else if (this == "advertising_id_cleared") {
      return AccountStateAction.advertising_id_cleared;
    } else if (this == "vendor_id_set") {
      return AccountStateAction.vendor_id_set;
    } else if (this == "vendor_id_cleared") {
      return AccountStateAction.vendor_id_cleared;
    } else if (this == "customer_data_platform_id_set") {
      return AccountStateAction.customer_data_platform_id_set;
    } else if (this == "customer_data_platform_id_cleared") {
      return AccountStateAction.customer_data_platform_id_cleared;
    } else if (this == "nami_device_id_set") {
      return AccountStateAction.nami_device_id_set;
    } else if (this == "nami_device_id_cleared") {
      return AccountStateAction.nami_device_id_cleared;
    } else if (this == "anonymous_mode_on") {
      return AccountStateAction.anonymous_mode_on;
    } else if (this == "anonymous_mode_off") {
      return AccountStateAction.anonymous_mode_off;
    } else {
      return AccountStateAction.unknown;
    }
  }
}
