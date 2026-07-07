import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/design_tokens.dart';
import 'buttons.dart';
import 'inputs.dart';
import 'cards.dart';
import 'loaders.dart';
import 'feedback.dart';
import 'navigation.dart';
import 'dialogs.dart';

class ComponentShowcasePage extends StatefulWidget {
  const ComponentShowcasePage({super.key});

  @override
  State<ComponentShowcasePage> createState() => _ComponentShowcasePageState();
}

class _ComponentShowcasePageState extends State<ComponentShowcasePage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(titleText: 'KAAND DESIGN SYSTEM'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Branding Section
            Center(
              child: Column(
                children: [
                  const SizedBox(height: DesignTokens.spaceM),
                  const Text(
                    'KAAND',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay Connected. Stay Informed.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: DesignTokens.spaceXL),
                ],
              ),
            ),

            const SectionHeader(title: 'Color Palette'),
            const SizedBox(height: DesignTokens.spaceS),
            Wrap(
              spacing: DesignTokens.spaceS,
              runSpacing: DesignTokens.spaceS,
              children: [
                _buildColorChip('Background', AppColors.background),
                _buildColorChip('Surface', AppColors.surface),
                _buildColorChip('Primary', AppColors.primary),
                _buildColorChip('Secondary', AppColors.secondary),
                _buildColorChip('Accent', AppColors.accent),
                _buildColorChip('Text Primary', AppColors.textPrimary),
                _buildColorChip('Text Sec', AppColors.textSecondary),
                _buildColorChip('Success', AppColors.success),
                _buildColorChip('Error', AppColors.error),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceXL),

            const SectionHeader(title: 'Buttons'),
            const SizedBox(height: DesignTokens.spaceS),
            PrimaryButton(
              text: 'Primary Action',
              onPressed: () {
                SnackBarFeedback.showSuccess(context, 'Primary Button Triggered');
              },
            ),
            const SizedBox(height: DesignTokens.spaceM),
            SecondaryButton(
              text: 'Secondary Action',
              onPressed: () {
                SnackBarFeedback.showError(context, 'Secondary Button Triggered');
              },
            ),
            const SizedBox(height: DesignTokens.spaceM),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Loading State',
                    onPressed: () {},
                    isLoading: true,
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceM),
                const Expanded(
                  child: GhostButton(
                    text: 'Ghost Option',
                    icon: Icons.info_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceXL),

            const SectionHeader(title: 'Text Inputs'),
            const SizedBox(height: DesignTokens.spaceS),
            const CustomTextField(
              labelText: 'Display Name',
              hintText: 'Enter your username',
              prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
            ),
            const SizedBox(height: DesignTokens.spaceM),
            const SearchField(hintText: 'Search headlines...'),
            const SizedBox(height: DesignTokens.spaceXL),

            const SectionHeader(title: 'Cards'),
            const SizedBox(height: DesignTokens.spaceS),
            const ElevatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elevated Card',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spaceXS),
                  Text(
                    'This container represents secondary container layouts.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceM),
            const GlassCard(
              showGlow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Glassmorphic Card',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spaceXS),
                  Text(
                    'Backdrop filter blur with glowing obsidian styling.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceM),
            const EmptyCard(text: 'No articles bookmarked yet'),
            const SizedBox(height: DesignTokens.spaceXL),

            const SectionHeader(title: 'Dialogs & Sheets'),
            const SizedBox(height: DesignTokens.spaceS),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Alert Popup',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => CustomAlertDialog(
                          title: 'Clear Cache?',
                          content: 'This will purge all offline stored articles from disk.',
                          confirmText: 'Clear',
                          cancelText: 'Cancel',
                          onConfirm: () {
                            SnackBarFeedback.showSuccess(context, 'Cache purged');
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceM),
                Expanded(
                  child: SecondaryButton(
                    text: 'Bottom Sheet',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CustomBottomSheet(
                          title: 'User Profile Details',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Display Name: John Doe',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                              ),
                              const SizedBox(height: DesignTokens.spaceS),
                              const Text(
                                'Role: Premium Subscriber',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                              const SizedBox(height: DesignTokens.spaceXL),
                              PrimaryButton(
                                text: 'Close Sheet',
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceXL),

            const SectionHeader(title: 'Loaders'),
            const SizedBox(height: DesignTokens.spaceS),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                LottieLoader(
                  assetPath: 'assets/animations/loading.json',
                  size: 80,
                ),
                SkeletonLoader(
                  width: 150,
                  height: 24,
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceXL),

            const SectionHeader(title: 'Feedback States'),
            const SizedBox(height: DesignTokens.spaceS),
            const GlassCard(
              child: EmptyState(
                title: 'Nothing Saved',
                description: 'Your bookmarks collection will show up here.',
                icon: Icons.bookmark_border_rounded,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceM),
            GlassCard(
              child: ErrorState(
                title: 'Connection Dropped',
                message: 'Verify network settings and try fetching headlines again.',
                onRetry: () {
                  SnackBarFeedback.showSuccess(context, 'Retrying connection...');
                },
              ),
            ),
            const SizedBox(height: DesignTokens.spaceXL),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) {
          setState(() {
            _navIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookmarks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildColorChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color.computeLuminance() > 0.6 ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
