import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blitzware_flutter_sdk/blitzware_flutter_sdk.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlitzWare SDK Test'),
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
                    'BlitzWare SDK Test',
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    error.message,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (user != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'User Info:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('ID', user.id),
                            _buildInfoRow('Email', user.email),
                            _buildInfoRow('Username', user.username),
                            _buildInfoRow(
                              'Roles', 
                              user.roleNames.isNotEmpty ? user.roleNames.join(', ') : 'N/A'
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
                                Icon(Icons.admin_panel_settings, color: Colors.red.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Admin Access',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildWelcomeCard(BuildContext context, BlitzWareUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (user.email != null)
                        Text(
                          user.email!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (user.roleNames.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Your Roles:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: user.roleNames
                    .map((role) => Chip(
                          label: Text(role),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.amber[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Admin Dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You have administrative access to the system',
              style: TextStyle(
                fontSize: 16,
                color: Colors.amber[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureList([
              'User Management',
              'System Settings',
              'Analytics & Reports',
              'Security Logs',
              'Database Administration',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSection(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.blue[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Premium Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enjoy your premium subscription benefits',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureList([
              'Advanced Analytics',
              'Priority Support',
              'Custom Themes',
              'Export Features',
              'Advanced Integrations',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context, BlitzWareUser user) {
    final isPremium = user.isPremium;
    final isAdmin = user.isAdmin;

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.green[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'User Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Available features for all authenticated users',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureList([
              'Profile Management',
              'Basic Dashboard',
              'Support Tickets',
              'Account Settings',
            ]),
            if (!isPremium && !isAdmin) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consider upgrading to premium for more features!',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontStyle: FontStyle.italic,
                        ),
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

  Widget _buildRoleSummary(BuildContext context, BlitzWareAuthProvider authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Access Level',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRoleIndicator(
                  context,
                  'Admin',
                  authProvider.isAdmin,
                  Icons.admin_panel_settings,
                ),
                _buildRoleIndicator(
                  context,
                  'Premium',
                  authProvider.isPremium,
                  Icons.star,
                ),
                _buildRoleIndicator(
                  context,
                  'User',
                  true, // Always true for authenticated users
                  Icons.person,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleIndicator(
    BuildContext context,
    String label,
    bool isActive,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[600],
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return Column(
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ))
          .toList(),
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