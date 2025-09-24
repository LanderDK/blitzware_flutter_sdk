/// Represents a user role in the BlitzWare system
class BlitzWareRole {
  final String id;
  final String name;
  final String? description;

  const BlitzWareRole({required this.id, required this.name, this.description});

  factory BlitzWareRole.fromJson(Map<String, dynamic> json) {
    return BlitzWareRole(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlitzWareRole &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'BlitzWareRole(id: $id, name: $name)';
}

/// Represents a BlitzWare user
class BlitzWareUser {
  final String sub;
  final String? email;
  final String? username;
  final List<dynamic>? roles;

  const BlitzWareUser({
    required this.sub,
    this.email,
    this.username,
    this.roles,
  });

  factory BlitzWareUser.fromJson(Map<String, dynamic> json) {
    return BlitzWareUser(
      sub: json['sub'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      roles: json['roles'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'sub': sub,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (roles != null) 'roles': roles,
    };

    return json;
  }

  /// Get display name for the user
  String get displayName => username ?? email ?? 'User';

  /// Get list of role names as strings
  List<String> get roleNames {
    if (roles == null) return [];

    return roles!
        .map((role) {
          if (role is String) return role;
          if (role is Map<String, dynamic> && role['name'] != null) {
            return role['name'] as String;
          }
          return '';
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// Check if user has a specific role
  bool hasRole(String roleName) {
    return roleNames.any(
      (role) => role.toLowerCase() == roleName.toLowerCase(),
    );
  }

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<String> roleNames) {
    return roleNames.any((roleName) => hasRole(roleName));
  }

  /// Check if user has all of the specified roles
  bool hasAllRoles(List<String> roleNames) {
    return roleNames.every((roleName) => hasRole(roleName));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlitzWareUser &&
          runtimeType == other.runtimeType &&
          sub == other.sub;

  @override
  int get hashCode => sub.hashCode;

  @override
  String toString() => 'BlitzWareUser(sub: $sub, email: $email, username: $username)';
}
