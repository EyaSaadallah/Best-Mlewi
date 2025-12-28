import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/commande.dart';
import '../../models/enums.dart';
import '../../repositories/order_repository.dart';
import '../../services/firebase_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'client_order_details_screen.dart';

/// Screen for Clients to view their orders and cancel if still created
class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'My Orders',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Please login to view your orders.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Orders History',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .where('clientId', isEqualTo: user.id)
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
            return _buildEmptyState();
          }

          final sortedDocs = docs.toList();
          sortedDocs.sort((a, b) {
            final aTime =
                (a.data() as Map<String, dynamic>)['dateCreation'] as Timestamp;
            final bTime =
                (b.data() as Map<String, dynamic>)['dateCreation'] as Timestamp;
            return bTime.compareTo(aTime);
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
      ),
    );
  }

  Widget _buildOrderCard(Commande order, String docId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                  ...order.lignes.map(
                    (ligne) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '${ligne.quantite}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ligne.plat.nom,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${ligne.sousTotal.toStringAsFixed(2)} TND',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Paid',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${order.totalWithTax.toStringAsFixed(2)} TND',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      _buildQuickAction(order, docId),
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

  Widget _buildStatusBadge(StatusCommande status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuickAction(Commande order, String docId) {
    if (order.statut == StatusCommande.delivering) {
      return TextButton.icon(
        onPressed: () => _openOrderDetails(order, docId),
        icon: const Icon(Icons.radar_rounded, size: 16),
        label: const Text(
          'TRACK LIVE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      );
    }

    if (order.statut == StatusCommande.created) {
      return OutlinedButton(
        onPressed: () => _confirmCancelOrder(docId, order.id),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text(
          'CANCEL',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        ),
      );
    }

    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: 14,
      color: Colors.grey[300],
    );
  }

  void _openOrderDetails(Commande order, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClientOrderDetailsScreen(order: order, docId: docId),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No orders yet',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Your delicious moments will appear here',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
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
            'Error loading orders',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelOrder(String docId, int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Cancel Order',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text('Are you sure you want to cancel Order #$orderId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'BACK',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'YES, CANCEL',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _orderRepository.updateStatus(docId, StatusCommande.cancelled);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled'),
              backgroundColor: Colors.black,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
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
}
