import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/liquid_linear_progress_indicator.dart';
import '../../widgets/status_icon.dart';
import 'bin_details_screen.dart';
import 'create_bin_screen.dart';

class BinListScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  
  const BinListScreen({super.key, required this.user});

  @override
  State<BinListScreen> createState() => _BinsListScreenState();
}

class _BinsListScreenState extends State<BinListScreen> {
  List<dynamic> _bins = [];
  List<dynamic> _filteredBins = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadBins();
  }

  Future<void> _loadBins() async {
    setState(() => _isLoading = true);
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    try {
      final bins = await apiService.getBins(status: _statusFilter);
      setState(() {
        _bins = bins;
        _filteredBins = bins;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBins = _bins.where((bin) {
        final matchesSearch = bin['bin_code']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            bin['location']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        
        final matchesStatus = _statusFilter == null || 
            bin['status'] == _statusFilter;
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Status'),
              leading: Radio<String?>(
                value: null,
                groupValue: _statusFilter,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() => _statusFilter = value);
                  _loadBins();
                },
              ),
            ),
            ListTile(
              title: const Text('Critical'),
              leading: Radio<String?>(
                value: 'critical',
                groupValue: _statusFilter,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() => _statusFilter = value);
                  _loadBins();
                },
              ),
            ),
            ListTile(
              title: const Text('Warning'),
              leading: Radio<String?>(
                value: 'warning',
                groupValue: _statusFilter,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() => _statusFilter = value);
                  _loadBins();
                },
              ),
            ),
            ListTile(
              title: const Text('Normal'),
              leading: Radio<String?>(
                value: 'normal',
                groupValue: _statusFilter,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() => _statusFilter = value);
                  _loadBins();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bins'),
        actions: [
          IconButton(
            icon: Icon(
              _statusFilter != null 
                  ? Icons.filter_alt 
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search bins...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),

          // Filter chips
          if (_statusFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text('Status: $_statusFilter'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _statusFilter = null);
                      _loadBins();
                    },
                  ),
                ],
              ),
            ),

          // Bins list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBins.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bins found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBins,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBins.length,
                          itemBuilder: (context, index) {
                            return _buildBinCard(_filteredBins[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Wrap CreateBinScreen in its own Scaffold so that all TextField
          // widgets have a Material ancestor even when this screen is pushed
          // as a full route from the bins list.
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: const Text('Create New Waste Bin'),
                ),
                body: CreateBinScreen(user: widget.user),
              ),
            ),
          );
          if (result == true) {
            _loadBins();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Bin'),
      ),
    );
  }

  Widget _buildBinCard(Map<String, dynamic> bin) {
    final fillLevel = (bin['fill_level'] ?? 0).toDouble();
    final progress = (fillLevel / 100).clamp(0.0, 1.0);
    final status = bin['status'] ?? 'normal';
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'critical':
        statusColor = Colors.red;
        statusIcon = FontAwesomeIcons.triangleExclamation;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = FontAwesomeIcons.circleInfo;
        break;
      case 'offline':
        statusColor = Colors.grey;
        statusIcon = FontAwesomeIcons.cloud;
        break;
      default:
        statusColor = Colors.green;
        statusIcon = FontAwesomeIcons.circleCheck;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BinDetailScreen(binId: bin['id']),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusIcon(
                        icon: statusIcon,
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  bin['bin_code'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.headerText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bin['location'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.subText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${fillLevel.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                    children: [
                      FaIcon(
                        FontAwesomeIcons.user,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bin['collector_name'] ?? 'Unassigned',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (bin['last_collection'] != null) ...[
                        const SizedBox(width: 12),
                        FaIcon(
                          FontAwesomeIcons.clock,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last: ${_formatDate(bin['last_collection'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Never';
    
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}