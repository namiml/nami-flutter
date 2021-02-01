import 'dart:async';

import '../channel.dart';

/// Manager class which providing functionality related to managing customer/user information
class NamiCustomerManager {
  /// returns current customer's journey state
  static Future<CustomerJourneyState> currentCustomerJourneyState() async {
    Map<dynamic, dynamic> map = await channel.invokeMethod("currentCustomerJourneyState");
    if (map == null || map.isNotEmpty) {
      return null;
    } else {
      return CustomerJourneyState(
          map['former_subscriber'],
          map['in_grace_period'],
          map['in_trial_period'],
          map['in_intro_offer_period']);
    }
  }
}

/// This data class represents a customer's subscription journey state
class CustomerJourneyState {
  final bool formerSubscriber;
  final bool inGracePeriod;
  final bool inTrialPeriod;
  final bool inIntroOfferPeriod;

  CustomerJourneyState(this.formerSubscriber, this.inGracePeriod,
      this.inTrialPeriod, this.inIntroOfferPeriod);
}
