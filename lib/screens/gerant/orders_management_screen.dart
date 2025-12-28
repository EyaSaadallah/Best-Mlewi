import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/commande.dart';
import '../../models/enums.dart';
import '../../repositories/order_repository.dart';
import 'order_details_screen.dart';
import 'package:intl/intl.dart';

/// Screen for Gerant to manage all orders and update their statuses
class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderRepository _orderRepository = OrderRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Orders Pipeline',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('commandes')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final Map<String, int> counts = {'All': docs.length};

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>?;
                final status = data?['statut'] as String?;
                if (status != null) {
                  counts[status] = (counts[status] ?? 0) + 1;
                }
              }

              return TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorColor: Colors.black,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  _buildTab(
                    'Created',
                    counts[StatusCommande.created.name] ?? 0,
                  ),
                  _buildTab(
                    'Accepted',
                    counts[StatusCommande.accepted.name] ?? 0,
                  ),
                  _buildTab(
                    'Preparing',
                    counts[StatusCommande.preparing.name] ?? 0,
                  ),
                  _buildTab('Ready', counts[StatusCommande.ready.name] ?? 0),
                  _buildTab(
                    'Delivering',
                    counts[StatusCommande.delivering.name] ?? 0,
                  ),
                  _buildTab(
                    'Delivered',
                    counts[StatusCommande.delivered.name] ?? 0,
                  ),
                  _buildTab(
                    'Cancelled',
                    counts[StatusCommande.cancelled.name] ?? 0,
                  ),
                  _buildTab('All', counts['All'] ?? 0),
                ],
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(StatusCommande.created),
          _buildOrdersList(StatusCommande.accepted),
          _buildOrdersList(StatusCommande.preparing),
          _buildOrdersList(StatusCommande.ready),
          _buildOrdersList(StatusCommande.delivering),
          _buildOrdersList(StatusCommande.delivered),
          _buildOrdersList(StatusCommande.cancelled),
          _buildOrdersList(null),
        ],
      ),
    );
  }

  Tab _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildOrdersList(StatusCommande? status) {
    return StreamBuilder<QuerySnapshot>(
      stream: status == null
          ? FirebaseFirestore.instance
                .collection('commandes')
                .orderBy('dateCreation', descending: true)
                .snapshots()
          : FirebaseFirestore.instance
                .collection('commandes')
                .where('statut', isEqualTo: status.name)
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(status);
        }

        // Sort in memory if filtered by status (since we can't always order by on filtered queries without indexes)
        var sortedDocs = docs.toList();
        if (status != null) {
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = (aData['dateCreation'] as Timestamp).toDate();
            final bDate = (bData['dateCreation'] as Timestamp).toDate();
            return bDate.compareTo(aDate);
          });
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: Colors.black,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final order = _orderRepository.fromFirestore(doc);
              return _buildOrderCard(order, doc.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Commande order, String docId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openOrderDetails(order, docId),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORDER',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'MMM dd, HH:mm',
                            ).format(order.dateCreation),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusBadge(order.statut),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_basket_outlined,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${order.lignes.length} Items Summary',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.lignes.map((l) => l.plat.nom).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${order.totalWithTax.toStringAsFixed(2)} TND',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (order.statut == StatusCommande.created) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openOrderDetails(order, docId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'PROCESS ORDER',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(StatusCommande status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(status).toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _openOrderDetails(Commande order, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(order: order, docId: docId),
      ),
    ).then((_) => setState(() {}));
  }

  Widget _buildEmptyState(StatusCommande? status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            status == null
                ? 'No orders recorded'
                : 'Empty ${_getStatusLabel(status)} Pipeline',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'New orders will appear here automatically',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'Pipeline Error',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(StatusCommande status) {
    switch (status) {
      case StatusCommande.created:
        return Colors.blueAccent;
      case StatusCommande.accepted:
        return Colors.teal;
      case StatusCommande.preparing:
        return Colors.orange;
      case StatusCommande.ready:
        return Colors.purple;
      case StatusCommande.delivering:
        return Colors.indigo;
      case StatusCommande.delivered:
        return Colors.green;
      case StatusCommande.cancelled:
        return Colors.redAccent;
    }
  }

  IconData _getStatusIcon(StatusCommande status) {
    switch (status) {
      case StatusCommande.created:
        return Icons.receipt_long_rounded;
      case StatusCommande.accepted:
        return Icons.check_circle_rounded;
      case StatusCommande.preparing:
        return Icons.restaurant_rounded;
      case StatusCommande.ready:
        return Icons.inventory_2_rounded;
      case StatusCommande.delivering:
        return Icons.delivery_dining_rounded;
      case StatusCommande.delivered:
        return Icons.task_alt_rounded;
      case StatusCommande.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _getStatusLabel(StatusCommande status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }
}
