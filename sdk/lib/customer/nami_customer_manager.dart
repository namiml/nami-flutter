import 'dart:async';

import 'package:flutter/services.dart';

import '../channel.dart';

/// Manager class which providing functionality related to managing customer/user information
class NamiCustomerManager {
  static const EventChannel _customerJourneyChangeEvent =
      const EventChannel('customerJourneyChangeEvent');

  static Stream<CustomerJourneyState> customerJourneyChangeEvents() {
    var data = _customerJourneyChangeEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _mapToCustomerJourneyState(event));

    return data;
  }

  static CustomerJourneyState _mapToCustomerJourneyState(
      Map<dynamic, dynamic> map) {
    return CustomerJourneyState.fromMap(map);
  }

  /// returns current customer's journey state
  static Future<CustomerJourneyState?> currentCustomerJourneyState() async {
    Map<dynamic, dynamic>? map =
        await channel.invokeMethod("currentCustomerJourneyState");
    if (map == null) {
      return null;
    }
    return CustomerJourneyState.fromMap(map);
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

  factory CustomerJourneyState.fromMap(Map<dynamic, dynamic?> map) {
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
