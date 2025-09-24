import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // BlitzWare configuration
    final blitzwareConfig = BlitzWareConfig(
      clientId: 'your-client-id',
      redirectUri: 'com.example.blitzware://callback',
      responseType: 'code', // or 'token'
    );

    // Create authentication service
    final authService = BlitzWareAuthService(config: blitzwareConfig);

    return ChangeNotifierProvider(
      create: (context) => BlitzWareAuthProvider(authService: authService),
      child: MaterialApp(
        title: 'BlitzWare Flutter Role Check Example',
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
