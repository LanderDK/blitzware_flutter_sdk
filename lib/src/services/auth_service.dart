import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../models/auth.dart';
import '../models/user.dart';

/// BlitzWare authentication service
class BlitzWareAuthService {
  final BlitzWareConfig _config;
  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  static const String _accessTokenKey = 'blitzware_access_token';
  static const String _refreshTokenKey = 'blitzware_refresh_token';
  static const String _idTokenKey = 'blitzware_id_token';
  static const String _userKey = 'blitzware_user';
  static const String _tokenExpiryKey = 'blitzware_token_expiry';

  BlitzWareAuthService({
    required BlitzWareConfig config,
    FlutterAppAuth? appAuth,
    FlutterSecureStorage? secureStorage,
  })  : _config = config,
        _appAuth = appAuth ?? const FlutterAppAuth(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _logger = Logger('BlitzWareAuthService') {
    // Validate configuration
    final errors = _config.validate();
    if (errors.isNotEmpty) {
      throw ConfigurationException(
        'Invalid configuration: ${errors.join(', ')}',
      );
    }
  }

  /// Authenticate user with authorization code flow
  Future<BlitzWareUser> login() async {
    try {
      _logger.info('Starting authentication flow');

      final AuthorizationTokenRequest request = AuthorizationTokenRequest(
        _config.clientId,
        _config.redirectUri,
        issuer: _config.issuer,
      );

      final AuthorizationTokenResponse? response =
          await _appAuth.authorizeAndExchangeCode(request);

      if (response == null) {
        throw const AuthenticationException('Authentication was cancelled');
      }

      if (response.accessToken == null) {
        throw const AuthenticationException('No access token received');
      }

      // Store tokens securely
      await _storeTokens(TokenSet(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
        idToken: response.idToken,
        expiresAt: response.accessTokenExpirationDateTime,
      ));

      // Fetch user information
      final user = await _fetchUserInfo(response.accessToken!);
      await _storeUser(user);

      _logger.info('Authentication successful for user: ${user.id}');
      return user;
    } catch (e) {
      _logger.severe('Authentication failed: $e');
      if (e is BlitzWareException) rethrow;
      throw AuthenticationException('Authentication failed: $e');
    }
  }

  /// Log out the user and clear stored tokens
  Future<void> logout() async {
    try {
      _logger.info('Starting logout');

      // Get current tokens for logout endpoint
      final accessToken = await getAccessToken();

      if (accessToken != null) {
        try {
          // Call logout endpoint
          await _revokeToken(accessToken);
        } catch (e) {
          _logger.warning('Token revocation failed: $e');
          // Continue with local logout even if server logout fails
        }
      }

      // Clear all stored data
      await _clearStorage();

      _logger.info('Logout completed');
    } catch (e) {
      _logger.severe('Logout failed: $e');
      throw AuthenticationException('Logout failed: $e');
    }
  }

  /// Get current access token, refreshing if necessary
  Future<String?> getAccessToken() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      if (accessToken == null) return null;

      // Check if token is expired
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryString != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(expiryString),
        );

