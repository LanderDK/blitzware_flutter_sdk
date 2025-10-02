import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          BlitzWareLogoutButton(
            text: 'Logout',
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<BlitzWareAuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(child: Text('No user data available'));
          }

          // Check if user actually has admin role
          if (!authProvider.hasRole('admin')) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('You need admin privileges to access this area.'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await authProvider.refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Administrator Dashboard',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Welcome, ${user.displayName}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current User Details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, 'User ID', user.id),
                          _buildInfoRow(context, 'Username', user.username),
                          _buildInfoRow(context, 'Email', user.email),
                          _buildInfoRow(context, 'Name', user.additionalProperties?['name'] ?? 'N/A'),
                          _buildInfoRow(
                            context, 
                            'Roles', 
                            user.roleNames.isNotEmpty ? user.roleNames.join(', ') : 'N/A'
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                authProvider.hasRole('admin') ? Icons.check_circle : Icons.cancel,
                                color: authProvider.hasRole('admin') ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Admin Status: ${authProvider.hasRole('admin') ? 'Active' : 'Inactive'}',
                                style: TextStyle(
                                  color: authProvider.hasRole('admin') ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Admin Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Actions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            context,
                            'Validate Access Token',
                            Icons.verified_user,
                            () async {
                              final isValid = await authProvider.validateAccessToken();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Access Token: ${isValid ? 'Valid' : 'Invalid/Expired'}',
                                    ),
                                    backgroundColor: isValid ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            context,
                            'Refresh Token',
                            Icons.refresh,
                            () async {
                              try {
                                final newToken = await authProvider.refreshAccessToken();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        newToken != null 
                                          ? 'Token refreshed successfully' 
                                          : 'Failed to refresh token',
                                      ),
                                      backgroundColor: newToken != null ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error refreshing token: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            context,
                            'Check Role (Premium)',
                            Icons.star,
                            () async {
                              final hasPremium = await authProvider.hasRoleAsync('premium');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Premium Role: ${hasPremium ? 'Yes' : 'No'}',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}