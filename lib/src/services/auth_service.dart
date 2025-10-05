import 'dart:async';
import 'dart:convert';
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
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: _config.authorizationEndpoint,
          tokenEndpoint: _config.tokenEndpoint,
        ),
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
      final user = await _fetchUserInfo();
      await _storeUser(user);

      _logger.info('Authentication successful for user: ${user.id}');
      return user;
    } catch (e) {
      _logger.severe('Authentication failed: $e');
      throw _handleError(e, AuthErrorCode.authenticationFailed);
    }
  }

  /// Log out the user and clear stored tokens
  Future<void> logout() async {
    try {
      _logger.info('Starting logout');

      final accessToken = await getStoredToken('access_token');

      if (accessToken != null) {
        try {
          final response = await http.post(
            Uri.parse('${_config.issuer}/logout'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'client_id': _config.clientId,
            }),
          );

          if (response.statusCode < 200 || response.statusCode >= 300) {
            _logger.warning('Logout request failed: ${response.statusCode}');
          }
        } catch (logoutError) {
          // Continue with local logout even if logout request fails
          _logger.warning('Logout request failed: $logoutError');
        }
      }

      // Clear all stored data
      await _clearStorage();

      _logger.info('Logout completed');
    } catch (e) {
      _logger.severe('Logout failed: $e');
      throw _handleError(e, AuthErrorCode.logoutFailed);
    }
  }

  /// Get current access token, refreshing if necessary
  /// This method ensures you always get a valid token if possible
  Future<String?> getAccessToken() async {
    try {
      // First check if we have a token locally that appears valid
      final isLocallyValid = await isTokenValidLocally();

      if (!isLocallyValid) {
        // Token doesn't exist or is expired locally, try to refresh
        try {
          return await refreshAccessToken();
        } catch (e) {
          _logger.warning('Token refresh failed: $e');
          return null;
        }
      }

      // Now validate with server to be sure
      final isServerValid = await isAuthenticated();

      if (!isServerValid) {
        // Token is invalid on server, try to refresh
        try {
          return await refreshAccessToken();
        } catch (e) {
          _logger.warning('Token refresh after server validation failed: $e');
          return null;
        }
      }

      // Return the token
      return await getStoredToken('access_token');
    } catch (e) {
      _logger.warning('Failed to get access token: $e');
      return null;
    }
  }

  /// Get current access token without validation (faster, but may be expired)
  /// Use this for non-critical operations or when you handle validation separately
  Future<String?> getAccessTokenFast() async {
    try {
      final accessToken = await getStoredToken('access_token');
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);

      if (accessToken == null) {
        return null;
      }

      // Check if token is expired
      if (expiryString != null) {
        final expiryTime = int.parse(expiryString);
        if (DateTime.now().millisecondsSinceEpoch >= expiryTime) {
          return null;
        }
      }

      return accessToken;
    } catch (e) {
      _logger.warning('Failed to get access token fast: $e');
      return null;
    }
  }

  /// Refresh the access token using refresh token
  Future<String> refreshAccessToken() async {
    try {
      // First validate the refresh token using introspection
      final tokenValidation = await _validateRefreshToken();

      if (!tokenValidation.active) {
        _logger.warning('Refresh token is not active');
        await _clearStorage();
        throw const TokenException('Refresh token is not active');
      }

      final refreshToken = await getStoredToken('refresh_token');

      if (refreshToken == null) {
        _logger.warning('No refresh token available');
        await _clearStorage();
        throw const TokenException('No refresh token available');
      }

      _logger.info('Refreshing access token');

      final TokenRequest request = TokenRequest(
        _config.clientId,
        _config.redirectUri,
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: _config.authorizationEndpoint,
          tokenEndpoint: _config.tokenEndpoint,
        ),
        refreshToken: refreshToken,
      );

      final TokenResponse? response = await _appAuth.token(request);

      if (response == null || response.accessToken == null) {
        _logger.warning('Token refresh failed - no response');
        await _clearStorage();
        throw const TokenException('Token refresh failed - no response');
      }

      // Store new tokens
      await _storeTokens(TokenSet(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken ?? refreshToken,
        idToken: response.idToken,
        expiresAt: response.accessTokenExpirationDateTime,
      ));

      _logger.info('Token refresh successful');
      return response.accessToken!;
    } catch (e) {
      _logger.severe('Token refresh failed: $e');
      await _clearStorage();
      throw _handleError(e, AuthErrorCode.refreshFailed);
    }
  }

  /// Get current authenticated user, validating token and refreshing if needed
  /// Validates token then fetches user info
  Future<BlitzWareUser?> getUser() async {
    try {
      // First ensure we have a valid token
      final accessToken = await getAccessToken();

      if (accessToken == null) {
        return null;
      }

      // Get user from storage first (for performance)
      final userJson = await _secureStorage.read(key: _userKey);
      BlitzWareUser? storedUser;
      
      if (userJson != null) {
        try {
          final userMap = json.decode(userJson) as Map<String, dynamic>;
          storedUser = BlitzWareUser.fromJson(userMap);
        } catch (e) {
          _logger.warning('Failed to parse stored user: $e');
        }
      }

      // If we have stored user data and token is valid, return it
      if (storedUser != null) {
        return storedUser;
      }

      // No stored user or need fresh data, fetch from server
      final user = await _fetchUserInfo();
      await _storeUser(user);

      return user;
    } catch (e) {
      _logger.warning('Failed to get user: $e');
      return null;
    }
  }

  /// Get current authenticated user from storage only (no server validation)
  /// Use this for UI updates where you don't need fresh data
  Future<BlitzWareUser?> getUserFromStorage() async {
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

  /// Check if user has a specific role
  Future<bool> hasRole(String roleName) async {
    try {
      final user = await getUser();
      if (user == null) return false;

      return user.hasRole(roleName);
    } catch (e) {
      _logger.warning('Failed to check role: $e');
      return false;
    }
  }

  /// Check if user is currently authenticated
  /// Validates with server using token introspection
  Future<bool> isAuthenticated() async {
    try {
      final tokenValidation = await _validateAccessToken();
      return tokenValidation.active;
    } catch (e) {
      _logger.warning('Authentication check failed: $e');
      return false;
    }
  }

  /// Check if the stored access token is valid locally (not expired)
  /// This is a quick local check based on JWT expiration
  Future<bool> isTokenValidLocally() async {
    try {
      final token = await getStoredToken('access_token');
      if (token == null) return false;

      final payload = _parseJwt(token);
      if (payload == null) return false;

      final exp = payload['exp'];
      final expiration = _parseExp(exp);
      if (expiration == null) return false;

      return expiration.isAfter(DateTime.now());
    } catch (e) {
      _logger.warning('Local token validation failed: $e');
      return false;
    }
  }

  /// Fetch user information from the API
  /// Fetches user information using the stored access token with validation.
  /// Validates the token with the authorization server before fetching user info.
  Future<BlitzWareUser> _fetchUserInfo() async {
    try {
      // First validate the token using introspection
      final tokenValidation = await _validateAccessToken();

      if (!tokenValidation.active) {
        _logger.warning('Access token is not active during user info fetch');
        throw const TokenException('Access token is not active');
      }

      // If token is valid, fetch user info
      final accessToken = await getStoredToken('access_token');
      if (accessToken == null) {
        _logger.warning('No access token available for user info fetch');
        throw const TokenException('No access token available');
      }

      _logger.info('Fetching user info');

      final response = await http.get(
        Uri.parse(_config.userinfoEndpoint).replace(queryParameters: {
          'access_token': accessToken,
        }),
        headers: {
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
      throw _handleError(e, AuthErrorCode.userInfoFailed);
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

  /// Introspect a token to check its validity and get metadata
  /// Implements RFC 7662 OAuth2 Token Introspection
  Future<TokenIntrospectionResponse> _introspectToken(
    String token,
    String tokenTypeHint,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${_config.issuer}/introspect'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'token': token,
          'token_type_hint': tokenTypeHint,
          'client_id': _config.clientId,
        },
      );

      if (response.statusCode != 200) {
        throw TokenException(
          'Token introspection failed: ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      return TokenIntrospectionResponse.fromJson(responseData);
    } catch (e) {
      _logger.severe('Token introspection failed: $e');
      throw _handleError(e, AuthErrorCode.introspectionFailed);
    }
  }

  /// Validate an access token by introspecting it with the authorization server
  /// This provides authoritative validation from the server
  Future<TokenIntrospectionResponse> _validateAccessToken() async {
    final token = await getStoredToken('access_token');
    if (token == null) {
      return const TokenIntrospectionResponse(active: false);
    }

    try {
      return await _introspectToken(token, 'access_token');
    } catch (e) {
      // If introspection fails, token is considered invalid
      _logger.warning('Access token validation failed: $e');
      return const TokenIntrospectionResponse(active: false);
    }
  }

  /// Validate a refresh token by introspecting it with the authorization server
  Future<TokenIntrospectionResponse> _validateRefreshToken() async {
    final token = await getStoredToken('refresh_token');
    if (token == null) {
      return const TokenIntrospectionResponse(active: false);
    }

    try {
      return await _introspectToken(token, 'refresh_token');
    } catch (e) {
      // If introspection fails, token is considered invalid
      _logger.warning('Refresh token validation failed: $e');
      return const TokenIntrospectionResponse(active: false);
    }
  }

  /// Decode a JWT and return its payload as an object
  Map<String, dynamic>? _parseJwt(String token) {
    try {
      if (token.isEmpty) return null;

      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      
      // Normalize base64 string
      var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      
      // Add padding if needed
      switch (normalized.length % 4) {
        case 0:
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
        default:
          return null;
      }

      // Decode base64
      final decoded = utf8.decode(base64.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      _logger.warning('Failed to parse JWT: $e');
      return null;
    }
  }

  /// Convert a JWT exp (expiration) value to a DateTime object
  DateTime? _parseExp(dynamic exp) {
    if (exp == null) return null;
    
    int? expInt;
    if (exp is int) {
      expInt = exp;
    } else if (exp is String) {
      expInt = int.tryParse(exp);
    }
    
    if (expInt == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(expInt * 1000);
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

  /// Handle and normalize errors
  BlitzWareException _handleError(dynamic error, AuthErrorCode code) {
    if (error is BlitzWareException) {
      return error;
    }

    final message = error?.toString() ?? 'Unknown error occurred';
    return BlitzWareException(message, code: code.code);
  }
}
