import 'package:flutter/cupertino.dart';

enum Environment {
  production,
  staging,
}

class AppConfig {
  final Environment environment;

  AppConfig({required this.environment});
}
