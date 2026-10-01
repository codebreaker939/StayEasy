import 'package:flutter/material.dart';

import '../core/theme/stayeasy_theme.dart';
import 'router/app_router.dart';

class StayEasyApp extends StatelessWidget {
  const StayEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'StayEasy',
      theme: StayEasyTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
