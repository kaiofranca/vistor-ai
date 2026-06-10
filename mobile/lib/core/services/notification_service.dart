import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:vistor_ai_mobile/app/router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // O Firebase já é inicializado no main.dart, mas isolates de background
  // podem precisar de inicialização dependendo da versão do plugin.
  if (kDebugMode) {
    print("🔔 Mensagem em background: ${message.messageId}");
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // 1. Solicitar permissões (iOS/Android 13+)
    await requestPermission();

    // 2. Ouvir mensagens com app em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleForegroundMessage(message);
    });

    // 3. Ouvir cliques em notificações com app em background/suspenso
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });

    // 4. Verificar se o app foi aberto via notificação (estava encerrado)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Pequeno delay para garantir que o roteador está pronto
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClick(initialMessage);
      });
    }
  }

  Future<void> requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      if (kDebugMode) print('❌ Erro FCM Token: $e');
      return null;
    }
  }

  void handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📩 Mensagem em foreground: ${message.data}');
    }
    // A restrição impede o uso de flutter_local_notifications.
    // O sistema operacional não exibe banners em foreground por padrão.
    // O usuário verá os dados atualizados via streams (SyncManager).
  }

  void _handleNotificationClick(RemoteMessage message) {
    final inspectionId = message.data['inspection_id'];
    if (inspectionId != null) {
      final context = GetItNavigator.navigatorKey.currentContext;
      if (context != null) {
        context.push(AppRoutes.inspection(inspectionId));
      }
    }
  }
}
