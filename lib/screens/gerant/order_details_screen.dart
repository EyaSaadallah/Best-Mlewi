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

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.statut;
    _loadCurrentUserRole();
    _loadAssignedNames();
    if (_currentStatus == StatusCommande.created) {
      _loadAssignmentData();
    }
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
          setState(() {
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
          setState(() {
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
          _availablePOS = posList.where((p) => p.isOpenNow).toList();

          // Filter: Role Livreur AND Active/Available AND Not Busy
          _availableLivreurs = livreurs.where((l) {
            final isFree = !busyLivreurIds.contains(l.id);
            return l.isAvailable && l.isActive && isFree;
          }).toList();

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
        title: Text('Order #${widget.order.id}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.8), statusColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(_currentStatus),
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getStatusLabel(_currentStatus),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat(
                      'EEEE, MMM dd, yyyy • HH:mm',
                    ).format(widget.order.dateCreation),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer Info
            if (_clientName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSection(
                  'Customer',
                  Icons.person,
                  Text(
                    _clientName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            // Assignments Section (if accepted or later)
            if (_currentStatus != StatusCommande.created)
              _buildAssignmentsInfo(),

            // Preparation Time Info
            if (widget.order.estimationPreparation != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildSection(
                  'Preparation Estimate',
                  Icons.timer,
                  Text(
                    '${widget.order.estimationPreparation} minutes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Order Items
            _buildSection(
              'Order Items',
              Icons.shopping_bag,
              Column(
                children: widget.order.lignes.map((ligne) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${ligne.quantite}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ligne.plat.nom,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (ligne.plat.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    ligne.plat.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${ligne.prixUnitaire.toStringAsFixed(2)} TND each',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${ligne.sousTotal.toStringAsFixed(2)} TND',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Order Summary
            _buildSection(
              'Order Summary',
              Icons.receipt,
              Column(
                children: [
                  _buildSummaryRow('Subtotal', widget.order.total),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Tax & Fees',
                    widget.order.totalWithTax - widget.order.total,
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Total',
                    widget.order.totalWithTax,
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Assignment & Acceptance Workflow (Gerant Only)
            if (_currentStatus == StatusCommande.created &&
                _currentUserRole == Role.gerant)
              _buildAssignAndAcceptSection(),

            // Preparation Workflow (Coordinateur Only)
            if (_currentStatus == StatusCommande.accepted &&
                _currentUserRole == Role.coordinateur)
              _buildPreparationAction(),

            // Ready Workflow (Coordinateur Only)
            if (_currentStatus == StatusCommande.preparing &&
                _currentUserRole == Role.coordinateur)
              _buildReadyAction(),

            // Delivery Workflow (Livreur Only)
            if (_currentStatus == StatusCommande.ready &&
                _currentUserRole == Role.livreur)
              _buildStartDeliveryAction(),

            if (_currentStatus == StatusCommande.delivering &&
                _currentUserRole == Role.livreur)
              _buildCompleteDeliveryAction(),

            const SizedBox(height: 16),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsInfo() {
    // Only show if we recorded ids (which we will going forward)
    if (widget.order.livreurId == null && widget.order.posId == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            if (widget.order.posId != null)
              Row(
                children: [
                  const Icon(Icons.store, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Point of Sale',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _assignedPOSName ?? 'POS #${widget.order.posId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (widget.order.posId != null && widget.order.livreurId != null)
              const Divider(height: 24),
            if (widget.order.livreurId != null)
              Row(
                children: [
                  const Icon(Icons.delivery_dining, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Delivery Person',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _assignedLivreurName ??
                              'Livreur #${widget.order.livreurId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignAndAcceptSection() {
    if (_isLoadingData) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return _buildSection(
      'Assign & Accept',
      Icons.assignment_ind,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select a Point of Sale and Delivery Person to accept this order.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // POS Dropdown
          DropdownButtonFormField<PointDeVente>(
            decoration: InputDecoration(
              labelText: 'Point of Sale',
              prefixIcon: const Icon(Icons.store),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: _selectedPOS,
            items: _availablePOS.map((pos) {
              return DropdownMenuItem(value: pos, child: Text(pos.nom));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedPOS = value);
            },
          ),
          const SizedBox(height: 12),

          // Livreur Dropdown
          DropdownButtonFormField<Utilisateur>(
            decoration: InputDecoration(
              labelText: 'Delivery Person',
              prefixIcon: const Icon(Icons.delivery_dining),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: _selectedLivreur,
            items: _availableLivreurs.map((user) {
              return DropdownMenuItem(
                value: user,
                child: Text('${user.prenom} ${user.nom}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedLivreur = value);
            },
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed:
                (_selectedPOS == null ||
                    _selectedLivreur == null ||
                    _isUpdating)
                ? null
                : _handleAcceptAndAssign,
            icon: _isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isUpdating ? 'Updating...' : 'Accept & Assign Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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

      final updatedOrder = Commande(
        id: widget.order.id,
        dateCreation: widget.order.dateCreation,
        total: widget.order.total,
        totalWithTax: widget.order.totalWithTax,
        statut: StatusCommande.accepted, // Change status
        lignes: widget.order.lignes,
        livreurId: _selectedLivreur!.id, // Assign Livreur
        posId: _selectedPOS!.id, // Assign POS
        clientId: widget.order.clientId, // Preserve Client
      );

      await _orderRepository.updateOrder(updatedOrder);

      // Send Notifications
      final notificationService = NotificationService();

      // Notify Livreur
      await notificationService.createNotification(
        userId: _selectedLivreur!.id,
        message: 'New order #${widget.order.id} assigned to you.',
        type: NotificationType.info,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} TND',
          style: TextStyle(
            fontSize: isTotal ? 20 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPreparationAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _showPreparationTimeDialog,
        icon: const Icon(Icons.restaurant),
        label: const Text('Start Preparation'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildReadyAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _isUpdating
            ? null
            : () => _updateStatus(StatusCommande.ready),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Mark as Ready'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showPreparationTimeDialog() async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preparation Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter estimated preparation time in minutes:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                Navigator.pop(context);
                _updateStatus(
                  StatusCommande.preparing,
                  preparationTime: minutes,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid time')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start'),
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
      final updatedOrder = Commande(
        id: widget.order.id,
        dateCreation: widget.order.dateCreation,
        total: widget.order.total,
        totalWithTax: widget.order.totalWithTax,
        statut: newStatus,
        lignes: widget.order.lignes,
        livreurId: widget.order.livreurId,
        posId: widget.order.posId,
        clientId: widget.order.clientId,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _isUpdating
            ? null
            : () => _updateStatus(StatusCommande.delivering),
        icon: const Icon(Icons.delivery_dining),
        label: const Text('Start Delivery'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteDeliveryAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _isUpdating
            ? null
            : () => _updateStatus(StatusCommande.delivered),
        icon: const Icon(Icons.done_all),
        label: const Text('Complete Delivery'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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

  IconData _getStatusIcon(StatusCommande status) {
    switch (status) {
      case StatusCommande.created:
        return Icons.receipt_long;
      case StatusCommande.accepted:
        return Icons.thumb_up;
      case StatusCommande.preparing:
        return Icons.restaurant;
      case StatusCommande.ready:
        return Icons.check_circle_outline;
      case StatusCommande.delivering:
        return Icons.delivery_dining;
      case StatusCommande.delivered:
        return Icons.done_all;
      case StatusCommande.cancelled:
        return Icons.cancel;
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
