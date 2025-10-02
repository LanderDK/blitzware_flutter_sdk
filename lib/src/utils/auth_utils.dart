import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import '../models/user.dart';
import '../models/auth.dart';

/// Role checking utilities matching React Native SDK
bool _hasRole(BlitzWareUser? user, String roleName) {
  if (user == null || user.roles == null) return false;

  return user.roles!.any((role) {
    if (role is String) {
      return role.toLowerCase() == roleName.toLowerCase();
    } else if (role is Map<String, dynamic>) {
      return role['name']?.toString().toLowerCase() == roleName.toLowerCase();
    } else if (role is BlitzWareRole) {
      return role.name.toLowerCase() == roleName.toLowerCase();
    }
    return false;
  });
}

/// Check if user has any of the specified roles
bool _hasAnyRole(BlitzWareUser? user, List<String> roleNames) {
  if (user == null || user.roles == null || roleNames.isEmpty) return false;

  for (final roleName in roleNames) {
    if (_hasRole(user, roleName)) return true;
  }
  return false;
}

/// Check if user has all of the specified roles
bool _hasAllRoles(BlitzWareUser? user, List<String> roleNames) {
  if (user == null || user.roles == null || roleNames.isEmpty) return false;

  for (final roleName in roleNames) {
    if (!_hasRole(user, roleName)) return false;
  }
  return true;
}

/// Get user's role names as a list of strings
List<String> _getUserRoles(BlitzWareUser? user) {
  if (user == null || user.roles == null) return [];

  return user.roles!
      .map((role) {
        if (role is String) {
          return role;
        } else if (role is Map<String, dynamic>) {
          return role['name']?.toString() ?? '';
        } else if (role is BlitzWareRole) {
          return role.name;
        }
        return '';
      })
      .where((name) => name.isNotEmpty)
      .toList();
}

/// Get user's display name following React Native SDK logic
String _getUserDisplayName(BlitzWareUser? user) {
  if (user == null) return 'Anonymous';
  return user.username;
}

/// Global functions for public API (matching React Native SDK)
bool hasRole(BlitzWareUser? user, String roleName) => _hasRole(user, roleName);
bool hasAnyRole(BlitzWareUser? user, List<String> roleNames) =>
    _hasAnyRole(user, roleNames);
bool hasAllRoles(BlitzWareUser? user, List<String> roleNames) =>
    _hasAllRoles(user, roleNames);
List<String> getUserRoles(BlitzWareUser? user) => _getUserRoles(user);
String getUserDisplayName(BlitzWareUser? user) => _getUserDisplayName(user);

/// Check if a token is expired (with 5-minute buffer)
bool isTokenExpired(DateTime? expiresAt) {
  if (expiresAt == null) return false;
  return DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));
}

/// Generate cryptographically secure random string
String generateRandomString(int length) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(length, (index) => chars[random.nextInt(chars.length)])
      .join();
}

/// Validate BlitzWare configuration
List<String> validateConfig(BlitzWareConfig config) {
  return config.validate();
}

/// Generate PKCE code verifier
String generateCodeVerifier() {
  return generateRandomString(128);
}

/// Generate PKCE code challenge from verifier
String generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}

/// Utility functions for BlitzWare authentication (backward compatibility)
class BlitzWareUtils {
  BlitzWareUtils._();

  /// Check if user has a specific role
  static bool hasRole(BlitzWareUser? user, String roleName) {
    return _hasRole(user, roleName);
  }

  /// Check if user has any of the specified roles
  static bool hasAnyRole(BlitzWareUser? user, List<String> roleNames) {
    return _hasAnyRole(user, roleNames);
  }

  /// Check if user has all of the specified roles
  static bool hasAllRoles(BlitzWareUser? user, List<String> roleNames) {
    return _hasAllRoles(user, roleNames);
  }

  /// Get user's display name
  static String getUserDisplayName(BlitzWareUser? user) {
    return _getUserDisplayName(user);
  }

