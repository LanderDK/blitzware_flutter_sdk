import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// BlitzWare authentication provider using ChangeNotifier
class BlitzWareAuthProvider extends ChangeNotifier {
  final BlitzWareAuthService _authService;
  final Logger _logger = Logger('BlitzWareAuthProvider');

  bool _isAuthenticated = false;
  bool _isLoading = true;
  BlitzWareUser? _user;
  BlitzWareException? _error;

  BlitzWareAuthProvider({required BlitzWareAuthService authService})
      : _authService = authService {
    _initializeAuth();
  }

  /// Whether user is authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Whether authentication is in progress
  bool get isLoading => _isLoading;

  /// Current authenticated user
  BlitzWareUser? get user => _user;

  /// Current error, if any
  BlitzWareException? get error => _error;

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      _setLoading(true);
      _clearError();

      // First check if we have a stored access token
      final hasStoredToken = await _authService.getStoredToken('access_token');

      if (hasStoredToken == null) {
        // No token available - user is not authenticated
        _setUnauthenticated();
        return;
      }

      // Validate token with server
      final isValid = await _authService.isAuthenticated();

      if (!isValid) {
        // Token is invalid or expired, try to refresh
        try {
          await _authService.refreshAccessToken();
          // After successful refresh, fetch user info
          final user = await _authService.getUser();
          if (user != null) {
            _setAuthenticated(user);
          } else {
            _setUnauthenticated();
          }
        } catch (refreshError) {
          // Refresh failed, clear everything
          _logger.warning('Token refresh during initialization failed: $refreshError');
          await _authService.logout();
          _setUnauthenticated();
        }
      } else {
        // Token is valid, get user info
        final user = await _authService.getUser();
        if (user != null) {
          _setAuthenticated(user);
        } else {
          _setUnauthenticated();
        }
      }
    } catch (error) {
      // On any error, treat as unauthenticated
      _logger.warning('Initialization failed: $error');
      _setError(
        error is BlitzWareException 
          ? error 
          : BlitzWareException('Authentication check failed: $error')
      );
      _setUnauthenticated();
    }
  }

  /// Authenticate user (login)
  Future<void> login() async {
    try {
      _setLoading(true);
      _clearError();
      _logger.info('Starting login');

      final user = await _authService.login();
      
      _setAuthenticated(user);
      _logger.info('Login successful');
    } catch (e) {
      _logger.severe('Login failed: $e');
      final error = e is BlitzWareException ? e : AuthenticationException('Login failed: $e');
      _setError(error);
      _setLoading(false);
      rethrow;
    }
  }

  /// Log out user
  Future<void> logout() async {
    try {
      _setLoading(true);
      _clearError();
      _logger.info('Starting logout');

      await _authService.logout();
      
      _setUnauthenticated();
      _logger.info('Logout successful');
    } catch (e) {
      _logger.severe('Logout failed: $e');
      final error = e is BlitzWareException ? e : AuthenticationException('Logout failed: $e');
      _setError(error);
      _setLoading(false);
      rethrow;
    }
  }

  /// Get access token with automatic validation/refresh
  Future<String?> getAccessToken() async {
    try {
      return await _authService.getAccessToken();
    } catch (error) {
      _logger.warning('Failed to get access token: $error');
      _setError(
        error is BlitzWareException
          ? error
          : BlitzWareException('Failed to get access token: $error')
      );
      return null;
    }
  }

  /// Validate current session
  Future<bool> validateSession() async {
    try {
      final isValid = await _authService.isAuthenticated();

      if (!isValid) {
        // Try to refresh
        try {
          await _authService.refreshAccessToken();
          return true;
        } catch (refreshError) {
          // Refresh failed, clear session
          _logger.warning('Session validation refresh failed: $refreshError');
          _setUnauthenticated();
          return false;
        }
      }

      return true;
    } catch (error) {
      _logger.warning('Session validation failed: $error');
      return false;
    }
  }

  /// Check if user has a specific role
  bool hasRole(String role) {
    if (_user == null || _user!.roles == null) {
      return false;
    }

    return _user!.roles!.any(
      (userRole) {
        if (userRole is String) {
          return userRole.toLowerCase() == role.toLowerCase();
        } else if (userRole is Map<String, dynamic>) {
          final name = userRole['name'];
          if (name is String) {
            return name.toLowerCase() == role.toLowerCase();
          }
        }
        return false;
      }
    );
  }

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<String> roleNames) {
    return _user?.hasAnyRole(roleNames) ?? false;
  }

  /// Check if user has all of the specified roles
  bool hasAllRoles(List<String> roleNames) {
    return _user?.hasAllRoles(roleNames) ?? false;
  }

  /// Get user's display name
  String? get userDisplayName => _user?.displayName;

  /// Get user's role names
  List<String> get userRoles => _user?.roleNames ?? [];

  /// Refresh authentication state
  Future<void> refresh() async {
    await _initializeAuth();
  }

  /// Set authenticated state
  void _setAuthenticated(BlitzWareUser user) {
    _isAuthenticated = true;
    _isLoading = false;
    _user = user;
    _error = null;
    notifyListeners();
  }

  /// Set unauthenticated state
  void _setUnauthenticated() {
    _isAuthenticated = false;
    _isLoading = false;
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(BlitzWareException error) {
    _error = error;
    notifyListeners();
  }

  /// Clear current error
  void _clearError() {
    _error = null;
  }

  /// Clear error manually
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _logger.info('Disposing BlitzWareAuthProvider');
    super.dispose();
  }
}

/// Convenience methods for role-based access control
extension BlitzWareAuthProviderRoles on BlitzWareAuthProvider {
  /// Check if user is an admin
  bool get isAdmin => hasRole('admin');

  /// Check if user has premium access
  bool get isPremium => hasRole('premium');

  /// Check if user is a moderator
  bool get isModerator => hasRole('moderator');

  /// Check if user has elevated privileges (admin or moderator)
  bool get hasElevatedPrivileges => hasAnyRole(['admin', 'moderator']);
}