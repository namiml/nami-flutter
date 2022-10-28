import 'package:testnami/app.dart';
import 'package:testnami/app_config.dart';
import 'package:flutter/material.dart';

void main() async {
  AppConfig config = AppConfig(environment: Environment.production);
  Widget app = await initializeApp(config);
  runApp(app);
}
