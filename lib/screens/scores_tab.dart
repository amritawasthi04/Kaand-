import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/scores_provider.dart';
import '../models/sports_score.dart';
import '../theme/app_colors.dart';
import '../core/responsive.dart';

class ScoresTab extends StatefulWidget {
  const ScoresTab({super.key});

  @override
  State<ScoresTab> createState() => _ScoresTabState();
}

class _ScoresTabState extends State<ScoresTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScoresProvider>().loadScores();
      context.read<ScoresProvider>().startAutoRefresh();
    });
  }

  @override
  void dispose() {
    context.read<ScoresProvider>().stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ScoresProvider>(
      builder: (context, provider, _) {
        if (provider.status == ScoresStatus.loading && provider.liveScores.isEmpty) {
          return _buildShimmerList();
        }

        if (provider.status == ScoresStatus.error && provider.liveScores.isEmpty) {
          return _buildErrorState(provider.errorMessage);
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadScores(),
          color: AppColors.brand,
          backgroundColor: AppColors.onboardingSurface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              
              // Live Matches Section
              if (provider.liveScores.any((s) => s.isLive)) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('LIVE NOW', Icons.live_tv_rounded, AppColors.live),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final liveMatches = provider.liveScores.where((s) => s.isLive).toList();
                      return _buildScoreCard(liveMatches[index], isLive: true)
                          .animate()
                          .fadeIn(delay: (100 * index).ms)
                          .slideY(begin: 0.2);
                    },
                    childCount: provider.liveScores.where((s) => s.isLive).length,
                  ),
                ),
              ],
              
              // Cricket Section
              if (provider.cricketScores.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('CRICKET', Icons.sports_cricket_rounded, AppColors.brand),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildScoreCard(provider.cricketScores[index])
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideY(begin: 0.15),
                    childCount: provider.cricketScores.length,
                  ),
                ),
              ],
              
              // Football Section
              if (provider.footballScores.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('FOOTBALL', Icons.sports_soccer_rounded, AppColors.onboardingAccent),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildScoreCard(provider.footballScores[index])
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideY(begin: 0.15),
                    childCount: provider.footballScores.length,
                  ),
                ),
              ],
              
              // Other Sports Section
              if (provider.otherScores.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('OTHER SPORTS', Icons.sports_rounded, Colors.amber),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildScoreCard(provider.otherScores[index])
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideY(begin: 0.15),
                    childCount: provider.otherScores.length,
                  ),
                ),
              ],
              
              // Empty state
              if (provider.liveScores.isEmpty && provider.status == ScoresStatus.success)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                ),
              
              // Bottom padding for nav bar
              SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.navClearance(context)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.horizontal,
        AppSpacing.lg,
        AppSpacing.horizontal,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Scores',
                style: AppFonts.sg(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time match updates',
                style: AppFonts.sg(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          Consumer<ScoresProvider>(
            builder: (context, provider, _) {
              final liveCount = provider.liveScores.where((s) => s.isLive).length;
              final List<Widget> leadingWidgets = liveCount > 0
                  ? [
                      _buildPulseDot(AppColors.live),
                      const SizedBox(width: 6),
                    ]
                  : [
                      Icon(Icons.refresh_rounded, size: 14, color: AppColors.brand),
                      const SizedBox(width: 6),
                    ];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: liveCount > 0 ? AppColors.live.withOpacity(0.15) : AppColors.brand.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: liveCount > 0 ? AppColors.live.withOpacity(0.5) : AppColors.brand.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...leadingWidgets,
                    Text(
                      liveCount > 0 ? '$liveCount Live' : 'Auto-refresh',
                      style: AppFonts.sg(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: liveCount > 0 ? AppColors.live : AppColors.brand,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPulseDot(Color color) {
    return SizedBox(
      width: 8,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 1000.ms)
      .fadeOut(duration: 1000.ms);
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.horizontal,
        AppSpacing.lg,
        AppSpacing.horizontal,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppFonts.sg(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(SportsScore score, {bool isLive = false}) {
    final isCricket = score.sport == 'cricket';
    final statusColor = isLive ? AppColors.live : 
        score.status == 'final' ? Colors.green : 
        score.status == 'scheduled' ? Colors.orange : Colors.white60;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: score.matchUrl != null ? () {
          // Open match details
          _showMatchDetails(score);
        } : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.onboardingSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLive 
                  ? AppColors.live.withOpacity(0.4)
                  : Colors.white.withOpacity(0.08),
              width: isLive ? 1.5 : 1,
            ),
            boxShadow: isLive ? [
              BoxShadow(
                color: AppColors.live.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Teams and Score Row
                Row(
                  children: [
                    // Home Team
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (score.imageUrl != null) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(score.imageUrl!),
                                  backgroundColor: AppColors.onboardingPrimary.withOpacity(0.2),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  score.homeTeam,
                                  style: AppFonts.sg(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (score.inning != null || score.overs != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              isCricket 
                                  ? '${score.inning ?? ''} ${score.overs ?? ''}'.trim()
                                  : score.venue ?? '',
                              style: AppFonts.sg(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLive 
                            ? AppColors.live.withOpacity(0.15)
                            : AppColors.onboardingPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLive 
                              ? AppColors.live.withOpacity(0.3)
                              : AppColors.brand.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            score.scoreDisplay,
                            style: AppFonts.sg(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isLive ? AppColors.live : Colors.white,
                            ),
                          ),
                          if (score.commentary != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              score.commentary!,
                              style: AppFonts.sg(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Away Team
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  score.awayTeam,
                                  style: AppFonts.sg(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                              if (score.imageUrl != null) ...[
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(score.imageUrl!),
                                  backgroundColor: AppColors.onboardingPrimary.withOpacity(0.2),
                                ),
                              ],
                            ],
                          ),
                          if (score.tournament != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              score.tournament!,
                              style: AppFonts.sg(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Status and Meta Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) Transform.scale(scale: 0.7, child: _buildPulseDot(statusColor)),
                          if (isLive) const SizedBox(width: 4),
                          Text(
                            score.shortStatus,
                            style: AppFonts.sg(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // League
                    Text(
                      score.league,
                      style: AppFonts.sg(
                        fontSize: 11,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Time
                    if (score.startTime != null)
                      Text(
                        _formatTime(score.startTime!),
                        style: AppFonts.sg(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);
    if (diff.isNegative) return 'Started';
    if (diff.inHours > 24) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }

  void _showMatchDetails(SportsScore score) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MatchDetailsSheet(score: score),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_off_rounded, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              'Unable to load scores',
              style: AppFonts.sg(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppFonts.sg(fontSize: 14, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<ScoresProvider>().loadScores(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No live matches at the moment',
              style: AppFonts.sg(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Text(
              'Scores will appear when matches are live',
              style: AppFonts.sg(fontSize: 14, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Consumer<ScoresProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(AppSpacing.horizontal, 0, AppSpacing.horizontal, AppSpacing.navClearance(context)),
          itemCount: 5,
          itemBuilder: (context, index) => _buildShimmerCard().animate().fadeIn(delay: (100 * index).ms),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.white12,
        highlightColor: Colors.white24,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _MatchDetailsSheet extends StatelessWidget {
  final SportsScore score;
  const _MatchDetailsSheet({required this.score});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.onboardingSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              score.homeTeam,
                              style: AppFonts.sg(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(score.tournament ?? score.league, style: AppFonts.sg(fontSize: 13, color: Colors.white54)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            score.scoreDisplay,
                            style: AppFonts.sg(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.live),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.live.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('LIVE', style: AppFonts.sg(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.live)),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              score.awayTeam,
                              style: AppFonts.sg(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                              textAlign: TextAlign.end,
                            ),
                            Text(score.venue ?? '', style: AppFonts.sg(fontSize: 13, color: Colors.white54), textAlign: TextAlign.end),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white12),
            
            // Details
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  if (score.commentary != null) ...[
                    Text('Latest Commentary', style: AppFonts.sg(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.onboardingPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(score.commentary!, style: AppFonts.sg(fontSize: 14, color: Colors.white, height: 1.5)),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  if (score.inning != null || score.overs != null) ...[
                    _buildDetailRow('Inning', score.inning ?? '-'),
                    _buildDetailRow('Overs', score.overs ?? '-'),
                    const SizedBox(height: 12),
                  ],
                  
                  _buildDetailRow('League', score.league),
                  _buildDetailRow('Sport', score.sport?.toUpperCase() ?? '-'),
                  if (score.startTime != null)
                    _buildDetailRow('Start Time', _formatDateTime(score.startTime!)),
                  if (score.matchUrl != null)
                    _buildDetailRow('Match URL', score.matchUrl!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppFonts.sg(fontSize: 14, color: Colors.white54)),
          ),
          Expanded(child: Text(value, style: AppFonts.sg(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white))),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}