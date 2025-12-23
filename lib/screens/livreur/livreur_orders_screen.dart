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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Deliveries'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
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

  Widget _buildOrdersList({required bool active}) {
    Query query = FirebaseFirestore.instance
        .collection('commandes')
        .where('livreurId', isEqualTo: _currentUser!.id);

    if (active) {
      query = query.where(
        'statut',
        whereIn: [StatusCommande.ready.name, StatusCommande.delivering.name],
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
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active ? Icons.delivery_dining : Icons.history,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  active ? 'No active deliveries' : 'No history yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        // We need both doc for ID and order for data.
        // We'll sort locally.
        // To sort easily, we map to a list of pairs or custom objects.
        // But since we can't easily sort (Doc, Order) pairs in place without a class,
        // we'll just sort docs by parsing dateCreation from data directly if needed, or parse all first.

        final parsed = docs.map((doc) {
          return {'doc': doc, 'order': _orderRepository.fromFirestore(doc)};
        }).toList();

        parsed.sort((a, b) {
          final orderA = a['order'] as Commande;
          final orderB = b['order'] as Commande;
          return orderB.dateCreation.compareTo(orderA.dateCreation);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: parsed.length,
          itemBuilder: (context, index) {
            final item = parsed[index];
            final order = item['order'] as Commande;
            final doc = item['doc'] as DocumentSnapshot;
            return _buildOrderCard(order, doc.id);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Commande order, String docId) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(order.statut).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(order.statut),
                      style: TextStyle(
                        color: _getStatusColor(order.statut),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(order.dateCreation),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (order.totalWithTax > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${order.totalWithTax.toStringAsFixed(2)} TND',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order.lignes.length} Items',
                    style: const TextStyle(color: Colors.grey),
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
    switch (status) {
      case StatusCommande.created:
        return 'Created';
      case StatusCommande.accepted:
        return 'Accepted';
      case StatusCommande.preparing:
        return 'Preparing';
      case StatusCommande.ready:
        return 'Ready';
      case StatusCommande.delivering:
        return 'Delivering';
      case StatusCommande.delivered:
        return 'Delivered';
      case StatusCommande.cancelled:
        return 'Cancelled';
    }
  }
}
