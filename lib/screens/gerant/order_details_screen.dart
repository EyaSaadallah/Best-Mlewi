import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/commande.dart';
import '../../models/enums.dart';
import '../../models/utilisateur.dart';
import '../../models/point_de_vente.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/utilisateur_repository.dart';
import '../../repositories/point_de_vente_repository.dart';
import '../../services/notification_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Detailed view of a single order with status update options
class OrderDetailsScreen extends StatefulWidget {
  final Commande order;
  final String docId;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.docId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final UtilisateurRepository _utilisateurRepository = UtilisateurRepository();
  final PointDeVenteRepository _posRepository = PointDeVenteRepository();

  late StatusCommande _currentStatus;

  // Selection state
  List<Utilisateur> _availableLivreurs = [];
  List<PointDeVente> _availablePOS = [];
  Utilisateur? _selectedLivreur;
  PointDeVente? _selectedPOS;
  bool _isLoadingData = false;
  bool _isUpdating = false;

  // Resolved names for display
  String? _assignedLivreurName;
  String? _assignedPOSName;
  String? _clientName;
  Role? _currentUserRole;

  Utilisateur? _assignedLivreur;
  PointDeVente? _assignedPOS;
  List<PointDeVente> _allPOS = [];
  final MapController _mapController = MapController();
  Timer? _trackingTimer;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.statut;
    _loadCurrentUserRole();
    _loadAssignedNames();
    if (_currentStatus == StatusCommande.created) {
      _loadAssignmentData();
    }
    _startTrackingTimer();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _startTrackingTimer() {
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted &&
          _currentStatus != StatusCommande.delivered &&
          _currentStatus != StatusCommande.cancelled) {
        if (_currentStatus == StatusCommande.created) {
          _loadAssignmentData();
        } else {
          _loadAssignedNames();
        }
      }
    });
  }

  Future<void> _loadCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final dbUser = await _utilisateurRepository.getByEmail(user.email!);
      if (mounted && dbUser != null) {
        setState(() {
          _currentUserRole = dbUser.role;
        });
      }
    }
  }

  Future<void> _loadAssignedNames() async {
    try {
      // Fetch Client Info
      if (widget.order.clientId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .where('id', isEqualTo: widget.order.clientId)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty && mounted) {
          final user = _utilisateurRepository.fromFirestore(
            snapshot.docs.first,
          );
          setState(() {
            _clientName = '${user.prenom} ${user.nom}';
          });
        }
      }

      // Fetch Livreur Info
      if (widget.order.livreurId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .where('id', isEqualTo: widget.order.livreurId)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty && mounted) {
          final user = _utilisateurRepository.fromFirestore(
            snapshot.docs.first,
          );
          debugPrint(
            'Loaded Livreur: ${user.prenom} (Lat: ${user.latitude}, Lng: ${user.longitude})',
          );
          setState(() {
            _assignedLivreur = user;
            _assignedLivreurName = '${user.prenom} ${user.nom}';
          });
        }
      }

      // Fetch POS Info
      if (widget.order.posId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('points_de_vente')
            .where('id', isEqualTo: widget.order.posId)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty && mounted) {
          final pos = _posRepository.fromFirestore(snapshot.docs.first);
          debugPrint(
            'Loaded POS: ${pos.nom} (Lat: ${pos.latitude}, Lng: ${pos.longitude})',
          );
          setState(() {
            _assignedPOS = pos;
            _assignedPOSName = pos.nom;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading assigned names: $e');
    }
  }

  Future<void> _loadAssignmentData() async {
    setState(() => _isLoadingData = true);
    try {
      // Load active POS
      final posList = await _posRepository.getAll();

      // Load available livreurs
      final livreurs = await _utilisateurRepository.getByRole(Role.livreur);

      // Load active orders to find busy livreurs
      final activeOrders = await _orderRepository.getActiveOrders();
      final busyLivreurIds = activeOrders
          .map((o) => o.livreurId)
          .where((id) => id != null)
          .toSet();

      if (mounted) {
        setState(() {
          _allPOS = posList;
          // Build unique lists by ID to prevent "2 or more items with same value" error
          final Map<int, PointDeVente> uniquePOS = {};
          for (var p in posList) {
            if (p.isOpenNow) uniquePOS[p.id] = p;
          }
          _availablePOS = uniquePOS.values.toList();

          final Map<int, Utilisateur> uniqueLivreurs = {};
          for (var l in livreurs) {
            final isFree = !busyLivreurIds.contains(l.id);
            if (l.isAvailable && l.isActive && isFree) {
              uniqueLivreurs[l.id] = l;
            }
          }
          _availableLivreurs = uniqueLivreurs.values.toList();

          // CRITICAL FIX: If currently selected item is no longer in the available list,
          // we must clear the selection or Flutter's DropdownButton will crash.
          if (_selectedPOS != null && !_availablePOS.contains(_selectedPOS)) {
            _selectedPOS = null;
          }
          if (_selectedLivreur != null &&
              !_availableLivreurs.contains(_selectedLivreur)) {
            _selectedLivreur = null;
          }

          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_currentStatus);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ORDER DETAILS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STATUS',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: statusColor.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              _getStatusLabel(_currentStatus).toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'PLACED ON',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat(
                              'MMM dd, HH:mm',
                            ).format(widget.order.dateCreation),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.order.estimationPreparation != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESTIMATED PREP TIME',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              '${widget.order.estimationPreparation} minutes',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Assignments Banner (Blue Info)
            if (_currentStatus != StatusCommande.created)
              _buildAssignmentsInfo(),

            // Section: Customer
            if (_clientName != null)
              _buildSection(
                'Customer Info',
                Icons.person_outline_rounded,
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 20,
                      child: Text(
                        _clientName![0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _clientName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Registered Customer',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {}, // Future: Call/Chat
                      icon: const Icon(
                        Icons.call_outlined,
                        color: Colors.black,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),

            // Section: Tracking Map & Location
            if (_currentStatus != StatusCommande.delivered &&
                _currentStatus != StatusCommande.cancelled)
              if (_currentUserRole == Role.gerant ||
                  _currentUserRole == Role.coordinateur ||
                  _currentUserRole == Role.livreur)
                _buildTrackingMap()
              else if (widget.order.adresse != null ||
                  (widget.order.latitude != null &&
                      widget.order.longitude != null))
                _buildLocationSection(),

            // Section: Order Items
            _buildSection(
              'Order Items (${widget.order.lignes.length})',
              Icons.shopping_basket_outlined,
              Column(
                children: widget.order.lignes.map((ligne) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${ligne.quantite}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ligne.plat.nom,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              if (ligne.plat.description.isNotEmpty)
                                Text(
                                  ligne.plat.description,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${ligne.sousTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Section: Summary
            _buildSection(
              'Payment Summary',
              Icons.receipt_long_outlined,
              Column(
                children: [
                  _buildSummaryRow('Subtotal', widget.order.total),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Taxes & Local Fees',
                    widget.order.totalWithTax - widget.order.total,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.order.totalWithTax.toStringAsFixed(2)} TND',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Workflows
            if (_currentStatus == StatusCommande.created &&
                _currentUserRole == Role.gerant)
              _buildAssignAndAcceptSection(),

            if (_currentStatus == StatusCommande.accepted &&
                _currentUserRole == Role.coordinateur)
              _buildPreparationAction(),

            if (_currentStatus == StatusCommande.preparing &&
                _currentUserRole == Role.coordinateur)
              _buildReadyAction(),

            if (_currentStatus == StatusCommande.ready &&
                _currentUserRole == Role.livreur)
              _buildStartDeliveryAction(),

            if (_currentStatus == StatusCommande.delivering &&
                _currentUserRole == Role.livreur)
              _buildCompleteDeliveryAction(),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsInfo() {
    final showPOS =
        widget.order.posId != null && _currentUserRole != Role.coordinateur;
    final showLivreur = widget.order.livreurId != null;

    if (!showPOS && !showLivreur) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          if (showPOS)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.indigo,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREPARATION POINT',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _assignedPOSName ?? 'POS #${widget.order.posId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (showPOS && showLivreur)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.grey[100], height: 1),
            ),
          if (widget.order.livreurId != null)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_motorsports_rounded,
                    color: Colors.teal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVERY DRIVER',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _assignedLivreurName ??
                            'Driver #${widget.order.livreurId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAssignAndAcceptSection() {
    if (_isLoadingData) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return _buildSection(
      'Assignment Hub',
      Icons.assignment_ind_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PLEASE SELECT A PREPARATION POINT AND A DELIVERY DRIVER TO VALIDATE AND START THIS ORDER.',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),

          // POS Dropdown
          DropdownButtonFormField<PointDeVente>(
            decoration: InputDecoration(
              labelText: 'Select Point of Sale',
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black, width: 1),
              ),
            ),
            value: _selectedPOS,
            items: _availablePOS.map((pos) {
              return DropdownMenuItem(
                value: pos,
                child: Text(
                  pos.nom,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedPOS = value),
          ),
          const SizedBox(height: 16),

          // Livreur Dropdown
          DropdownButtonFormField<Utilisateur>(
            decoration: InputDecoration(
              labelText: 'Select Delivery Driver',
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              prefixIcon: const Icon(
                Icons.sports_motorsports_rounded,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black, width: 1),
              ),
            ),
            value: _selectedLivreur,
            items: _availableLivreurs.map((user) {
              return DropdownMenuItem(
                value: user,
                child: Text(
                  '${user.prenom} ${user.nom}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedLivreur = value),
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed:
                (_selectedPOS == null ||
                    _selectedLivreur == null ||
                    _isUpdating)
                ? null
                : _handleAcceptAndAssign,
            icon: _isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              _isUpdating ? 'PROCESSING...' : 'ACCEPT & ASSIGN ORDER',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptAndAssign() async {
    if (_selectedPOS == null || _selectedLivreur == null) return;

    setState(() => _isUpdating = true);

    try {
      // 1. Update order status to ACCEPTED
      // 2. Assign POS ID and Livreur ID

      // We need to update multiple fields, so let's check if the repository supports updateOrder
      // or if we need to manually update fields

      final updatedOrder = widget.order.copyWith(
        statut: StatusCommande.accepted,
        livreurId: _selectedLivreur!.id,
        posId: _selectedPOS!.id,
      );

      await _orderRepository.updateOrder(updatedOrder);

      // Send Notifications
      final notificationService = NotificationService();

      // Notify Livreur
      await notificationService.createNotification(
        userId: _selectedLivreur!.id,
        message: 'New order #${widget.order.id} assigned to you.',
        type: NotificationType.info,
        latitude: _selectedPOS!.latitude,
        longitude: _selectedPOS!.longitude,
      );

      // Notify Coordinateur (if assigned to POS and POS has a coordinator)
      if (_selectedPOS!.coordinateurId != null) {
        await notificationService.createNotification(
          userId: _selectedPOS!.coordinateurId!,
          message:
              'New order #${widget.order.id} assigned to your Point of Sale (${_selectedPOS!.nom}).',
          type: NotificationType.info,
        );
      }

      // Update local state is optional since we reload or navigate back usually,
      // but good for UX if staying on page
      setState(() {
        _currentStatus = StatusCommande.accepted;
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted and assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} TND',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPreparationAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _showPreparationTimeDialog,
        icon: const Icon(Icons.restaurant_rounded),
        label: const Text('START PREPARATION'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildReadyAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: _isUpdating
            ? null
            : () => _updateStatus(StatusCommande.ready),
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('MARK AS READY'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Future<void> _showPreparationTimeDialog() async {
    final controller = TextEditingController();
    final travelTime = _getTotalTravelTime();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estimation Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter estimated preparation time:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Preparation (min)',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
            ),
            if (travelTime > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calculated Travel Time: +$travelTime min',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final prepMinutes = int.tryParse(controller.text) ?? 0;
              if (prepMinutes > 0) {
                final totalMinutes = prepMinutes + travelTime;
                Navigator.pop(context);
                _updateStatus(
                  StatusCommande.preparing,
                  preparationTime: totalMinutes,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter preparation time'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    StatusCommande newStatus, {
    int? preparationTime,
  }) async {
    setState(() => _isUpdating = true);
    try {
      final updatedOrder = widget.order.copyWith(
        statut: newStatus,
        estimationPreparation:
            preparationTime ?? widget.order.estimationPreparation,
      );

      await _orderRepository.updateOrder(updatedOrder);

      setState(() {
        _currentStatus = newStatus;
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Optional: go back to list or stay
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStartDeliveryAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: _isUpdating
            ? null
            : () => _updateStatus(StatusCommande.delivering),
        icon: const Icon(Icons.delivery_dining_rounded),
        label: const Text('START DELIVERY'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteDeliveryAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: _isUpdating
            ? null
            : () => _updateStatus(StatusCommande.delivered),
        icon: const Icon(Icons.done_all_rounded),
        label: const Text('COMPLETE DELIVERY'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.0,
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

  Widget _buildLocationSection() {
    final hasCoords =
        widget.order.latitude != null && widget.order.longitude != null;

    return _buildSection(
      'Delivery Destination',
      Icons.location_on_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.order.adresse != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.order.adresse!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          if (hasCoords) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        widget.order.latitude!,
                        widget.order.longitude!,
                      ),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bestmlewi',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              widget.order.latitude!,
                              widget.order.longitude!,
                            ),
                            width: 50,
                            height: 60,
                            child: _buildMarkerWidget(
                              'DESTINATION',
                              Icons.location_on_rounded,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_currentUserRole != Role.coordinateur) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openInMaps(
                  widget.order.latitude!,
                  widget.order.longitude!,
                ),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('GET DIRECTIONS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingMap() {
    final List<Marker> markers = [];
    final List<LatLng> points = [];

    // 1. Order Marker
    final orderLatLng =
        (widget.order.latitude != null && widget.order.longitude != null)
        ? LatLng(widget.order.latitude!, widget.order.longitude!)
        : null;

    if (orderLatLng != null) {
      points.add(orderLatLng);
      markers.add(
        Marker(
          point: orderLatLng,
          width: 50,
          height: 60,
          child: _buildMarkerWidget(
            'CLIENT',
            Icons.person_pin_circle_rounded,
            Colors.red,
          ),
        ),
      );
    }

    // 2. POS Markers
    if (_currentStatus == StatusCommande.created) {
      for (final pos in _allPOS) {
        if (pos.latitude != null && pos.longitude != null) {
          final latLng = LatLng(pos.latitude!, pos.longitude!);
          points.add(latLng);
          markers.add(
            Marker(
              point: latLng,
              width: 50,
              height: 60,
              child: _buildMarkerWidget(
                pos.nom,
                Icons.storefront_rounded,
                Colors.blue,
              ),
            ),
          );
        }
      }
    } else if (_assignedPOS?.latitude != null &&
        _assignedPOS?.longitude != null) {
      final latLng = LatLng(_assignedPOS!.latitude!, _assignedPOS!.longitude!);
      points.add(latLng);
      markers.add(
        Marker(
          point: latLng,
          width: 50,
          height: 60,
          child: _buildMarkerWidget(
            'POS',
            Icons.storefront_rounded,
            Colors.blue,
          ),
        ),
      );
    }

    // 3. Livreur Marker
    LatLng? assignedLivreurLatLng;
    if (_assignedLivreur?.latitude != null &&
        _assignedLivreur?.longitude != null) {
      assignedLivreurLatLng = LatLng(
        _assignedLivreur!.latitude!,
        _assignedLivreur!.longitude!,
      );
    }

    if (_currentStatus == StatusCommande.created) {
      for (final livreur in _availableLivreurs) {
        if (livreur.latitude != null && livreur.longitude != null) {
          final latLng = LatLng(livreur.latitude!, livreur.longitude!);
          points.add(latLng);
          markers.add(
            Marker(
              point: latLng,
              width: 50,
              height: 60,
              child: _buildMarkerWidget(
                '${livreur.prenom}',
                Icons.motorcycle_rounded,
                Colors.green,
              ),
            ),
          );
        }
      }
    } else if (assignedLivreurLatLng != null) {
      points.add(assignedLivreurLatLng);
      markers.add(
        Marker(
          point: assignedLivreurLatLng,
          width: 50,
          height: 60,
          child: _buildMarkerWidget(
            'DRIVER',
            Icons.motorcycle_rounded,
            Colors.green,
          ),
        ),
      );
    }

    if (markers.isEmpty && widget.order.adresse == null) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      'Live Order Tracking',
      Icons.map_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.order.adresse != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.order.adresse!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (markers.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 300,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: points.length > 1
                          ? LatLng(
                              points
                                      .map((p) => p.latitude)
                                      .reduce((a, b) => a + b) /
                                  points.length,
                              points
                                      .map((p) => p.longitude)
                                      .reduce((a, b) => a + b) /
                                  points.length,
                            )
                          : (orderLatLng ??
                                (points.isNotEmpty
                                    ? points.first
                                    : const LatLng(0, 0))),
                      initialZoom: points.length > 1 ? 12 : 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bestmlewi',
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                Icons.person_pin_circle_rounded,
                Colors.red,
                'CLIENT',
              ),
              const SizedBox(width: 16),
              _buildLegendItem(Icons.storefront_rounded, Colors.blue, 'POS'),
              const SizedBox(width: 16),
              _buildLegendItem(
                Icons.motorcycle_rounded,
                Colors.green,
                'DRIVER',
              ),
            ],
          ),
          if (_assignedPOS?.latitude != null &&
              _assignedPOS?.longitude != null &&
              _currentStatus != StatusCommande.delivering &&
              _currentUserRole != Role.coordinateur) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _openInMaps(
                _assignedPOS!.latitude!,
                _assignedPOS!.longitude!,
              ),
              icon: const Icon(Icons.restaurant_rounded),
              label: const Text('DIRECTIONS TO RESTAURANT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
                elevation: 0,
              ),
            ),
          ],
          if (orderLatLng != null && _currentUserRole != Role.coordinateur) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  _openInMaps(orderLatLng.latitude, orderLatLng.longitude),
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('DIRECTIONS TO CLIENT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarkerWidget(String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(icon, color: color, size: 28),
      ],
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  /// Helper to calculate numeric travel time in minutes
  int _calculateMinutes(LatLng p1, LatLng p2) {
    final distanceInMeters = Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
    // Assume average speed of 20 km/h for city delivery (scooter/bike)
    return ((distanceInMeters / 1000) / 20 * 60).round();
  }

  /// Calculates total delivery travel time: (Livreur to POS) + (POS to Order)
  int _getTotalTravelTime() {
    int total = 0;

    final orderLatLng =
        (widget.order.latitude != null && widget.order.longitude != null)
        ? LatLng(widget.order.latitude!, widget.order.longitude!)
        : null;

    final posLatLng =
        (_assignedPOS?.latitude != null && _assignedPOS?.longitude != null)
        ? LatLng(_assignedPOS!.latitude!, _assignedPOS!.longitude!)
        : null;

    final livreurLatLng =
        (_assignedLivreur?.latitude != null &&
            _assignedLivreur?.longitude != null)
        ? LatLng(_assignedLivreur!.latitude!, _assignedLivreur!.longitude!)
        : null;

    // 1. Livreur to POS
    if (livreurLatLng != null && posLatLng != null) {
      total += _calculateMinutes(livreurLatLng, posLatLng);
    }

    // 2. POS to Order
    if (posLatLng != null && orderLatLng != null) {
      total += _calculateMinutes(posLatLng, orderLatLng);
    }

    return total;
  }
}
