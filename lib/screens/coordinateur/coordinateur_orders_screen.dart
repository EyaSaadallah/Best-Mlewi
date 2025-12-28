import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/commande.dart';
import '../../models/enums.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/point_de_vente_repository.dart';
import '../../repositories/utilisateur_repository.dart';
import '../gerant/order_details_screen.dart';

class CoordinateurOrdersScreen extends StatefulWidget {
  const CoordinateurOrdersScreen({super.key});

  @override
  State<CoordinateurOrdersScreen> createState() =>
      _CoordinateurOrdersScreenState();
}

class _CoordinateurOrdersScreenState extends State<CoordinateurOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderRepository _orderRepository = OrderRepository();
  final PointDeVenteRepository _posRepository = PointDeVenteRepository();
  final UtilisateurRepository _userRepository = UtilisateurRepository();

  int? _posId;
  String? _posName;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadCoordinateurPOS();
  }

  Future<void> _loadCoordinateurPOS() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // 1. Get current user's integer ID
      // We assume email is the link or we need to find the user doc by auth ID
      // Since mapping strategy varies, I'll search by email as fallback or auth ID if stored
      // Assuming I can get the user by their email which is standard
      final dbUser = await _userRepository.getByEmail(user.email!);
      if (dbUser == null) {
        throw Exception('User profile not found');
      }

      // 2. Get POS assigned to this coordinateur
      final pos = await _posRepository.getByCoordinateurId(dbUser.id);

      if (mounted) {
        setState(() {
          if (pos != null) {
            _posId = pos.id;
            _posName = pos.nom;
          } else {
            _error = 'No Point of Sale assigned to your account.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Orders Management',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
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
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Orders Pipeline',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (_posName != null)
              Text(
                _posName!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.black54,
                  letterSpacing: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
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
                .where('posId', isEqualTo: _posId)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final Map<String, int> counts = {};
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
                ],
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(StatusCommande.accepted),
          _buildOrdersList(StatusCommande.preparing),
          _buildOrdersList(StatusCommande.ready),
          _buildOrdersList(StatusCommande.delivering),
          _buildOrdersList(StatusCommande.delivered),
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
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildOrdersList(StatusCommande? status) {
    if (_posId == null) return const SizedBox();

    Query query = FirebaseFirestore.instance
        .collection('commandes')
        .where('posId', isEqualTo: _posId);

    if (status != null) {
      query = query.where('statut', isEqualTo: status.name);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[200]),
                const SizedBox(height: 16),
                Text(
                  status == null
                      ? 'No orders for this POS'
                      : 'No ${_getStatusLabel(status)} orders',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        // Sort in memory (newest first)
        final sortedDocs = docs.toList();
        sortedDocs.sort((a, b) {
          try {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = (aData['dateCreation'] as Timestamp).toDate();
            final bDate = (bData['dateCreation'] as Timestamp).toDate();
            return bDate.compareTo(aDate);
          } catch (e) {
            return 0;
          }
        });

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
