# Flutter

This guide demonstrates how to add user authentication to a Flutter application using BlitzWare.

This tutorial is based on the [example app](https://github.com/LanderDK/blitzware_flutter_sdk/tree/master/example/example1).

1. [Configure BlitzWare](#1-configure-blitzware)
2. [Install the BlitzWare Flutter SDK](#2-install-the-blitzware-flutter-sdk)
3. [Implementation Guide](#3-implementation-guide)

---

## 1) Configure BlitzWare

### Get Your Application Keys

You will need some details about your application to communicate with BlitzWare. You can get these details from the **Application Settings** section in the BlitzWare dashboard.

**You need the Client ID.**

### Configure Redirect URIs

A redirect URI is a URL in your application where BlitzWare redirects the user after they have authenticated. The redirect URI for your app must be added to the **Redirect URIs** list in your **Application Settings** under the **Security** tab. If this is not set, users will be unable to log in to the application and will get an error.

---

## 2) Install the BlitzWare Flutter SDK

Add the BlitzWare Flutter SDK to your `pubspec.yaml`:

```yaml
dependencies:
  blitzware_flutter_sdk:
    git:
      url: https://github.com/LanderDK/blitzware_flutter_sdk.git
      ref: master
```

Then run:

```bash
flutter pub get
```

### Prerequisites

This SDK requires Flutter 3.0.0 or higher and includes the following key dependencies:

- `flutter_appauth` - For OAuth 2.0 authentication with PKCE
- `flutter_secure_storage` - For secure token storage
- `provider` - For state management
- `http` - For API communication

These dependencies are automatically installed with the SDK.

### Platform Setup

#### iOS Setup

1. Add URL scheme to your `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

Replace `yourapp` with your actual app scheme.

#### Android Setup

1. Add the redirect URI receiver activity to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<activity
    android:name="net.openid.appauth.RedirectUriReceiverActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="yourapp" />
    </intent-filter>
</activity>
```

Replace `yourapp` with your actual app scheme.

---

## 3) Implementation Guide

Follow this step-by-step guide to implement authentication in your app.

### Step 1: Configure the Provider

Wrap your app with the `BlitzWareAuthProvider` at the root level in your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // BlitzWare configuration
    const blitzwareConfig = BlitzWareConfig(
      clientId: 'your-client-id',
      redirectUri: 'yourapp://callback',
      responseType: 'code', // OAuth 2.0 authorization code flow
    );

    // Create authentication service
    final authService = BlitzWareAuthService(config: blitzwareConfig);

    return ChangeNotifierProvider(
      create: (context) => BlitzWareAuthProvider(authService: authService),
      child: MaterialApp(
        title: 'BlitzWare Flutter App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
```

### Step 2: Basic Authentication

Create your main authentication screen using the `AuthStateBuilder` widget:

```dart
import 'package:flutter/material.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthStateBuilder(
      // Loading state
      loading: (context) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      
      // Unauthenticated state - show login
      unauthenticated: (context) => const LoginScreen(),
      
      // Authenticated state - show main app
      authenticated: (context) => const DashboardScreen(),
      
      // Error state
      error: (context, error) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.message}'),
              ElevatedButton(
                onPressed: () {
                  context.read<BlitzWareAuthProvider>().refresh();
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

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'BlitzWare Authentication',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            // Use the built-in login button with automatic loading state
            BlitzWareLoginButton(
              text: 'Login with BlitzWare',
              icon: const Icon(Icons.login),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () async {
                try {
                  await context.read<BlitzWareAuthProvider>().login();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Login failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3: Display User Information

Create a dashboard screen that displays user information and authentication status:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Built-in logout button
          BlitzWareLogoutButton(
            text: 'Logout',
            icon: const Icon(Icons.logout, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<BlitzWareAuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Authentication Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Authentication Status:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authProvider.isLoading
                              ? 'Loading...'
                              : authProvider.isAuthenticated
                                  ? 'Authenticated'
                                  : 'Not Authenticated',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // User Information
                if (user != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Info:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'ID', value: user.id),
                          _InfoRow(label: 'Email', value: user.email),
                          _InfoRow(label: 'Username', value: user.username),
                          _InfoRow(
                            label: 'Roles',
                            value: user.roleNames.isNotEmpty
                                ? user.roleNames.join(', ')
                                : 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
```

### Step 4: Access Token Management

Get access tokens for making authenticated API calls:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiScreen extends StatefulWidget {
  const ApiScreen({super.key});

  @override
  State<ApiScreen> createState() => _ApiScreenState();
}

class _ApiScreenState extends State<ApiScreen> {
  String _apiResponse = '';
  bool _loading = false;

  Future<void> _makeApiCall() async {
    setState(() {
      _loading = true;
      _apiResponse = '';
    });

    try {
      // Get the access token (automatically refreshed if needed)
      final authProvider = context.read<BlitzWareAuthProvider>();
      final token = await authProvider.getAccessToken();

      if (token == null) {
        setState(() {
          _apiResponse = 'No access token available';
          _loading = false;
        });
        return;
      }

      // Make authenticated API call
      final response = await http.get(
        Uri.parse('https://api.yourservice.com/protected'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _apiResponse = 'Success: ${json.encode(data)}';
        });
      } else {
        setState(() {
          _apiResponse = 'Error: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        _apiResponse = 'Error: $error';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Integration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _makeApiCall,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Make Protected API Call'),
            ),
            const SizedBox(height: 16),
            if (_apiResponse.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_apiResponse),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

### Step 5: Role-Based Access Control

Implement role-based features using the `RoleGuard` widget:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

class RoleBasedDashboard extends StatelessWidget {
  const RoleBasedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Consumer<BlitzWareAuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.username ?? 'User'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Roles: ${user?.roleNames.join(', ') ?? 'None'}'),
                const SizedBox(height: 24),

                // Admin-only content using RoleGuard
                RoleGuard(
                  role: 'admin',
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: Colors.red.shade600,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Admin Panel',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('You have administrative privileges'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to admin features
                            },
                            child: const Text('Manage Users'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  fallback: const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // Premium-only content
                RoleGuard(
                  role: 'premium',
                  child: Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber.shade600),
                              const SizedBox(width: 8),
                              const Text(
                                'Premium Features',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Access to exclusive content'),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Regular user content (always visible when authenticated)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.dashboard, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            const Text(
                              'User Dashboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Standard user features available'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

You can also check roles programmatically using the provider:

```dart
Consumer<BlitzWareAuthProvider>(
  builder: (context, authProvider, _) {
    final isAdmin = authProvider.hasRole('admin');
    final isPremium = authProvider.hasRole('premium');
    final hasAnyModeratorRole = authProvider.hasAnyRole(['admin', 'moderator']);
    
    if (isAdmin) {
      return const AdminDashboard();
    } else if (isPremium) {
      return const PremiumDashboard();
    } else {
      return const StandardDashboard();
    }
  },
)
```

### Step 6: Session Validation

Add session validation for enhanced security:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

class ProtectedScreen extends StatefulWidget {
  const ProtectedScreen({super.key});

  @override
  State<ProtectedScreen> createState() => _ProtectedScreenState();
}

class _ProtectedScreenState extends State<ProtectedScreen> {
  bool? _sessionValid;
  bool _validating = false;

  Future<void> _validateSession() async {
    setState(() {
      _validating = true;
    });

    try {
      final authProvider = context.read<BlitzWareAuthProvider>();
      final isValid = await authProvider.validateSession();
      
      setState(() {
        _sessionValid = isValid;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isValid
                  ? 'Session is valid!'
                  : 'Session expired. Please log in again.',
            ),
            backgroundColor: isValid ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to validate session: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _validating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const Scaffold(
            body: Center(
              child: Text('Please log in to access this content'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Protected Content')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, ${authProvider.user?.username ?? 'User'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Session Status Display
                if (_sessionValid != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _sessionValid!
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _sessionValid!
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      'Session: ${_sessionValid! ? 'Valid' : 'Invalid'}',
                      style: TextStyle(
                        color: _sessionValid!
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _validating ? null : _validateSession,
                  child: _validating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Check Session'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

That's it! You now have a fully functional Flutter application with BlitzWare authentication.

For more information, check out the [example app](https://github.com/LanderDK/blitzware_flutter_sdk/tree/master/example/example1) which demonstrates all these features and more.