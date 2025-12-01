import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_seeder_service.dart';

/// Professional dashboard widget for Gerant with statistics and charts
class GerantDashboard extends StatelessWidget {
  const GerantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Statistics Cards Row
        _buildStatisticsCards(),
        const SizedBox(height: 24),

        // Charts Section
        _buildChartsSection(context),
        const SizedBox(height: 24),

        // Recent Activity
        _buildRecentActivity(),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return StreamBuilder<Map<String, int>>(
      stream: _getStatisticsStream(),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            {
              'totalOrders': 0,
              'totalUsers': 0,
              'totalDishes': 0,
              'totalPOS': 0,
            };

        return SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildStatCard(
                'Total Orders',
                stats['totalOrders'].toString(),
                Icons.shopping_cart,
                Colors.grey[900]!,
                '${stats['totalOrders']} orders',
              ),
              _buildStatCard(
                'Active Users',
                stats['totalUsers'].toString(),
                Icons.people,
                Colors.grey[800]!,
                '${stats['totalUsers']} users',
              ),
              _buildStatCard(
                'Menu Items',
                stats['totalDishes'].toString(),
                Icons.restaurant_menu,
                Colors.grey[700]!,
                '${stats['totalDishes']} dishes',
              ),
              _buildStatCard(
                'Sales Points',
                stats['totalPOS'].toString(),
                Icons.store,
                Colors.black,
                '${stats['totalPOS']} locations',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                Icon(
                  Icons.trending_up,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analytics Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.cloud_upload, color: Colors.black),
                tooltip: 'Seed Test Data',
                onPressed: () => _showSeedConfirmation(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildOrdersChart()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildOrderStatusChart()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildOrdersChart(),
                    const SizedBox(height: 16),
                    _buildOrderStatusChart(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showSeedConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Test Data'),
        content: const Text(
          'This will generate random orders AND reset menus:\n\n'
          '• Orders for this week (Line Chart)\n'
          '• Orders for today (Pie Chart)\n'
          '• Past orders (Total Count)\n'
          '• CLEAN MENUS & DISHES (with images)\n\n'
          'Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Seeding data...')));

              try {
                final seeder = DataSeederService();
                await seeder.seedMenus();
                await seeder.seedDashboardData();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data seeded successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error seeding data: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersChart() {
    return StreamBuilder<List<FlSpot>>(
      stream: _getWeeklyOrdersData(),
      builder: (context, snapshot) {
        final spots =
            snapshot.data ??
            [
              const FlSpot(0, 0),
              const FlSpot(1, 0),
              const FlSpot(2, 0),
              const FlSpot(3, 0),
              const FlSpot(4, 0),
              const FlSpot(5, 0),
              const FlSpot(6, 0),
            ];

        // Calculate max Y value for better scaling
        double maxY = 10;
        for (var spot in spots) {
          if (spot.y > maxY) maxY = spot.y;
        }
        maxY = (maxY * 1.2).ceilToDouble(); // Add 20% padding

        return Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Orders This Week',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                const style = TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                );
                                Widget text;
                                switch (value.toInt()) {
                                  case 0:
                                    text = const Text('Mon', style: style);
                                    break;
                                  case 1:
                                    text = const Text('Tue', style: style);
                                    break;
                                  case 2:
                                    text = const Text('Wed', style: style);
                                    break;
                                  case 3:
                                    text = const Text('Thu', style: style);
                                    break;
                                  case 4:
                                    text = const Text('Fri', style: style);
                                    break;
                                  case 5:
                                    text = const Text('Sat', style: style);
                                    break;
                                  case 6:
                                    text = const Text('Sun', style: style);
                                    break;
                                  default:
                                    text = const Text('', style: style);
                                    break;
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: text,
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: maxY / 5,
                              reservedSize: 32,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [Colors.grey[700]!, Colors.black],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.withOpacity(0.2),
                                  Colors.grey.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusChart() {
    return StreamBuilder<Map<String, int>>(
      stream: _getOrderStatusData(),
      builder: (context, snapshot) {
        final statusData =
            snapshot.data ??
            {'delivered': 0, 'pending': 0, 'in_transit': 0, 'cancelled': 0};

        final total = statusData.values.fold(0, (sum, val) => sum + val);

        // If no data, show placeholder
        if (total == 0) {
          return Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'No order data available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Status',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: [
                        if (statusData['delivered']! > 0)
                          PieChartSectionData(
                            color: Colors.green,
                            value: statusData['delivered']!.toDouble(),
                            title:
                                '${((statusData['delivered']! / total) * 100).toStringAsFixed(0)}%',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (statusData['pending']! > 0)
                          PieChartSectionData(
                            color: Colors.orange,
                            value: statusData['pending']!.toDouble(),
                            title:
                                '${((statusData['pending']! / total) * 100).toStringAsFixed(0)}%',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (statusData['in_transit']! > 0)
                          PieChartSectionData(
                            color: Colors.blue,
                            value: statusData['in_transit']!.toDouble(),
                            title:
                                '${((statusData['in_transit']! / total) * 100).toStringAsFixed(0)}%',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (statusData['cancelled']! > 0)
                          PieChartSectionData(
                            color: Colors.red,
                            value: statusData['cancelled']!.toDouble(),
                            title:
                                '${((statusData['cancelled']! / total) * 100).toStringAsFixed(0)}%',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLegend(statusData, total),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(Map<String, int> statusData, int total) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        if (statusData['delivered']! > 0)
          _buildLegendItem('Delivered', Colors.green),
        if (statusData['pending']! > 0)
          _buildLegendItem('Pending', Colors.orange),
        if (statusData['in_transit']! > 0)
          _buildLegendItem('In Transit', Colors.blue),
        if (statusData['cancelled']! > 0)
          _buildLegendItem('Cancelled', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(onPressed: () {}, child: const Text('View All')),
                ],
              ),
            ),
            const Divider(height: 1),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('commandes')
                  .orderBy('dateCommande', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No recent activity',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['statut'] ?? 'pending';
                    final timestamp = data['dateCommande'] as Timestamp?;
                    final date = timestamp?.toDate() ?? DateTime.now();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(
                          status,
                        ).withOpacity(0.2),
                        child: Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Order #${doc.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _formatDate(date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'livree':
      case 'livré':
        return Colors.green;
      case 'pending':
      case 'en_attente':
      case 'en attente':
        return Colors.orange;
      case 'in_transit':
      case 'en_cours':
      case 'en cours':
        return Colors.blue;
      case 'cancelled':
      case 'annulee':
      case 'annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'livree':
      case 'livré':
        return Icons.check_circle;
      case 'pending':
      case 'en_attente':
      case 'en attente':
        return Icons.pending;
      case 'in_transit':
      case 'en_cours':
      case 'en cours':
        return Icons.local_shipping;
      case 'cancelled':
      case 'annulee':
      case 'annulée':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Get real weekly orders data from Firestore
  Stream<List<FlSpot>> _getWeeklyOrdersData() {
    final now = DateTime.now();
    // Start of the current week (Monday)
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    return FirebaseFirestore.instance
        .collection('commandes')
        .where(
          'dateCommande',
          isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
        )
        .snapshots()
        .map((snapshot) {
          // Initialize counts for each day
          final dayCounts = List<int>.filled(7, 0);

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final timestamp = data['dateCommande'] as Timestamp?;
            if (timestamp != null) {
              final date = timestamp.toDate();
              final daysDiff = date.difference(weekStart).inDays;
              if (daysDiff >= 0 && daysDiff < 7) {
                dayCounts[daysDiff]++;
              }
            }
          }

          // Convert to FlSpot list
          return List.generate(
            7,
            (index) => FlSpot(index.toDouble(), dayCounts[index].toDouble()),
          );
        });
  }

  // Get real order status data from Firestore for TODAY
  Stream<Map<String, int>> _getOrderStatusData() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return FirebaseFirestore.instance
        .collection('commandes')
        .where(
          'dateCommande',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .snapshots()
        .map((snapshot) {
          final statusCounts = {
            'delivered': 0,
            'pending': 0,
            'in_transit': 0,
            'cancelled': 0,
          };

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final status = (data['statut'] ?? 'pending')
                .toString()
                .toLowerCase();

            if (status.contains('livr') || status == 'delivered') {
              statusCounts['delivered'] = statusCounts['delivered']! + 1;
            } else if (status.contains('attente') || status == 'pending') {
              statusCounts['pending'] = statusCounts['pending']! + 1;
            } else if (status.contains('cours') ||
                status.contains('transit') ||
                status == 'in_transit') {
              statusCounts['in_transit'] = statusCounts['in_transit']! + 1;
            } else if (status.contains('annul') || status == 'cancelled') {
              statusCounts['cancelled'] = statusCounts['cancelled']! + 1;
            }
          }

          return statusCounts;
        });
  }

  Stream<Map<String, int>> _getStatisticsStream() {
    // Refresh stats every 30 seconds to save reads
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      try {
        // Use count() aggregation for efficient reading
        final ordersCount = await FirebaseFirestore.instance
            .collection('commandes')
            .count()
            .get();

        final usersCount = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .where('isActive', isEqualTo: true)
            .count()
            .get();

        final posCount = await FirebaseFirestore.instance
            .collection('pointsDeVente')
            .count()
            .get();

        // For menus, we still need to read docs to count dishes inside arrays
        final menusSnapshot = await FirebaseFirestore.instance
            .collection('menus')
            .get();

        int totalDishes = 0;
        for (var doc in menusSnapshot.docs) {
          final data = doc.data();
          final plats = data['plats'] as List<dynamic>? ?? [];
          totalDishes += plats.length;
        }

        return {
          'totalOrders': ordersCount.count ?? 0,
          'totalUsers': usersCount.count ?? 0,
          'totalDishes': totalDishes,
          'totalPOS': posCount.count ?? 0,
        };
      } catch (e) {
        debugPrint('Error fetching dashboard stats: $e');
        return {
          'totalOrders': 0,
          'totalUsers': 0,
          'totalDishes': 0,
          'totalPOS': 0,
        };
      }
    }).asyncMap((event) => event);
  }
}
