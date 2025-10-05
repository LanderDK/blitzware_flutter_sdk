import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlitzWare Flutter SDK Example'),
        actions: [
          BlitzWareLogoutButton(
            text: 'Logout',
            icon: const Icon(Icons.logout, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<BlitzWareAuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          final isLoading = authProvider.isLoading;
          final error = authProvider.error;

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
                  // Title
                  Text(
                    'BlitzWare Flutter SDK Example',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Authentication Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authentication Status:',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLoading
                                ? 'Loading...'
                                : authProvider.isAuthenticated
                                ? 'Authenticated'
                                : 'Not Authenticated',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),

                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Error:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    error.message,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (user != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'User Info:',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('ID', user.id),
                            _buildInfoRow('Email', user.email),
                            _buildInfoRow('Username', user.username),
                            _buildInfoRow(
                              'Roles',
                              user.roleNames.isNotEmpty
                                  ? user.roleNames.join(', ')
                                  : 'N/A',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role-based content
                  if (user != null && authProvider.hasRole('admin')) ...[
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Admin Access',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You have administrator privileges. Check the Admin tab for more options.',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (user != null && authProvider.hasRole('premium')) ...[
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Premium User',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You have premium access to enhanced features.',
                              style: TextStyle(color: Colors.amber.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
