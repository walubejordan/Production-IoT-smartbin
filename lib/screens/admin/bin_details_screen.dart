import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class BinDetailScreen extends StatefulWidget {
  final int binId;

  const BinDetailScreen({super.key, required this.binId});

  @override
  State<BinDetailScreen> createState() => _BinDetailScreenState();
}

class _BinDetailScreenState extends State<BinDetailScreen> {
  Map<String, dynamic>? _bin;
  List<dynamic> _history = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  List<dynamic> _collectors = [];
  bool _isLoadingCollectors = false;
  int? _selectedCollectorId;

  @override
  void initState() {
    super.initState();
    _loadBinDetails();
  }

  Future<void> _loadBinDetails() async {
    setState(() => _isLoading = true);

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final bin = await apiService.getBin(widget.binId);
      final history = await apiService.getBinHistory(widget.binId);

      setState(() {
        _bin = bin;
        _history = history;
        _selectedCollectorId = bin['assigned_to'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadCollectors() async {
    setState(() {
      _isLoadingCollectors = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final collectors = await apiService.getCollectors();
      setState(() {
        _collectors = collectors;
        _isLoadingCollectors = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCollectors = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collectors: $e')),
        );
      }
    }
  }

  Future<void> _deleteBin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bin'),
        content: Text('Are you sure you want to delete ${_bin!['bin_code']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.deleteBin(widget.binId);

      if (!mounted) return;

      Navigator.pop(context, true); // Return true to indicate deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bin deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bin Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bin == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bin Details')),
        body: const Center(child: Text('Bin not found')),
      );
    }

    final fillLevel = _bin!['fill_level'] ?? 0;
    final status = _bin!['status'] ?? 'normal';

    Color statusColor;
    switch (status) {
      case 'critical':
        statusColor = Colors.red;
        break;
      case 'warning':
        statusColor = Colors.orange;
        break;
      case 'offline':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.green;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_bin!['bin_code']),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (_bin == null) return;
              final apiService =
                  Provider.of<ApiService>(context, listen: false);

              // Controllers for existing editable fields
              final locationController = TextEditingController(
                  text: _bin!['location']?.toString() ?? '');
              final capacityController = TextEditingController(
                  text: (_bin!['capacity'] ?? 100).toString());
              final latitudeController = TextEditingController(
                  text: _bin!['latitude'] != null
                      ? _bin!['latitude'].toString()
                      : '');
              final longitudeController = TextEditingController(
                  text: _bin!['longitude'] != null
                      ? _bin!['longitude'].toString()
                      : '');

              // Load collectors for the dropdown
              await _loadCollectors();

              await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Edit Bin'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: capacityController,
                          decoration: const InputDecoration(
                            labelText: 'Capacity (L)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: latitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: longitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                        ),
                        const SizedBox(height: 12),
                        _isLoadingCollectors
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<int>(
                                initialValue: _selectedCollectorId,
                                decoration: const InputDecoration(
                                  labelText: 'Assign Collector',
                                  border: OutlineInputBorder(),
                                ),
                                items: _collectors.map((collector) {
                                  return DropdownMenuItem<int>(
                                    value: collector['id'] as int,
                                    child: Text(collector['name'] as String),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCollectorId = value;
                                  });
                                },
                              ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final loc = locationController.text.trim();
                          final cap =
                              int.tryParse(capacityController.text.trim());
                          final lat = latitudeController.text.trim().isNotEmpty
                              ? double.tryParse(latitudeController.text.trim())
                              : null;
                          final lng = longitudeController.text.trim().isNotEmpty
                              ? double.tryParse(longitudeController.text.trim())
                              : null;

                          await apiService.updateBin(
                            widget.binId,
                            location: loc.isNotEmpty ? loc : null,
                            capacity: cap,
                            latitude: lat,
                            longitude: lng,
                            assignedTo: _selectedCollectorId,
                          );

                          if (!mounted) return;
                          Navigator.pop(context, true);
                          await _loadBinDetails();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bin updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Bin', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deleteBin();
              }
            },
          ),
        ],
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBinDetails,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Card(
                      color: statusColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fill Level',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$fillLevel%',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 48,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: fillLevel / 100,
                                minHeight: 12,
                                backgroundColor: Colors.white,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Information
                    const Text(
                      'Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.qr_code,
                            'Bin Code',
                            _bin!['bin_code'],
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            'Location',
                            _bin!['location'],
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.person_outline,
                            'Assigned To',
                            _bin!['collector_name'] ?? 'Unassigned',
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.inventory_2_outlined,
                            'Capacity',
                            '${_bin!['capacity'] ?? 100}L',
                          ),
                          if (_bin!['last_collection'] != null) ...[
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.access_time,
                              'Last Collection',
                              _formatDateTime(_bin!['last_collection']),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Location Map
                    if (_bin!['latitude'] != null &&
                        _bin!['longitude'] != null) ...[
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 48,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Map View',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lat: ${_bin!['latitude']}, Lng: ${_bin!['longitude']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Collection History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Collection History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // View all history
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_history.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No collection history',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final collection = _history[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                              ),
                              title: Text(
                                  collection['collector_name'] ?? 'Unknown'),
                              subtitle: Text(
                                _formatDateTime(collection['collection_time']),
                              ),
                              trailing: Text(
                                '${collection['fill_level_before']}% → ${collection['fill_level_after']}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'Unknown';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
