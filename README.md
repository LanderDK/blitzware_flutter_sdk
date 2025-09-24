# BlitzWare Flutter SDK

A comprehensive Flutter SDK for BlitzWare authentication with role-based access control, built for cross-platform mobile applications.

## Features

- **OAuth 2.0 Authentication** with PKCE (Proof Key for Code Exchange)
- **Role-based Access Control** (Admin, Premium, Moderator, User)
- **Secure Token Storage** using Flutter Secure Storage
- **Cross-platform Support** (iOS and Android)
- **Provider State Management** integration
- **Automatic Token Refresh** handling
- **Comprehensive Error Handling**
- **TypeScript-like Type Safety** with Dart

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  blitzware_flutter_sdk:
    path: ../path/to/blitzware-flutter-sdk
```

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BlitzWareAuthProvider(
            BlitzWareAuthService(
              clientId: 'your-client-id',
              redirectUrl: 'your-app://auth',
              responseType: 'code', // or 'token'
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'BlitzWare App',
        home: AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        return authProvider.isAuthenticated
            ? HomeScreen()
            : LoginScreen();
      },
    );
  }
}
```

### Authentication

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final authProvider = context.read<BlitzWareAuthProvider>();
            try {
              await authProvider.login();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login failed: $e')),
              );
            }
          },
          child: Text('Login with BlitzWare'),
        ),
      ),
    );
  }
}
```

### Role-based Access Control

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Consumer<BlitzWareAuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user!;
          
          return Column(
            children: [
              Text('Welcome, ${user.name}!'),
              
              // Admin-only content
              if (user.isAdmin)
                AdminOnlyWidget(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminPanel()),
                    ),
                    child: Text('Admin Panel'),
                  ),
                ),
              
              // Premium-only content
              if (user.isPremium)
                PremiumOnlyWidget(
                  child: Card(
                    child: ListTile(
                      title: Text('Premium Features'),
                      subtitle: Text('Access exclusive content'),
                      trailing: Icon(Icons.star),
                    ),
                  ),
                ),
              
              // Regular user content
              ElevatedButton(
                onPressed: () async {
                  await authProvider.logout();
                },
                child: Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

## API Reference

### BlitzWareAuthService

The core authentication service:

```dart
final authService = BlitzWareAuthService(
  clientId: 'your-client-id',
  redirectUrl: 'your-app://auth',
  discoveryUrl: 'https://auth.example.com/.well-known/openid_configuration',
  scopes: ['openid', 'profile', 'email', 'roles'],
  additionalParameters: {'prompt': 'login'}, // Optional
  debugMode: false, // Optional debug logging
);

// Authenticate user
final result = await authService.login();

// Get stored access token
final token = await authService.getAccessToken();

// Refresh tokens
await authService.refresh();

// Logout and clear tokens
await authService.logout();
```

### BlitzWareAuthProvider

Provider for state management:

```dart
final authProvider = BlitzWareAuthProvider(authService);

// Properties
bool get isAuthenticated => authProvider.isAuthenticated;
bool get isLoading => authProvider.isLoading;
BlitzWareUser? get user => authProvider.user;
String? get error => authProvider.error;

// Methods
await authProvider.login();
await authProvider.logout();
await authProvider.refresh();
final token = await authProvider.getAccessToken();
```

### BlitzWareUser

User model with role checking:

```dart
final user = authProvider.user!;

// Basic properties
String get sub => user.sub;
String? get name => user.name;
String? get email => user.email;
String? get username => user.username;
String? get picture => user.picture;
bool get isEmailVerified => user.isEmailVerified;

// Role checking
bool get isAdmin => user.isAdmin;
bool get isPremium => user.isPremium;
bool get isModerator => user.isModerator;
List<String> get roleNames => user.roleNames;

// Utility methods
bool hasRole(String role) => user.hasRole(role);
String get initials => user.initials;
String get formattedUpdatedAt => user.formattedUpdatedAt;
Map<String, dynamic> toJson() => user.toJson();
```

### Role-based Widgets

Convenient widgets for role-based UI:

```dart
// Admin-only widget
AdminOnlyWidget(
  child: Text('Admin Content'),
  fallback: Text('Access Denied'), // Optional
)

// Premium-only widget
PremiumOnlyWidget(
  child: Text('Premium Content'),
  fallback: UpgradePrompt(), // Optional
)

// Custom role widget
RoleBasedWidget(
  allowedRoles: ['admin', 'moderator'],
  child: Text('Admin or Moderator Content'),
  fallback: Text('Insufficient Permissions'), // Optional
)
```

## Platform Configuration

### iOS Setup

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>your-app.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-app</string>
        </array>
    </dict>
</array>
```

### Android Setup

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name="net.openid.appauth.RedirectUriReceiverActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="your-app" android:host="auth" />
    </intent-filter>
</activity>
```

## Dependencies

Core dependencies included:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_appauth: ^6.0.2
  flutter_secure_storage: ^9.0.0
  provider: ^6.0.5
  http: ^1.1.0
```

## Examples

Check out the comprehensive example app:

```bash
cd examples/blitzware_flutter_role_check_example
flutter pub get
flutter run
```

The example demonstrates:
- Complete authentication flow
- Role-based dashboard
- User profile management
- Token handling
- Error scenarios

## Error Handling

The SDK provides comprehensive error handling:

```dart
try {
  await authProvider.login();
} on BlitzWareAuthException catch (e) {
  switch (e.type) {
    case BlitzWareAuthExceptionType.userCancelled:
      print('User cancelled login');
      break;
    case BlitzWareAuthExceptionType.networkError:
      print('Network error: ${e.message}');
      break;
    case BlitzWareAuthExceptionType.invalidConfiguration:
      print('Configuration error: ${e.message}');
      break;
    case BlitzWareAuthExceptionType.tokenExpired:
      print('Token expired, refreshing...');
      await authProvider.refresh();
      break;
    default:
      print('Auth error: ${e.message}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

## Security Best Practices

1. **Use HTTPS**: Always use HTTPS for your discovery URL and redirect URIs
2. **Validate Tokens**: Server-side token validation is essential
3. **Secure Storage**: Tokens are automatically stored securely using platform security
4. **Certificate Pinning**: Consider implementing certificate pinning for production
5. **Scope Limitation**: Request only necessary scopes
6. **Token Lifecycle**: Implement proper token refresh and cleanup

## Development

### Building the SDK

```bash
flutter packages get
flutter analyze
flutter test
```

### Running Tests

```bash
flutter test
flutter test --coverage
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Architecture

The SDK follows these architectural principles:

- **Provider Pattern**: Clean state management
- **Service Layer**: Separation of concerns
- **Type Safety**: Comprehensive type definitions
- **Error Handling**: Robust error management
- **Security First**: Secure token storage and handling

## Changelog

### Version 1.0.0
- Initial release
- OAuth 2.0 with PKCE support
- Role-based access control
- Provider state management
- Cross-platform support
- Comprehensive example app

## Support

For support and questions:
- Documentation: [docs.blitzware.xyz](https://docs.blitzware.xyz)
- Issues: GitHub Issues
- Community: BlitzWare Discord

## License

This SDK is licensed under the MIT License. See LICENSE file for details.