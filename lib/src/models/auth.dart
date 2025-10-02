/// Configuration for BlitzWare authentication
class BlitzWareConfig {
  final String clientId;
  final String redirectUri;
  final String responseType;

  const BlitzWareConfig({
    required this.clientId,
    required this.redirectUri,
    this.responseType = 'code',
  });

  /// Get the issuer URL
  String get issuer => 'https://auth.blitzware.xyz/api/auth';

  /// Get the authorization endpoint
  String get authorizationEndpoint => '$issuer/authorize';

  /// Get the token endpoint
  String get tokenEndpoint => '$issuer/token';

  /// Get the userinfo endpoint
  String get userinfoEndpoint => '$issuer/userinfo';

  /// Get the logout endpoint
  String get logoutEndpoint => '$issuer/logout';

  /// Validate configuration
  List<String> validate() {
    final errors = <String>[];

    if (clientId.isEmpty) {
      errors.add('clientId is required');
    }

    if (redirectUri.isEmpty) {
      errors.add('redirectUri is required');
    }

    if (!redirectUri.contains('://')) {
      errors.add('redirectUri must include a valid scheme');
    }

    if (responseType != 'code' && responseType != 'token') {
      errors.add('responseType must be "code" or "token"');
    }

    return errors;
  }

  @override
  String toString() => 'BlitzWareConfig(clientId: $clientId)';
}

/// Authentication state
enum AuthenticationState {
  unknown,
  authenticated,
  unauthenticated,
  loading,
  error,
}

/// Token set containing access and refresh tokens
class TokenSet {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? tokenType;
  final DateTime? expiresAt;
  final String? scope;

  const TokenSet({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.tokenType = 'Bearer',
    this.expiresAt,
    this.scope,
  });

  factory TokenSet.fromJson(Map<String, dynamic> json) {
    return TokenSet(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      idToken: json['id_token'] as String?,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresAt: json['expires_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expires_at'] as int)
          : null,
      scope: json['scope'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (idToken != null) 'id_token': idToken,
      'token_type': tokenType,
      if (expiresAt != null) 'expires_at': expiresAt!.millisecondsSinceEpoch,
      if (scope != null) 'scope': scope,
    };
  }

  /// Check if the access token is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.subtract(const Duration(minutes: 5)));
  }

  /// Get authorization header value
  String get authorizationHeader => '$tokenType $accessToken';

  @override
  String toString() => 'TokenSet(accessToken: ${accessToken.substring(0, 10)}...)';
}

/// BlitzWare authentication exception
class BlitzWareException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const BlitzWareException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'BlitzWareException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Specific authentication exceptions
class AuthenticationException extends BlitzWareException {
  const AuthenticationException(super.message, {super.code, super.originalError});
}

class TokenException extends BlitzWareException {
  const TokenException(super.message, {super.code, super.originalError});
}

class NetworkException extends BlitzWareException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class ConfigurationException extends BlitzWareException {
  const ConfigurationException(super.message, {super.code, super.originalError});
}

/// Token introspection response (RFC 7662 OAuth2 Token Introspection)
class TokenIntrospectionResponse {
  final bool active;
  final String? clientId;
  final String? username;
  final String? scope;
  final String? sub;
  final String? aud;
  final String? iss;
  final int? exp;
  final int? iat;
  final String? tokenType;
  final Map<String, dynamic>? additionalProperties;

  const TokenIntrospectionResponse({
    required this.active,
    this.clientId,
    this.username,
    this.scope,
    this.sub,
    this.aud,
    this.iss,
    this.exp,
    this.iat,
    this.tokenType,
    this.additionalProperties,
  });

  factory TokenIntrospectionResponse.fromJson(Map<String, dynamic> json) {
    // Extract known fields
    final knownFields = {
      'active', 'client_id', 'username', 'scope', 'sub', 'aud', 'iss', 
      'exp', 'iat', 'token_type'
    };
    final additionalProperties = <String, dynamic>{};
    
    // Store any additional properties
    for (final entry in json.entries) {
      if (!knownFields.contains(entry.key)) {
        additionalProperties[entry.key] = entry.value;
      }
    }

    return TokenIntrospectionResponse(
      active: json['active'] as bool,
      clientId: json['client_id'] as String?,
      username: json['username'] as String?,
      scope: json['scope'] as String?,
      sub: json['sub'] as String?,
      aud: json['aud'] as String?,
      iss: json['iss'] as String?,
      exp: json['exp'] as int?,
      iat: json['iat'] as int?,
      tokenType: json['token_type'] as String?,
      additionalProperties: additionalProperties.isNotEmpty ? additionalProperties : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'active': active,
      if (clientId != null) 'client_id': clientId,
      if (username != null) 'username': username,
      if (scope != null) 'scope': scope,
      if (sub != null) 'sub': sub,
      if (aud != null) 'aud': aud,
      if (iss != null) 'iss': iss,
      if (exp != null) 'exp': exp,
      if (iat != null) 'iat': iat,
      if (tokenType != null) 'token_type': tokenType,
    };

    // Add any additional properties
    if (additionalProperties != null) {
      json.addAll(additionalProperties!);
    }

    return json;
  }
}

/// Authentication error codes matching React Native SDK
enum AuthErrorCode {
  configurationError,
  networkError,
  authenticationFailed,
  tokenExpired,
  refreshFailed,
  logoutFailed,
  userInfoFailed,
  storageError,
  introspectionFailed,
  unknownError,
}

extension AuthErrorCodeExtension on AuthErrorCode {
  String get code {
    switch (this) {
      case AuthErrorCode.configurationError:
        return 'configuration_error';
      case AuthErrorCode.networkError:
        return 'network_error';
      case AuthErrorCode.authenticationFailed:
        return 'authentication_failed';
      case AuthErrorCode.tokenExpired:
        return 'token_expired';
      case AuthErrorCode.refreshFailed:
        return 'refresh_failed';
      case AuthErrorCode.logoutFailed:
        return 'logout_failed';
      case AuthErrorCode.userInfoFailed:
        return 'user_info_failed';
      case AuthErrorCode.storageError:
        return 'storage_error';
      case AuthErrorCode.introspectionFailed:
        return 'introspection_failed';
      case AuthErrorCode.unknownError:
        return 'unknown_error';
    }
  }
}