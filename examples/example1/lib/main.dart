import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';
import 'package:logging/logging.dart';

import 'screens/home_screen.dart';

void main() {
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // BlitzWare configuration
    const blitzwareConfig = BlitzWareConfig(
      clientId: 'your-client-id',
      redirectUri: 'your-app-scheme://callback',
      responseType: 'code', // or "token" for implicit flow
    );

    // Create authentication service
    final authService = BlitzWareAuthService(config: blitzwareConfig);

    return ChangeNotifierProvider(
      create: (context) => BlitzWareAuthProvider(authService: authService),
      child: MaterialApp(
        title: 'BlitzWare Flutter SDK Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007BFF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFF007BFF),
            labelStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
