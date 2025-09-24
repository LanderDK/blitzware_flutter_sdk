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

  AuthenticationState _state = AuthenticationState.unknown;
  BlitzWareUser? _user;
  BlitzWareException? _error;
  bool _isLoading = false;

  BlitzWareAuthProvider({required BlitzWareAuthService authService})
      : _authService = authService {
    _initialize();
  }

  /// Current authentication state
  AuthenticationState get state => _state;

  /// Current authenticated user
  BlitzWareUser? get user => _user;

  /// Current error, if any
  BlitzWareException? get error => _error;

  /// Whether authentication is in progress
  bool get isLoading => _isLoading;

  /// Whether user is authenticated
  bool get isAuthenticated => _state == AuthenticationState.authenticated;

  /// Whether user is unauthenticated
  bool get isUnauthenticated => _state == AuthenticationState.unauthenticated;

  /// Initialize authentication state
  Future<void> _initialize() async {
    try {
      _setLoading(true);
      _clearError();

      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final user = await _authService.getUser();
        if (user != null) {
          _setAuthenticated(user);
        } else {
          _setUnauthenticated();
        }
      } else {
        _setUnauthenticated();
      }
    } catch (e) {
      _logger.severe('Initialization failed: $e');
      _setError(e is BlitzWareException ? e : BlitzWareException('Initialization failed: $e'));
    } finally {
      _setLoading(false);
    }
  }

  /// Authenticate user
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
      rethrow;
    } finally {
      _setLoading(false);
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
      // Still set as unauthenticated even if logout fails
      _setUnauthenticated();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    try {
      return await _authService.getAccessToken();
    } catch (e) {
      _logger.warning('Failed to get access token: $e');
      return null;
    }
  }

  /// Refresh authentication state
  Future<void> refresh() async {
    await _initialize();
  }

  /// Check if user has a specific role
  bool hasRole(String roleName) {
    return _user?.hasRole(roleName) ?? false;
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

  /// Set authenticated state
  void _setAuthenticated(BlitzWareUser user) {
    _state = AuthenticationState.authenticated;
    _user = user;
    _error = null;
    notifyListeners();
  }

  /// Set unauthenticated state
  void _setUnauthenticated() {
    _state = AuthenticationState.unauthenticated;
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _state = AuthenticationState.loading;
    }
    notifyListeners();
  }

  /// Set error state
  void _setError(BlitzWareException error) {
    _state = AuthenticationState.error;
    _error = error;
    notifyListeners();
  }

  /// Clear current error
  void _clearError() {
    _error = null;
    notifyListeners();
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