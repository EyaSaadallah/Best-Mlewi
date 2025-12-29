import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/commande.dart';
import '../../models/enums.dart';
import '../../models/point_de_vente.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/utilisateur_repository.dart';
import '../../repositories/point_de_vente_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class ClientOrderDetailsScreen extends StatefulWidget {
  final Commande order;
  final String docId;

  const ClientOrderDetailsScreen({
    super.key,
    required this.order,
    required this.docId,
  });

  @override
  State<ClientOrderDetailsScreen> createState() =>
      _ClientOrderDetailsScreenState();
}

class _ClientOrderDetailsScreenState extends State<ClientOrderDetailsScreen> {
  final UtilisateurRepository _utilisateurRepository = UtilisateurRepository();
  final PointDeVenteRepository _posRepository = PointDeVenteRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Track Your Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.hasError) {
            return Center(child: Text('Error: ${orderSnapshot.error}'));
          }

          if (orderSnapshot.connectionState == ConnectionState.waiting &&
              !orderSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentOrder =
              orderSnapshot.hasData && orderSnapshot.data!.exists
              ? OrderRepository().fromFirestore(orderSnapshot.data!)
              : widget.order;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusHeader(currentOrder),
                if (currentOrder.estimationPreparation != null)
                  _buildEstimationTime(currentOrder.estimationPreparation!),

                // Reactive Map Section
                if (currentOrder.statut != StatusCommande.delivered &&
                    currentOrder.statut != StatusCommande.cancelled)
                  _buildMapWithLiveTracking(currentOrder),

                // Reactive Info Sections
                _buildPOSSection(currentOrder),
                _buildAssignmentSection(currentOrder),

                _buildOrderSummary(currentOrder),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(Commande order) {
    final statusColor = _getStatusColor(order.statut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.statut.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(order.statut),
                  color: statusColor,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _getStatusProgress(order.statut),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ID: #${order.id}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                DateFormat('MMM dd, HH:mm').format(order.dateCreation),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstimationTime(int minutes) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.orange, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Arrival',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$minutes min - ${minutes + 10} min',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWithLiveTracking(Commande order) {
    return StreamBuilder<QuerySnapshot>(
      // Listen to the specific livreur document
      stream: order.livreurId != null
          ? FirebaseFirestore.instance
                .collection('utilisateurs')
                .where('id', isEqualTo: order.livreurId)
                .limit(1)
                .snapshots()
          : null,
      builder: (context, livreurSnapshot) {
        // Build marker list
        final List<Marker> markers = [];
        final List<LatLng> points = [];

        // 1. Client Location
        if (order.latitude != null && order.longitude != null) {
          final clientLatLng = LatLng(order.latitude!, order.longitude!);
          points.add(clientLatLng);
          markers.add(
            Marker(
              point: clientLatLng,
              width: 50,
              height: 50,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ),
          );
        }

        // 2. POS Location (Static for now, but we could fetch details if needed)
        // For simplicity, we'll try to get it from a separate stream or use a static lookup
        return FutureBuilder<PointDeVente?>(
          future: order.posId != null
              ? FirebaseFirestore.instance
                    .collection('points_de_vente')
                    .where('id', isEqualTo: order.posId)
                    .limit(1)
                    .get()
                    .then(
                      (s) => s.docs.isNotEmpty
                          ? _posRepository.fromFirestore(s.docs.first)
                          : null,
                    )
              : Future.value(null),
          builder: (context, posSnapshot) {
            final pos = posSnapshot.data;
            if (pos != null && pos.latitude != null && pos.longitude != null) {
              final posLatLng = LatLng(pos.latitude!, pos.longitude!);
              points.add(posLatLng);
              markers.add(
                Marker(
                  point: posLatLng,
                  width: 50,
                  height: 50,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.blue,
                      size: 26,
                    ),
                  ),
                ),
              );
            }

            // 3. Livreur Location (Live Tracking)
            if (livreurSnapshot.hasData &&
                livreurSnapshot.data!.docs.isNotEmpty) {
              final livreurData =
                  livreurSnapshot.data!.docs.first.data()
                      as Map<String, dynamic>;
              if (livreurData['latitude'] != null &&
                  livreurData['longitude'] != null) {
                final livreurLatLng = LatLng(
                  livreurData['latitude'] as double,
                  livreurData['longitude'] as double,
                );
                points.add(livreurLatLng);
                markers.add(
                  Marker(
                    point: livreurLatLng,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        // Pulsing effect or label could go here
                      ],
                    ),
                  ),
                );
              }
            }

            if (points.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Delivery tracking',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: points
                            .last, // Center on the most relevant point (driver or user)
                        initialZoom: points.length > 1 ? 13 : 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        // Polyline could be added here if we had coordinates
                        MarkerLayer(markers: markers),
                      ],
                    ),
                  ),
                  if (order.livreurId != null &&
                      (livreurSnapshot.data?.docs.isEmpty ?? true))
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Connecting to driver\'s GPS...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAssignmentSection(Commande order) {
    if (order.livreurId == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigning Driver',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Finding the nearest hero for you',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('id', isEqualTo: order.livreurId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final livreur = _utilisateurRepository.fromFirestore(
          snapshot.data!.docs.first,
        );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.black,
                backgroundImage: livreur.imageUrl != null
                    ? NetworkImage(livreur.imageUrl!)
                    : null,
                child: livreur.imageUrl == null
                    ? Text(
                        livreur.prenom[0],
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Delivery Hero',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '${livreur.prenom} ${livreur.nom}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.phone, color: Colors.green),
                style: IconButton.styleFrom(backgroundColor: Colors.green[50]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPOSSection(Commande order) {
    if (order.posId == null) return const SizedBox.shrink();

    return FutureBuilder<PointDeVente?>(
      future: FirebaseFirestore.instance
          .collection('points_de_vente')
          .where('id', isEqualTo: order.posId)
          .limit(1)
          .get()
          .then(
            (s) => s.docs.isNotEmpty
                ? _posRepository.fromFirestore(s.docs.first)
                : null,
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final pos = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            child: Row(
              children: [
                // Left Accent Bar / Icon Area
                Container(
                  width: 70,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Text Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PREPARING AT',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pos.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: -0.5,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pos.adresse,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildOrderSummary(Commande order) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...order.lignes.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${l.quantite}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.plat.nom,
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                  Text(
                    '${l.sousTotal.toStringAsFixed(2)} TND',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Paid',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '${order.totalWithTax.toStringAsFixed(2)} TND',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
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

  IconData _getStatusIcon(StatusCommande status) {
    switch (status) {
      case StatusCommande.created:
        return Icons.new_releases;
      case StatusCommande.accepted:
        return Icons.check_circle;
      case StatusCommande.preparing:
        return Icons.restaurant;
      case StatusCommande.ready:
        return Icons.shopping_bag;
      case StatusCommande.delivering:
        return Icons.delivery_dining;
      case StatusCommande.delivered:
        return Icons.home_work;
      case StatusCommande.cancelled:
        return Icons.cancel;
    }
  }

  double _getStatusProgress(StatusCommande status) {
    switch (status) {
      case StatusCommande.created:
        return 0.1;
      case StatusCommande.accepted:
        return 0.3;
      case StatusCommande.preparing:
        return 0.5;
      case StatusCommande.ready:
        return 0.7;
      case StatusCommande.delivering:
        return 0.9;
      case StatusCommande.delivered:
        return 1.0;
      case StatusCommande.cancelled:
        return 0.0;
    }
  }
}
