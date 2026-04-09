import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Account section
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outlined),
            title: Text(authState.user?.email ?? 'Not signed in'),
            subtitle: authState.user != null
                ? Text('UID: ${authState.user!.uid}')
                : null,
          ),
          const Divider(),

          // Storage section
          _SectionHeader(title: 'Storage'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('GCS Bucket'),
            subtitle: const Text('Configure your storage bucket'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to bucket configuration.
            },
          ),
          const Divider(),

          // Cache section
          _SectionHeader(title: 'Cache'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Thumbnail Cache'),
            subtitle: const Text('Max 500 MB'),
            trailing: TextButton(
              onPressed: () {
                // TODO: Clear thumbnail cache.
              },
              child: const Text('Clear'),
            ),
          ),
          const Divider(),

          // Sign out
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
