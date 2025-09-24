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