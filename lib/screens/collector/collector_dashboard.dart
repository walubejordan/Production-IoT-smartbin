import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/mqtt_service.dart';
import '../login_screen.dart';
import '../notifications_screen.dart';
import '../settings_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/liquid_linear_progress_indicator.dart';
import '../../widgets/status_icon.dart';
import 'map_view_screen.dart';
import 'collection_history_screen.dart';

class CollectorDashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const CollectorDashboard({super.key, required this.user});

  @override
  State<CollectorDashboard> createState() => _CollectorDashboardState();
}

class _CollectorDashboardState extends State<CollectorDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _bins = [];
  bool _isLoading = true;
  static const double _wideBreakpoint = 900;

  // Helper to get titles for the AppBar
  final List<String> _titles = [
    'Collector Dashboard',
    'My Assigned Bins',
    'Bin Locations Map',
    'Collection History',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupMqtt();
  }

  void _setupMqtt() {
    final mqttService = Provider.of<MqttService>(context, listen: false);
    mqttService.onNotificationReceived = (notification) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notification['message'] ?? 'New notification'),
          backgroundColor:
              notification['type'] == 'critical' ? Colors.red : Colors.orange,
        ),
      );
      _loadData();
    };
    mqttService.onBinStatusUpdate = (topic, data) => _loadBins();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadDashboard(), _loadBins()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadDashboard() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getCollectorDashboard();
      if (mounted) setState(() => _dashboardData = data);
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }
  }

  Future<void> _loadBins() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final assignedTo = widget.user['id'];
      final bins = await apiService.getBins(
        assignedTo:
            assignedTo is int ? assignedTo : int.tryParse('$assignedTo'),
      );
      if (mounted) setState(() => _bins = bins);
    } catch (e) {
      debugPrint('Bins error: $e');
    }
  }

  Future<void> _markBinCollected(int binId, String binCode) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await apiService.collectBin(binId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$binCode marked as collected'),
            backgroundColor: Colors.green),
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _logout() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    Provider.of<MqttService>(context, listen: false).disconnect();
    await apiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !isWide,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      // On mobile, show a hamburger drawer (left). On wide web, show a permanent left rail.
      drawer: isWide
          ? null
          : Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: Colors.white),
                    accountName: Text(
                      widget.user['name'] ?? 'Collector',
                      style: const TextStyle(
                        color: AppColors.headerText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    accountEmail: Text(
                      widget.user['email'] ?? '',
                      style: const TextStyle(
                        color: AppColors.subText,
                      ),
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: AppColors.scaffoldBackground,
                      child: Text(
                        widget.user['name']?[0].toUpperCase() ?? 'C',
                        style: const TextStyle(
                            fontSize: 24,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outlined),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to profile settings
                    },
                  ),
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
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('History'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 3);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                ],
              ),
            ),
      body: isWide ? _buildWideBody() : _buildNarrowBody(),
      bottomNavigationBar: !isWide
          ? BottomNavigationBar(
              currentIndex: _selectedIndex.clamp(0, 2),
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.delete_outline),
                  activeIcon: Icon(Icons.delete),
                  label: 'My Bins',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Map',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildNarrowBody() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : _buildContent();
  }

  Widget _buildWideBody() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex.clamp(0, 3),
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          labelType: NavigationRailLabelType.all,
          backgroundColor: Colors.white,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.delete_outline),
              selectedIcon: Icon(Icons.delete),
              label: Text('My Bins'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: Text('Map'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history),
              label: Text('History'),
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
        Expanded(child: _buildNarrowBody()),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildBinsList();
      case 2:
        return MapViewScreen(user: widget.user);
      case 3:
        return CollectionHistoryScreen(user: widget.user);
      default:
        return _buildHome();
    }
  }

  // --- UI COMPONENTS FOR HOME ---
  Widget _buildHome() {
    if (_dashboardData == null) {
      return const Center(child: Text('No data available'));
    }
    final overview = _dashboardData!['overview'];
    final pendingBins = _dashboardData!['pending_bins'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
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
                      widget.user['name']?.toString().isNotEmpty == true
                          ? widget.user['name'][0].toUpperCase()
                          : 'C',
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
                          'Ready to collect some bins?',
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
              "Today's Summary",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _animatedStatCard(
                  'Assigned',
                  '${overview['assigned_bins']}',
                  Colors.blue,
                  FontAwesomeIcons.listCheck,
                ),
                const SizedBox(width: 8),
                _animatedStatCard(
                    'Pending',
                    '${overview['critical_bins'] + overview['warning_bins']}',
                  Colors.orange,
                  FontAwesomeIcons.triangleExclamation,
                ),
                const SizedBox(width: 8),
                _animatedStatCard(
                  'Done',
                  '${overview['today_collections']}',
                  Colors.green,
                  FontAwesomeIcons.circleCheck,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (pendingBins.isNotEmpty) ...[
              Text(
                "Priority Collections",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...pendingBins.take(5).map((bin) => _buildBinCard(bin)),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "All clean! No pending collections.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _animatedStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, animationValue, child) {
          return Transform.scale(
            scale: animationValue,
            child: AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusIcon(
                        icon: icon,
                        color: color,
                        size: 18,
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subText,
                        fontWeight: FontWeight.w600,
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

  Widget _buildBinsList() {
    if (_bins.isEmpty) return const Center(child: Text('No bins assigned'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bins.length,
      itemBuilder: (context, index) => _buildBinCard(_bins[index]),
    );
  }

  Widget _buildBinCard(Map<String, dynamic> bin) {
    final fillLevel = (bin['fill_level'] ?? 0).toDouble();
    final progress = (fillLevel / 100).clamp(0.0, 1.0);
    final status = bin['status'] ?? 'normal';
    final Color statusColor = status == 'critical'
        ? Colors.red
        : (status == 'warning'
            ? Colors.orange
            : (status == 'offline' ? Colors.grey : Colors.green));
    final IconData statusIcon = status == 'critical'
        ? FontAwesomeIcons.triangleExclamation
        : (status == 'warning'
            ? FontAwesomeIcons.circleInfo
            : (status == 'offline'
                ? FontAwesomeIcons.cloud
                : FontAwesomeIcons.circleCheck));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                StatusIcon(
                  icon: statusIcon,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bin['bin_code'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.headerText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bin['location'],
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${fillLevel.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LiquidLinearProgressIndicator(
              value: progress,
              color: statusColor,
              height: 12,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {/* Navigate logic */},
                  icon: const FaIcon(FontAwesomeIcons.locationArrow),
                  label: const Text('Route'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _markBinCollected(bin['id'], bin['bin_code']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark Collected'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
