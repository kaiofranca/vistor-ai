import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// Stub router for app.dart to compile
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Vistor AI'))),
    ),
  ],
);
