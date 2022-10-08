import 'dart:async';

import 'package:flutter/services.dart';

import '../channel.dart';

/// Manager class which providing functionality related to managing customer/user information
class NamiCustomerManager {
  static const EventChannel _journeyChangeEvent =
      const EventChannel('journeyStateEvent');

  static Stream<CustomerJourneyState> registerJourneyStateHandler() {
    var data = _journeyChangeEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _mapToCustomerJourneyState(event));

    return data;
  }

  static CustomerJourneyState _mapToCustomerJourneyState(
      Map<dynamic, dynamic> map) {
    return CustomerJourneyState.fromMap(map);
  }

  /// returns current customer's journey state
  static Future<CustomerJourneyState?> journeyState() async {
    Map<dynamic, dynamic>? map =
        await channel.invokeMethod("journeyState");
    if (map == null) {
      return null;
    }
    return CustomerJourneyState.fromMap(map);
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
  static Future<void> login(
      String withId) {
    var variableMap = {
      'withId': withId,
    };
    return channel.invokeMethod("login", variableMap);
  }

  /// A string of the external identifier that Nami has stored. Returns [null]
  /// if no id has been stored, including if a string was passed to
  /// [login] that was not valid.
  static Future<String?> loggedInId() {
    return channel.invokeMethod("loggedInId");
  }

  /// Disassociate a device from an external id.
  static Future<void> logout() {
    return channel.invokeMethod("logout");
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
