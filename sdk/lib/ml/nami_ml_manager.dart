import '../channel.dart';

class NamiMLManager {
  /// Inform `Nami` platform about an important actions a user has taken in
  /// your app. This is to train and improve the performance of the machine
  /// learning.
  static Future<void> coreAction(String label) {
    return channel.invokeMethod("coreAction", label);
  }

  /// Inform `Nami` platform when a user starts consuming content that is core
  /// to your app experience.
  ///
  /// [labels] is a list of strings where the list is ordered by the
  /// relationship of the content, such as ["video", "basketball", "michael
  /// jordan"]. Note that the **exact same labels list** must be used in both
  /// [enterCoreContent] and [exitCoreContent] calls as they both combined make
  /// one complete entry of core content experience
  /// `Note` to only send more than one label in list when they're structured.
  /// Nami assumes this list is ordered with the larger category being the
  /// first element of the list and the smallest category being the final
  /// element in the list. Under the hood Nami uses these inputs to build a
  /// tree of related concepts.
  static Future<void> enterCoreContent(List<String> labels) {
    return channel.invokeMethod("enterCoreContent", labels);
  }

  /// Inform `Nami` platform when a user finished consuming content that is
  /// core to your app experience.
  ///
  /// [labels] is a list of strings where the list is ordered by the
  /// relationship of the content, such as ["video", "basketball", "michael
  /// jordan"]. Note that the **exact same labels list** must be used in
  /// both [enterCoreContent] and [exitCoreContent] calls as they both combined
  /// make one complete entry of core content experience
  static Future<void> exitCoreContent(List<String> labels) {
    return channel.invokeMethod("exitCoreContent", labels);
  }
}
