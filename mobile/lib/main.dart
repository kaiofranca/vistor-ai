import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vistor_ai_mobile/app/app.dart';
import 'package:vistor_ai_mobile/core/di/service_locator.dart';
import 'package:vistor_ai_mobile/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase
  await Firebase.initializeApp();
  
  // Handler de background (deve estar fora de classes)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Inicializa Hive
  await Hive.initFlutter();
  
  // Service Locator
  await setupLocator();
  
  // Inicializa Notificações
  await getIt<NotificationService>().init();
  
  runApp(const VistorApp());
}
