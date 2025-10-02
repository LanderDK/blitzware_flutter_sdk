/// BlitzWare Flutter SDK
/// 
/// A comprehensive authentication SDK for Flutter applications providing
/// secure OAuth 2.0/OIDC authentication with role-based access control.
library blitzware_flutter_sdk;

// Models
export 'src/models/user.dart';
export 'src/models/auth.dart';

// Services
export 'src/services/auth_service.dart';

// Providers
export 'src/providers/auth_provider.dart';

// Widgets
export 'src/widgets/auth_widgets.dart';

// Utils
export 'src/utils/auth_utils.dart';

// Utility Functions (matching React Native SDK exports)
export 'src/utils/auth_utils.dart' show 
  hasRole,
  hasAnyRole, 
  hasAllRoles,
  getUserRoles,
  getUserDisplayName,
  isTokenExpired,
  generateRandomString,
  validateConfig,
  generateCodeVerifier,
  generateCodeChallenge;