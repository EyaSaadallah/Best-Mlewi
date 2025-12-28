import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/commande.dart';
import '../../models/enums.dart';
import '../../models/utilisateur.dart';
import '../../services/firebase_auth_service.dart';
import '../../repositories/order_repository.dart';
import '../gerant/order_details_screen.dart';

class LivreurOrdersScreen extends StatefulWidget {
  const LivreurOrdersScreen({super.key});

  @override
  State<LivreurOrdersScreen> createState() => _LivreurOrdersScreenState();
}

class _LivreurOrdersScreenState extends State<LivreurOrdersScreen> {
  final _authService = FirebaseAuthService();
  final _orderRepository = OrderRepository();
  Utilisateur? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _authService.currentUser;
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Driver Profile not found',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'My Deliveries',
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
                  .where('livreurId', isEqualTo: _currentUser!.id)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                int activeCount = 0;
                int historyCount = 0;

                final List<String> activeStates = [
                  StatusCommande.accepted.name,
                  StatusCommande.preparing.name,
                  StatusCommande.ready.name,
                  StatusCommande.delivering.name,
                ];

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>?;
                  final status = data?['statut'] as String?;
                  if (status != null) {
                    if (activeStates.contains(status)) {
                      activeCount++;
                    } else {
                      historyCount++;
                    }
                  }
                }

                return TabBar(
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
                    _buildTab('Active', activeCount),
                    _buildTab('History', historyCount),
                  ],
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrdersList(active: true),
            _buildOrdersList(active: false),
          ],
        ),
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
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildOrdersList({required bool active}) {
    Query query = FirebaseFirestore.instance
        .collection('commandes')
        .where('livreurId', isEqualTo: _currentUser!.id);

    if (active) {
      query = query.where(
        'statut',
        whereIn: [
          StatusCommande.accepted.name,
          StatusCommande.preparing.name,
          StatusCommande.ready.name,
          StatusCommande.delivering.name,
        ],
      );
    } else {
      query = query.where(
        'statut',
        whereIn: [StatusCommande.delivered.name, StatusCommande.cancelled.name],
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Icon(
                    active
                        ? Icons.delivery_dining_rounded
                        : Icons.history_rounded,
                    size: 48,
                    color: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  active ? 'No active deliveries' : 'No history found',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        final parsed = docs.map((doc) {
          return {'doc': doc, 'order': _orderRepository.fromFirestore(doc)};
        }).toList();

        parsed.sort((a, b) {
          final orderA = a['order'] as Commande;
          final orderB = b['order'] as Commande;
          return orderB.dateCreation.compareTo(orderA.dateCreation);
        });

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: Colors.black,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: parsed.length,
            itemBuilder: (context, index) {
              final item = parsed[index];
              final order = item['order'] as Commande;
              final doc = item['doc'] as DocumentSnapshot;
              return _buildOrderCard(order, doc.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Commande order, String docId) {
    final color = _getStatusColor(order.statut);

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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OrderDetailsScreen(order: order, docId: docId),
                ),
              ).then((_) => setState(() {}));
            },
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
                            'DELIVERY',
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Text(
                          _getStatusLabel(order.statut).toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_basket_outlined,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${order.lignes.length} Items Summary',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${order.totalWithTax.toStringAsFixed(2)} TND',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

  String _getStatusLabel(StatusCommande status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }
}