        // Refresh if token expires within 5 minutes
        if (DateTime.now().isAfter(
          expiryTime.subtract(const Duration(minutes: 5)),
        )) {
          return await _refreshAccessToken();
        }
      }

      return accessToken;
    } catch (e) {
      _logger.warning('Failed to get access token: $e');
      return null;
    }
  }

  /// Refresh the access token using refresh token
  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        _logger.warning('No refresh token available');
        await _clearStorage();
        return null;
      }

      _logger.info('Refreshing access token');

      final TokenRequest request = TokenRequest(
        _config.clientId,
        _config.redirectUri,
        issuer: _config.issuer,
        refreshToken: refreshToken,
      );

      final TokenResponse? response = await _appAuth.token(request);

      if (response == null || response.accessToken == null) {
        _logger.warning('Token refresh failed - no response');
        await _clearStorage();
        return null;
      }

      // Store new tokens
      await _storeTokens(TokenSet(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken ?? refreshToken,
        idToken: response.idToken,
        expiresAt: response.accessTokenExpirationDateTime,
      ));

      _logger.info('Token refresh successful');
      return response.accessToken;
    } catch (e) {
      _logger.severe('Token refresh failed: $e');
      await _clearStorage();
      return null;
    }
  }

  /// Get current authenticated user
  Future<BlitzWareUser?> getUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson == null) return null;

      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return BlitzWareUser.fromJson(userMap);
    } catch (e) {
      _logger.warning('Failed to get user from storage: $e');
      return null;
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null;
    } catch (e) {
      _logger.warning('Authentication check failed: $e');
      return false;
    }
  }

  /// Fetch user information from the API
  Future<BlitzWareUser> _fetchUserInfo(String accessToken) async {
    try {
      _logger.info('Fetching user info');

      final response = await http.get(
        Uri.parse(_config.userinfoEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw NetworkException(
          'Failed to fetch user info: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }

      final userMap = json.decode(response.body) as Map<String, dynamic>;
      return BlitzWareUser.fromJson(userMap);
    } catch (e) {
      _logger.severe('Failed to fetch user info: $e');
      if (e is BlitzWareException) rethrow;
      throw NetworkException('Failed to fetch user info: $e');
    }
  }

  /// Store tokens securely
  Future<void> _storeTokens(TokenSet tokens) async {
    try {
      await _secureStorage.write(
          key: _accessTokenKey, value: tokens.accessToken);

      if (tokens.refreshToken != null) {
        await _secureStorage.write(
            key: _refreshTokenKey, value: tokens.refreshToken);
      }

      if (tokens.idToken != null) {
        await _secureStorage.write(key: _idTokenKey, value: tokens.idToken);
      }

      if (tokens.expiresAt != null) {
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: tokens.expiresAt!.millisecondsSinceEpoch.toString(),
        );
      }
    } catch (e) {
      _logger.severe('Failed to store tokens: $e');
      throw TokenException('Failed to store tokens: $e');
    }
  }

  /// Store user information
  Future<void> _storeUser(BlitzWareUser user) async {
    try {
      final userJson = json.encode(user.toJson());
      await _secureStorage.write(key: _userKey, value: userJson);
    } catch (e) {
      _logger.warning('Failed to store user: $e');
    }
  }

  /// Revoke token on server
  Future<void> _revokeToken(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('${_config.issuer}/oauth/revoke'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'token': accessToken,
          'client_id': _config.clientId,
        },
      );

      if (response.statusCode != 200) {
        _logger.warning('Token revocation failed: ${response.statusCode}');
      }
    } catch (e) {
      _logger.warning('Token revocation request failed: $e');
    }
  }

  /// Clear all stored authentication data
  Future<void> _clearStorage() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _idTokenKey),
        _secureStorage.delete(key: _userKey),
        _secureStorage.delete(key: _tokenExpiryKey),
      ]);
    } catch (e) {
      _logger.warning('Failed to clear storage: $e');
    }
  }

  /// Generate a cryptographically random string
  String _generateRandomString(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Generate code verifier for PKCE
  String _generateCodeVerifier() => _generateRandomString(128);

  /// Generate code challenge for PKCE
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Get current access token without validation (faster, but may be expired)
  /// Use this for non-critical operations or when you handle validation separately
  Future<String?> getAccessTokenFast() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      _logger.warning('Failed to get access token fast: $e');
      return null;
    }
  }

  /// Refresh the access token using refresh token (public method)
  Future<String?> refreshAccessToken() async {
    return await _refreshAccessToken();
  }

  /// Get current authenticated user from storage only (no server validation)
  /// Use this for UI updates where you don't need fresh data
  Future<BlitzWareUser?> getUserFromStorage() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson == null) return null;

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return BlitzWareUser.fromJson(userMap);
    } catch (e) {
      _logger.warning('Failed to get user from storage: $e');
      return null;
    }
  }

  /// Check if user has a specific role
  Future<bool> hasRole(String roleName) async {
    try {
      final user = await getUserFromStorage();
      if (user == null || user.roles == null) return false;

      return user.roles!.any((role) {
        if (role is String) {
          return role.toLowerCase() == roleName.toLowerCase();
        } else if (role is Map<String, dynamic>) {
          return role['name']?.toString().toLowerCase() ==
              roleName.toLowerCase();
        } else if (role is BlitzWareRole) {
          return role.name.toLowerCase() == roleName.toLowerCase();
        }
        return false;
      });
    } catch (e) {
      _logger.warning('Failed to check role: $e');
      return false;
    }
  }

  /// Validate access token with authorization server
  /// Returns true if token is valid, false otherwise
  Future<bool> validateAccessToken() async {
    try {
      final accessToken = await getAccessTokenFast();
      if (accessToken == null) return false;

      // Try to introspect the token
      final introspection = await introspectToken(accessToken);
      return introspection.active;
    } catch (e) {
      _logger.warning('Token validation failed: $e');
      return false;
    }
  }

  /// Introspect a token to check its validity and get metadata
  /// Implements RFC 7662 OAuth2 Token Introspection
  Future<TokenIntrospectionResponse> introspectToken(
    String token, {
    String? tokenTypeHint,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_config.issuer}/oauth/introspect'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'token': token,
          'client_id': _config.clientId,
          if (tokenTypeHint != null) 'token_type_hint': tokenTypeHint,
        },
      );

      if (response.statusCode != 200) {
        throw TokenException(
          'Token introspection failed: ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return TokenIntrospectionResponse.fromJson(responseData);
    } catch (e) {
      _logger.severe('Token introspection failed: $e');
      if (e is BlitzWareException) rethrow;
      throw TokenException('Token introspection failed: $e');
    }
  }

  /// Get stored token (public method matching React Native SDK)
  Future<String?> getStoredToken(String type) async {
    try {
      switch (type) {
        case 'access_token':
          return await _secureStorage.read(key: _accessTokenKey);
        case 'refresh_token':
          return await _secureStorage.read(key: _refreshTokenKey);
        case 'id_token':
          return await _secureStorage.read(key: _idTokenKey);
        default:
          throw ArgumentError('Invalid token type: $type');
      }
    } catch (e) {
      _logger.warning('Failed to get stored token: $e');
      return null;
    }
  }

  /// Check if a token is expired (with buffer)
  bool isTokenExpired(DateTime? expiresAt,
      {Duration buffer = const Duration(minutes: 5)}) {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt.subtract(buffer));
  }
}
