import 'package:flutter/material.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';
import 'package:provider/provider.dart';

import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthStateBuilder(
      loading: (context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing BlitzWare...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      unauthenticated: (context) => const LoginScreen(),
      authenticated: (context) => const AuthenticatedHome(),
      error: (context, error) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final authProvider = context.read<BlitzWareAuthProvider>();
                  authProvider.clearError();
                  authProvider.refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthenticatedHome extends StatefulWidget {
  const AuthenticatedHome({super.key});

  @override
  State<AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<AuthenticatedHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        // Build screens list based on user roles
        final screens = <Widget>[
          const DashboardScreen(),
        ];

        // Add admin screen if user has admin role
        if (authProvider.hasRole('admin')) {
          screens.add(const AdminScreen());
        }

        // Build navigation items based on available screens
        final navItems = <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
        ];

        if (authProvider.hasRole('admin')) {
          navItems.add(const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ));
        }

        // Ensure current index is valid
        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: navItems,
          ),
        );
      },
    );
  }
}