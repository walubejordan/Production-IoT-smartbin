import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import '../notifications_screen.dart';
import '../settings_screen.dart';
import 'bin_list_screen.dart';
import 'create_bin_screen.dart';
import 'collectors_list_screen.dart';
import 'create_user_screen.dart';
import 'admin_map_view_screen.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_icon.dart';
import '../../theme/app_colors.dart';
import '../../widgets/notification_bell_with_badge.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  int _unreadCount = 0;
  static const double _wideBreakpoint = 900;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getNotifications(isRead: false, limit: 1);
      if (!mounted) return;
      setState(() {
        _unreadCount = (data['unread_count'] ?? 0) as int;
      });
    } catch (_) {
      // If unread count fails, don't block the dashboard.
    }
  }

  Future<void> _loadDashboard() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final data = await apiService.getAdminDashboard();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.logout();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.headerText,
        elevation: 0,
        automaticallyImplyLeading: !isWide,
        actions: [
          NotificationBellWithBadge(
            unreadCount: _unreadCount,
            icon: Icons.notifications,
            iconColor: AppColors.headerText,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              if (!mounted) return;
              _loadUnreadCount();
            },
          ),
        ],
      ),
      // On mobile, show a hamburger drawer (left). On wide web, show a permanent left rail.
      drawer: isWide ? null : _buildDrawer(),
      body: isWide ? _buildWideBody() : _buildNarrowBody(),
      // On narrow/mobile, keep bottom tabs for main 3 screens.
      bottomNavigationBar: !isWide && _selectedIndex <= 2
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryGreen,
              unselectedItemColor: Colors.grey,
              items: [
                BottomNavigationBarItem(
                  icon: _navAssetIcon('assets/reference/dashboard-ref.png'),
                  activeIcon: _navAssetIcon(
                    'assets/reference/dashboard-ref.png',
                    active: true,
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: _navAssetIcon('assets/reference/recycle-bin.png'),
                  activeIcon: _navAssetIcon(
                    'assets/reference/recycle-bin.png',
                    active: true,
                  ),
                  label: 'Bins',
                ),
                BottomNavigationBarItem(
                  icon: _navAssetIcon('assets/reference/profile.png'),
                  activeIcon: _navAssetIcon(
                    'assets/reference/profile.png',
                    active: true,
                  ),
                  label: 'Collectors',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildNarrowBody() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildContent();
  }

  Widget _buildWideBody() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex.clamp(0, 6),
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          labelType: NavigationRailLabelType.all,
          backgroundColor: Colors.white,
          destinations: [
            NavigationRailDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: _navAssetIcon('assets/reference/recycle-bin.png'),
              selectedIcon: _navAssetIcon(
                'assets/reference/recycle-bin.png',
                active: true,
              ),
              label: Text('Bins'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: Text('Truck'),
            ),
            NavigationRailDestination(
              icon: _navAssetIcon('assets/reference/profile.png'),
              selectedIcon: _navAssetIcon(
                'assets/reference/profile.png',
                active: true,
              ),
              label: Text('Profile'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: Text('Map'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.person_add_outlined),
              selectedIcon: Icon(Icons.person_add),
              label: Text('Add User'),
            ),
            NavigationRailDestination(
              icon: _navAssetIcon('assets/reference/analytics.png'),
              selectedIcon: _navAssetIcon(
                'assets/reference/analytics.png',
                active: true,
              ),
              label: Text('Analytics'),
            ),
          ],
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: _logout,
                ),
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _buildNarrowBody(),
        ),
      ],
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'SmartBin Dashboard';
      case 1:
        return 'Manage Bins';
      case 2:
        return 'Fleet Team';
      case 3:
        return 'User Profile';
      case 4:
        return 'Bins Map';
      case 5:
        return 'Add New Bin';
      case 6:
        return 'System Analytics';
      default:
        return 'SmartBin Admin';
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.scaffoldBackground,
                  child: Text(
                    widget.user['name'].toString().isNotEmpty
                        ? widget.user['name'][0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user['name'] ?? 'Admin',
                  style: const TextStyle(
                    color: AppColors.headerText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.user['email'] ?? '',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Bins Map'),
            selected: _selectedIndex == 3,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Bin'),
            selected: _selectedIndex == 4,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 4);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add_outlined),
            title: const Text('Add User'),
            selected: _selectedIndex == 5,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 5);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Analytics'),
            selected: _selectedIndex == 6,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 6);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(user: widget.user),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_dashboardData == null) {
      return const Center(child: Text('No data available'));
    }

    // FIX: Aligned case numbers with Drawer logic
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return BinListScreen(user: widget.user);
      case 2:
        return CollectorsListScreen(user: widget.user);
      case 3:
        return SettingsScreen(user: widget.user);
      case 4:
        return AdminMapViewScreen(user: widget.user);
      case 5:
        return CreateBinScreen(user: widget.user);
      case 6:
        return _buildAnalytics();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final overview = _dashboardData!['overview'];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.user['name'].toString().isNotEmpty
                          ? widget.user['name'][0].toUpperCase()
                          : 'A',
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
                          'Welcome back, ${widget.user['name']}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Here\'s your system overview',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'System Statistics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTopStatCard(
                    'Total Vehicles',
                    overview['total_collectors'].toString(),
                    Icons.local_shipping,
                  ),
                  _buildTopStatCard(
                    'Employees',
                    overview['total_collectors'].toString(),
                    Icons.groups_rounded,
                  ),
                  _buildTopStatCard(
                    'Bins',
                    overview['total_bins'].toString(),
                    Icons.delete_outline,
                  ),
                  _buildTopStatCard(
                    'Zones',
                    (overview['zones'] ?? 0).toString(),
                    Icons.map_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Builder(
                builder: (context) {
                  final recentActivity =
                      _dashboardData!['recent_collections'] as List<dynamic>? ??
                          [];

                  if (recentActivity.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No recent activity available'),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentActivity.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = recentActivity[index];
                      final time = item['collection_time'] ?? '';
                      final binCode = item['bin_code'] ?? 'Unknown Bin';
                      final collector =
                          item['collector_name'] ?? 'Unknown Collector';
                      final location = item['location'] ?? 'Unknown Location';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getActivityColor(index).withOpacity(0.1),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: _getActivityColor(index),
                          ),
                        ),
                        title: Text('$binCode • $location'),
                        subtitle: Text('$collector • ${_formatDateTime(time)}'),
                        trailing: const Icon(Icons.chevron_right),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatCard(String title, String value, IconData icon) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
              child: Icon(icon, size: 16, color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navAssetIcon(String asset, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryGreen.withOpacity(0.12) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Image.asset(asset, width: 18, height: 18),
    );
  }

  Widget _buildAnimatedStatCard(
      String title, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusIcon(
                      icon: icon,
                      color: color,
                      size: 20,
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getActivityColor(int index) {
    switch (index % 3) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  double _dashboardValueToDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';

    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  Widget _buildAnalytics() {
    if (_dashboardData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final dailyCollections =
        _dashboardData!['daily_collections'] as List<dynamic>? ?? [];
    final topCollectors =
        _dashboardData!['top_collectors'] as List<dynamic>? ?? [];
    final binsByStatus =
        _dashboardData!['bins_by_status'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Analytics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Daily Collections Dark Bar Chart
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Collections (Last 7 Days)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups:
                              dailyCollections.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: _dashboardValueToDouble(
                                    entry.value['count'],
                                  ),
                                  color: Colors.white,
                                  width: 10,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Smooth Area Wave Chart
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bin Collection Trend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots:
                                dailyCollections.asMap().entries.map((entry) {
                              return FlSpot(
                                entry.key.toDouble(),
                                _dashboardValueToDouble(entry.value['count']),
                              );
                            }).toList(),
                            isCurved: true,
                            color: AppColors.primaryGreen,
                            barWidth: 4,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primaryGreen.withOpacity(0.2),
                            ),
                          ),
                        ],
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Top Collectors
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Collectors (This Month)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...topCollectors.map((collector) {
                    final name = collector['name'] as String? ?? 'Unknown';
                    final collections = collector['collections'] as int? ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(name),
                      trailing: Text(
                        '$collections collections',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    );
                  }),
                  if (topCollectors.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No collection data available'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      case 'empty':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
