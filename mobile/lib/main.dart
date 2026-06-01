import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vistor_ai_mobile/app/app.dart';

Future<void> setup() async {
  // Service locator stub
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Hive
  await Hive.initFlutter();
  
  // Service Locator
  await setup();
  
  runApp(const VistorApp());
}
