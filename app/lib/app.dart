import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'core/ui/theme/app_theme.dart';

/// Root widget: themes follow the phone (System) until Appearance is built in M1.
class OzoneApp extends StatefulWidget {
  const OzoneApp({super.key});

  @override
  State<OzoneApp> createState() => _OzoneAppState();
}

class _OzoneAppState extends State<OzoneApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OZONE',
      debugShowCheckedModeBanner: false,
      theme: buildOzoneTheme(Brightness.light),
      darkTheme: buildOzoneTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
