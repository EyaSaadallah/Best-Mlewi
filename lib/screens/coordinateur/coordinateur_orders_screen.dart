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
    _tabController = TabController(length: 4, vsync: this);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Coordinateur Orders')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orders Management',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_posName != null)
              Text(
                _posName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(null),
          _buildOrdersList(StatusCommande.preparing),
          _buildOrdersList(StatusCommande.ready),
          _buildOrdersList(StatusCommande.delivered),
        ],
      ),
    );
  }

  Widget _buildOrdersList(StatusCommande? status) {
    if (_posId == null) return const SizedBox();

    Query query = FirebaseFirestore.instance
        .collection('commandes')
        .where('posId', isEqualTo: _posId); // FILTER BY POS ID

    if (status != null) {
      query = query.where('statut', isEqualTo: status.name);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  status == null
                      ? 'No orders for this POS'
                      : 'No ${_getStatusLabel(status)} orders',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Sort in memory (newest first)
        final docs = snapshot.data!.docs;
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
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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
    final statusColor = _getStatusColor(order.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderDetailsScreen(order: order, docId: docId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _getStatusLabel(order.statut),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy - HH:mm',
                    ).format(order.dateCreation),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.lignes.length} items',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    '${order.totalWithTax.toStringAsFixed(2)} TND',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(StatusCommande status) {
    switch (status) {
      case StatusCommande.created:
        return Colors.blue;
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
        return Colors.red;
    }
  }

  String _getStatusLabel(StatusCommande status) {
    // Basic capitalization or just .name upper first
    return status.name[0].toUpperCase() + status.name.substring(1);
  }
}
