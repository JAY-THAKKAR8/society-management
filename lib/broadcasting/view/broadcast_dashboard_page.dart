import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/broadcasting/model/broadcast_model.dart';
import 'package:society_management/broadcasting/repository/i_broadcast_repository.dart';
import 'package:society_management/broadcasting/service/broadcast_service.dart';
import 'package:society_management/broadcasting/view/create_broadcast_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class BroadcastDashboardPage extends StatefulWidget {
  const BroadcastDashboardPage({super.key});

  @override
  State<BroadcastDashboardPage> createState() => _BroadcastDashboardPageState();
}

class _BroadcastDashboardPageState extends State<BroadcastDashboardPage> {
  final BroadcastService _broadcastService = getIt<BroadcastService>();
  final IBroadcastRepository _broadcastRepository = getIt<IBroadcastRepository>();
  List<BroadcastModel> _broadcasts = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Emergency', 'Announcement', 'Maintenance', 'Event'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load recent broadcasts
      final broadcastsResult = await _broadcastRepository.getRecentBroadcasts(limit: 20);
      broadcastsResult.fold(
        (failure) => Utility.toast(message: 'Error loading broadcasts: ${failure.message}'),
        (broadcasts) => _broadcasts = broadcasts,
      );

      // Load analytics
      _analytics = await _broadcastService.getDashboardStats();
    } catch (e) {
      Utility.toast(message: 'Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: CommonAppBar(
        title: '📢 Broadcasting Center',
        showDivider: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      floatingActionButton: _buildCreateBroadcastFAB(context),
      body: _isLoading
          ? _buildLoadingState(context)
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(context),
                    const Gap(20),
                    _buildQuickStatsCards(context),
                    const Gap(24),
                    _buildQuickActionsGrid(context),
                    const Gap(24),
                    _buildFilterSection(context),
                    const Gap(16),
                    _buildBroadcastsList(context),
                    const Gap(80), // Space for FAB
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnalyticsSection() {
    final weeklyStats = _analytics['weekly'] ?? {};
    final monthlyStats = _analytics['monthly'] ?? {};

    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primaryBlue),
                Gap(8),
                Text(
                  'Broadcasting Analytics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'This Week',
                    '${weeklyStats['total_broadcasts'] ?? 0}',
                    'Broadcasts',
                    Icons.campaign,
                    AppColors.primaryBlue,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildStatCard(
                    'This Month',
                    '${monthlyStats['total_broadcasts'] ?? 0}',
                    'Broadcasts',
                    Icons.calendar_month,
                    AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Delivery Rate',
                    '${weeklyStats['delivery_rate'] ?? '0.0'}%',
                    'This Week',
                    Icons.send,
                    AppColors.primaryOrange,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildStatCard(
                    'Read Rate',
                    '${weeklyStats['read_rate'] ?? '0.0'}%',
                    'This Week',
                    Icons.mark_email_read,
                    AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Gap(4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.primaryOrange),
                Gap(8),
                Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Emergency Alert',
                    Icons.warning,
                    Colors.red,
                    () => _createQuickBroadcast(BroadcastType.emergency),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Announcement',
                    Icons.campaign,
                    AppColors.primaryBlue,
                    () => _createQuickBroadcast(BroadcastType.announcement),
                  ),
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Maintenance Notice',
                    Icons.build,
                    AppColors.primaryOrange,
                    () => _createQuickBroadcast(BroadcastType.maintenance),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Event Invitation',
                    Icons.event,
                    AppColors.primaryGreen,
                    () => _createQuickBroadcast(BroadcastType.event),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const Gap(4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBroadcastsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: AppColors.primaryBlue),
                Gap(8),
                Text(
                  'Recent Broadcasts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // Navigate to full broadcast history
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const Gap(12),
        if (_broadcasts.isEmpty)
          ThemeAwareCard(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.campaign_outlined, size: 48, color: Colors.grey[400]),
                    const Gap(8),
                    Text(
                      'No broadcasts yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const Gap(4),
                    Text(
                      'Create your first broadcast to get started',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_broadcasts.take(5).map((broadcast) => _buildBroadcastCard(broadcast))),
      ],
    );
  }

  Widget _buildBroadcastCard(BroadcastModel broadcast) {
    return ThemeAwareCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(broadcast.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                broadcast.type.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    broadcast.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    broadcast.message,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 12, color: Colors.grey[500]),
                      const Gap(2),
                      Text(
                        broadcast.creatorName,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      const Gap(8),
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      const Gap(2),
                      Text(
                        _formatDate(broadcast.createdAt),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(broadcast.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                broadcast.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  color: _getStatusColor(broadcast.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(BroadcastType type) {
    switch (type) {
      case BroadcastType.emergency:
        return Colors.red;
      case BroadcastType.announcement:
        return AppColors.primaryBlue;
      case BroadcastType.maintenance:
        return AppColors.primaryOrange;
      case BroadcastType.event:
        return AppColors.primaryGreen;
      case BroadcastType.reminder:
        return AppColors.primaryPurple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(BroadcastStatus status) {
    switch (status) {
      case BroadcastStatus.sent:
        return AppColors.primaryGreen;
      case BroadcastStatus.scheduled:
        return AppColors.primaryOrange;
      case BroadcastStatus.draft:
        return Colors.grey;
      case BroadcastStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _createQuickBroadcast(BroadcastType type) async {
    final result = await context.push(CreateBroadcastPage(initialType: type));
    if (result == true) {
      _loadData();
    }
  }

  // New User-Friendly Methods
  Widget _buildCreateBroadcastFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await context.push(const CreateBroadcastPage());
        if (result == true) {
          _loadData();
        }
      },
      backgroundColor: AppColors.primaryBlue,
      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
      label: const Text(
        'Create Broadcast',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      elevation: 4,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
          const Gap(16),
          Text(
            'Loading broadcasts...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Broadcasting',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  'Send announcements, alerts, and updates to your community',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards(BuildContext context) {
    final weeklyStats = _analytics['weekly'] ?? {};
    final monthlyStats = _analytics['monthly'] ?? {};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildModernStatCard(
            context,
            'Week',
            '${weeklyStats['total_broadcasts'] ?? 0}',
            'Broadcasts',
            Icons.campaign_rounded,
            AppColors.primaryBlue,
          ),
          const Gap(12),
          _buildModernStatCard(
            context,
            'Month',
            '${monthlyStats['total_broadcasts'] ?? 0}',
            'Total Sent',
            Icons.send_rounded,
            AppColors.primaryGreen,
          ),
          const Gap(12),
          _buildModernStatCard(
            context,
            'Success',
            '${weeklyStats['delivery_rate'] ?? '0.0'}%',
            'Delivered',
            Icons.check_circle_rounded,
            AppColors.primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(
      BuildContext context, String title, String value, String subtitle, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 120, // Fixed width to prevent overflow
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const Gap(8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const Gap(2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: AppColors.primaryOrange, size: 24),
            const Gap(8),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const Gap(16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4, // Adjusted for better fit
          children: [
            _buildQuickActionCard(
              context,
              'Emergency',
              '🚨',
              'Urgent alerts',
              AppColors.primaryRed,
              () => _createQuickBroadcast(BroadcastType.emergency),
            ),
            _buildQuickActionCard(
              context,
              'Announcement',
              '📢',
              'General news',
              AppColors.primaryBlue,
              () => _createQuickBroadcast(BroadcastType.announcement),
            ),
            _buildQuickActionCard(
              context,
              'Maintenance',
              '🔧',
              'Service notices',
              AppColors.primaryOrange,
              () => _createQuickBroadcast(BroadcastType.maintenance),
            ),
            _buildQuickActionCard(
              context,
              'Event',
              '🎉',
              'Invitations',
              AppColors.primaryGreen,
              () => _createQuickBroadcast(BroadcastType.event),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
      BuildContext context, String title, String emoji, String subtitle, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: color, size: 14),
              ],
            ),
            const Gap(8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.filter_list_rounded, color: AppColors.primaryBlue, size: 24),
            const Gap(8),
            Text(
              'Recent Broadcasts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_broadcasts.length} broadcasts',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const Gap(12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filterOptions.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  selectedColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  checkmarkColor: AppColors.primaryBlue,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.grey[300] : Colors.grey[700]),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBroadcastsList(BuildContext context) {
    if (_broadcasts.isEmpty) {
      return _buildEmptyState(context);
    }

    final filteredBroadcasts = _selectedFilter == 'All'
        ? _broadcasts
        : _broadcasts.where((b) => b.type.displayName == _selectedFilter).toList();

    if (filteredBroadcasts.isEmpty) {
      return _buildEmptyFilterState(context);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredBroadcasts.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final broadcast = filteredBroadcasts[index];
        return _buildModernBroadcastCard(context, broadcast);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const Gap(16),
          Text(
            'No broadcasts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
          const Gap(8),
          Text(
            'Create your first broadcast to get started',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await context.push(const CreateBroadcastPage());
              if (result == true) {
                _loadData();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Broadcast'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.filter_list_off,
            size: 48,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const Gap(16),
          Text(
            'No $_selectedFilter broadcasts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
          const Gap(8),
          Text(
            'Try selecting a different filter',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBroadcastCard(BuildContext context, BroadcastModel broadcast) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _getTypeColor(broadcast.type);
    final statusColor = _getStatusColor(broadcast.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      broadcast.type.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Gap(4),
                    Text(
                      broadcast.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  broadcast.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            broadcast.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Gap(8),
          Text(
            broadcast.message,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(12),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              const Gap(4),
              Flexible(
                child: Text(
                  broadcast.creatorName,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(16),
              Icon(
                Icons.access_time,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              const Gap(4),
              Text(
                _formatDateTime(broadcast.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              const Spacer(),
              if (broadcast.target != BroadcastTarget.all)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    broadcast.target.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
