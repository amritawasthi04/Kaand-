import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/hive_cache.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final name = Provider.of<UserProvider>(context, listen: false).name;
    _controller.text = name;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile settings header
          const Text(
            'User Profile',
            style: TextStyle(
              color: AppColors.highlight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintStyle: TextStyle(color: AppColors.mutedText),
                      labelStyle: TextStyle(color: AppColors.mutedText),
                    ),
                    style: const TextStyle(color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (_controller.text.trim().isNotEmpty) {
                          await userProvider.saveName(_controller.text);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name updated successfully!')),
                            );
                          }
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Cache control header
          const Text(
            'System Cache',
            style: TextStyle(
              color: AppColors.highlight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text(
                'Clear Offline Cache',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: const Text(
                'Delete all locally cached scraped articles',
                style: TextStyle(color: AppColors.mutedText),
              ),
              trailing: const Icon(Icons.delete_outline, color: AppColors.error),
              onTap: () async {
                await HiveCache().clearCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Offline cache cleared successfully!')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 32),

          // Application meta
          const Text(
            'About',
            style: TextStyle(
              color: AppColors.highlight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Version', style: TextStyle(color: AppColors.secondaryText)),
                      Text('1.0.0', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Developer', style: TextStyle(color: AppColors.secondaryText)),
                      Text('Solo Dev', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
