import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth.dart';
import '../providers/auth_provider.dart';

/// Widget that shows different content based on authentication state
class AuthStateBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) authenticated;
  final Widget Function(BuildContext context) unauthenticated;
  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context, BlitzWareException error)? error;

  const AuthStateBuilder({
    super.key,
    required this.authenticated,
    required this.unauthenticated,
    this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.state) {
          case AuthenticationState.loading:
            return loading?.call(context) ?? const Center(child: CircularProgressIndicator());
          
          case AuthenticationState.authenticated:
            return authenticated(context);
          
          case AuthenticationState.unauthenticated:
            return unauthenticated(context);
          
          case AuthenticationState.error:
            if (error != null && authProvider.error != null) {
              return error!(context, authProvider.error!);
            }
            return unauthenticated(context);
          
          case AuthenticationState.unknown:
            return loading?.call(context) ?? const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

/// Widget that only shows content when user is authenticated
class AuthenticatedGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AuthenticatedGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget that only shows content when user is unauthenticated
class UnauthenticatedGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const UnauthenticatedGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isUnauthenticated) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget that shows content based on user roles
class RoleGuard extends StatelessWidget {
  final String? role;
  final List<String>? roles;
  final bool requireAll;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    this.role,
    this.roles,
    this.requireAll = false,
    required this.child,
    this.fallback,
  }) : assert(role != null || roles != null, 'Either role or roles must be provided');

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        bool hasAccess = false;

        if (role != null) {
          hasAccess = authProvider.hasRole(role!);
        } else if (roles != null) {
          hasAccess = requireAll
              ? authProvider.hasAllRoles(roles!)
              : authProvider.hasAnyRole(roles!);
        }

        if (hasAccess) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget that shows different content for different roles
class RoleBasedBuilder extends StatelessWidget {
  final Map<String, Widget Function(BuildContext context)> roleBuilders;
  final Widget Function(BuildContext context)? defaultBuilder;

  const RoleBasedBuilder({
    super.key,
    required this.roleBuilders,
    this.defaultBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        // Check roles in order and return first match
        for (final entry in roleBuilders.entries) {
          if (authProvider.hasRole(entry.key)) {
            return entry.value(context);
          }
        }

        // Return default if no role matches
        return defaultBuilder?.call(context) ?? const SizedBox.shrink();
      },
    );
  }
}

/// Login button widget with built-in loading state
class BlitzWareLoginButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool showLoadingIndicator;

  const BlitzWareLoginButton({
    super.key,
    this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.showLoadingIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        final isLoading = authProvider.isLoading && showLoadingIndicator;
        
        return ElevatedButton(
          onPressed: isLoading ? null : (onPressed ?? () => authProvider.login()),
          style: style,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(text ?? 'Login with BlitzWare'),
                  ],
                ),
        );
      },
    );
  }
}

/// Logout button widget with built-in loading state
class BlitzWareLogoutButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool showLoadingIndicator;

  const BlitzWareLogoutButton({
    super.key,
    this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.showLoadingIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        final isLoading = authProvider.isLoading && showLoadingIndicator;
        
        return ElevatedButton(
          onPressed: isLoading ? null : (onPressed ?? () => authProvider.logout()),
          style: style,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(text ?? 'Logout'),
                  ],
                ),
        );
      },
    );
  }
}

/// User info display widget
class UserInfoDisplay extends StatelessWidget {
  final TextStyle? nameStyle;
  final TextStyle? emailStyle;
  final Widget? avatar;
  final bool showRoles;
  final EdgeInsetsGeometry? padding;

  const UserInfoDisplay({
    super.key,
    this.nameStyle,
    this.emailStyle,
    this.avatar,
    this.showRoles = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BlitzWareAuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Row(
            children: [
              if (avatar != null) ...[
                avatar!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName,
                      style: nameStyle ?? Theme.of(context).textTheme.titleMedium,
                    ),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: emailStyle ?? Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (showRoles && user.roleNames.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: user.roleNames
                            .map((role) => Chip(
                                  label: Text(role),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}