import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/app_shell.dart';
import 'theme/app_colors.dart';

void main() {
  // BrowserContextMenu needs the widgets binding set up before it can talk
  // to the platform channel - runApp() would do this on its own, but only
  // after this call, so it must be requested explicitly here first.
  WidgetsFlutterBinding.ensureInitialized();
  // The right-click "cancel/delete drawing" gesture needs the browser's own
  // context menu out of the way, or it would pop up over the app instead.
  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }
  // The pitch is far too wide to read in portrait, so phones/tablets run
  // this app landscape-only - mirrors android/AndroidManifest.xml's
  // screenOrientation and ios/Info.plist's UISupportedInterfaceOrientations,
  // which already restrict launch orientation at the OS level; this call
  // additionally locks rotation while the app is running.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FC Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.red,
          brightness: Brightness.dark,
        ).copyWith(surface: AppColors.charcoal, secondary: AppColors.taupe),
        scaffoldBackgroundColor: AppColors.appBackground,
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 1,
        ),
      ),
      home: const AppShell(),
    );
  }
}
