import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showAccessToken = false;
  String? _accessToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final authProvider = context.read<BlitzWareAuthProvider>();
              await authProvider.refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile refreshed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<BlitzWareAuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: Text('No user data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Information Section
                _buildUserInfoSection(context, user),
                const SizedBox(height: 16),

                // Account Details Section
                _buildAccountDetailsSection(context, user),
                const SizedBox(height: 16),

                // Roles Section
                _buildRolesSection(context, user),
                const SizedBox(height: 16),

                // Access Token Section
                _buildAccessTokenSection(context, authProvider),
                const SizedBox(height: 16),

                // Raw Data Section
                _buildRawDataSection(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context, BlitzWareUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('User ID', user.id),
                      _buildInfoRow('Username', user.username),
                      _buildInfoRow('Email', user.email),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetailsSection(BuildContext context, BlitzWareUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesSection(BuildContext context, BlitzWareUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roles & Permissions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (user.roleNames.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.roleNames
                    .map(
                      (role) => Chip(
                        label: Text(role),
                        avatar: Icon(
                          _getRoleIcon(role),
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _buildRoleCapabilities(context, user),
            ] else ...[
              Text(
                'No roles assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCapabilities(BuildContext context, BlitzWareUser user) {
    final capabilities = <String>[];

    if (user.isAdmin) {
      capabilities.addAll([
        'System Administration',
        'User Management',
        'Full Access',
      ]);
    }

    if (user.isPremium) {
      capabilities.addAll([
        'Premium Features',
        'Priority Support',
        'Advanced Analytics',
      ]);
    }

    if (user.isModerator) {
      capabilities.addAll(['Content Moderation', 'Community Management']);
    }

    if (capabilities.isEmpty) {
      capabilities.add('Basic User Access');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capabilities:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...capabilities
            .map(
              (capability) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(capability),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildAccessTokenSection(
    BuildContext context,
    BlitzWareAuthProvider authProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Access Token',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (_showAccessToken) {
                  setState(() {
                    _showAccessToken = false;
                    _accessToken = null;
                  });
                } else {
                  final token = await authProvider.getAccessToken();
                  setState(() {
                    _showAccessToken = true;
                    _accessToken = token;
                  });
                }
              },
              icon: Icon(
                _showAccessToken ? Icons.visibility_off : Icons.visibility,
              ),
              label: Text(
                _showAccessToken ? 'Hide Token' : 'Show Access Token',
              ),
            ),
            if (_showAccessToken && _accessToken != null) ...[
              const SizedBox(height: 16),
              Text(
                'Current Access Token:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _accessToken!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _accessToken!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Token copied to clipboard'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Copy',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ Keep this token secure and never share it publicly',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRawDataSection(BuildContext context, BlitzWareUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raw User Data',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.toJson().toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'premium':
        return Icons.star;
      case 'moderator':
        return Icons.security;
      case 'user':
        return Icons.person;
      default:
        return Icons.label;
    }
  }
}