  /// Get user's role names as a list
  static List<String> getUserRoles(BlitzWareUser? user) {
    return _getUserRoles(user);
  }

  /// Format role names for display
  static String formatRoles(BlitzWareUser? user, {String separator = ', '}) {
    final roles = _getUserRoles(user);
    if (roles.isEmpty) return 'No roles';
    return roles.join(separator);
  }

  /// Check if user is an admin
  static bool isAdmin(BlitzWareUser? user) {
    return _hasRole(user, 'admin');
  }

  /// Check if user has premium access
  static bool isPremium(BlitzWareUser? user) {
    return _hasRole(user, 'premium');
  }

  /// Check if user is a moderator
  static bool isModerator(BlitzWareUser? user) {
    return _hasRole(user, 'moderator');
  }

  /// Check if user has elevated privileges
  static bool hasElevatedPrivileges(BlitzWareUser? user) {
    return _hasAnyRole(user, ['admin', 'moderator']);
  }

  /// Validate BlitzWare configuration
  static List<String> validateConfig(BlitzWareConfig config) {
    return config.validate();
  }

  /// Check if configuration is valid
  static bool isConfigValid(BlitzWareConfig config) {
    return config.validate().isEmpty;
  }

  /// Create a configuration from environment or map
  static BlitzWareConfig createConfig({
    required String clientId,
    required String redirectUri,
    String responseType = 'code',
  }) {
    return BlitzWareConfig(
      clientId: clientId,
      redirectUri: redirectUri,
      responseType: responseType,
    );
  }

  /// Generate a secure redirect URI for mobile apps
  static String generateMobileRedirectUri(String appScheme,
      {String path = 'callback'}) {
    return '$appScheme://$path';
  }

  /// Create default scopes for authentication
  static List<String> get defaultScopes => ['openid', 'profile', 'email'];

  /// Create scopes with roles included
  static List<String> get scopesWithRoles =>
      ['openid', 'profile', 'email', 'roles'];

  /// Common role names
  static const String adminRole = 'admin';
  static const String premiumRole = 'premium';
  static const String moderatorRole = 'moderator';
  static const String userRole = 'user';

  /// Get user initials for avatar display
  static String getUserInitials(BlitzWareUser? user) {
    if (user == null) return '?';

    final name = user.username;
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  /// Format date string for display
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Format date time string for display
  static String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  /// Get error message from exception
  static String getErrorMessage(Object error) {
    if (error is BlitzWareException) {
      return error.message;
    }
    return error.toString();
  }

  /// Check if error is a network error
  static bool isNetworkError(Object error) {
    return error is NetworkException;
  }

  /// Check if error is an authentication error
  static bool isAuthError(Object error) {
    return error is AuthenticationException;
  }

  /// Check if error is a token error
  static bool isTokenError(Object error) {
    return error is TokenException;
  }

  /// Check if error is a configuration error
  static bool isConfigError(Object error) {
    return error is ConfigurationException;
  }
}

/// Extension methods for BlitzWareUser
extension BlitzWareUserExtensions on BlitzWareUser {
  /// Get user initials
  String get initials => BlitzWareUtils.getUserInitials(this);

  /// Check if user is admin
  bool get isAdmin => BlitzWareUtils.isAdmin(this);

  /// Check if user is premium
  bool get isPremium => BlitzWareUtils.isPremium(this);

  /// Check if user is moderator
  bool get isModerator => BlitzWareUtils.isModerator(this);

  /// Check if user has elevated privileges
  bool get hasElevatedPrivileges => BlitzWareUtils.hasElevatedPrivileges(this);

  /// Format roles for display
  String formatRoles({String separator = ', '}) =>
      BlitzWareUtils.formatRoles(this, separator: separator);
}

/// Extension methods for BlitzWareConfig
extension BlitzWareConfigExtensions on BlitzWareConfig {
  /// Check if configuration is valid
  bool get isValid => BlitzWareUtils.isConfigValid(this);

  /// Get validation errors
  List<String> get validationErrors => BlitzWareUtils.validateConfig(this);
}
