import '../models/user.dart';
import '../models/auth.dart';

/// Utility functions for BlitzWare authentication
class BlitzWareUtils {
  BlitzWareUtils._();

  /// Check if user has a specific role
  static bool hasRole(BlitzWareUser? user, String roleName) {
    return user?.hasRole(roleName) ?? false;
  }

  /// Check if user has any of the specified roles
  static bool hasAnyRole(BlitzWareUser? user, List<String> roleNames) {
    return user?.hasAnyRole(roleNames) ?? false;
  }

  /// Check if user has all of the specified roles
  static bool hasAllRoles(BlitzWareUser? user, List<String> roleNames) {
    return user?.hasAllRoles(roleNames) ?? false;
  }

  /// Get user's display name
  static String getUserDisplayName(BlitzWareUser? user) {
    return user?.displayName ?? 'Anonymous';
  }

  /// Get user's role names as a list
  static List<String> getUserRoles(BlitzWareUser? user) {
    return user?.roleNames ?? [];
  }

  /// Format role names for display
  static String formatRoles(BlitzWareUser? user, {String separator = ', '}) {
    final roles = getUserRoles(user);
    if (roles.isEmpty) return 'No roles';
    return roles.join(separator);
  }

  /// Check if user is an admin
  static bool isAdmin(BlitzWareUser? user) {
    return hasRole(user, 'admin');
  }

  /// Check if user has premium access
  static bool isPremium(BlitzWareUser? user) {
    return hasRole(user, 'premium');
  }

  /// Check if user is a moderator
  static bool isModerator(BlitzWareUser? user) {
    return hasRole(user, 'moderator');
  }

  /// Check if user has elevated privileges
  static bool hasElevatedPrivileges(BlitzWareUser? user) {
    return hasAnyRole(user, ['admin', 'moderator']);
  }

  /// Validate BlitzWare configuration
  static List<String> validateConfig(BlitzWareConfig config) {
    return config.validate();
  }

  /// Check if configuration is valid
  static bool isConfigValid(BlitzWareConfig config) {
    return validateConfig(config).isEmpty;
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
  static String generateMobileRedirectUri(String appScheme, {String path = 'callback'}) {
    return '$appScheme://$path';
  }

  /// Create default scopes for authentication
  static List<String> get defaultScopes => ['openid', 'profile', 'email'];

  /// Create scopes with roles included
  static List<String> get scopesWithRoles => ['openid', 'profile', 'email', 'roles'];

  /// Common role names
  static const String adminRole = 'admin';
  static const String premiumRole = 'premium';
  static const String moderatorRole = 'moderator';
  static const String userRole = 'user';

  /// Get user initials for avatar display
  static String getUserInitials(BlitzWareUser? user) {
    if (user == null) return '?';
    
    final name = user.username ?? user.email;
    if (name == null || name.isEmpty) return '?';

    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
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