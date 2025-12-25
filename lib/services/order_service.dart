import '../models/commande.dart';
import '../models/ligne_commande.dart';
import '../models/enums.dart';
import '../repositories/order_repository.dart';

/// Service for managing client orders
class OrderService {
  static final OrderService _instance = OrderService._internal();

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  final List<Commande> _orders = [];
  final OrderRepository _orderRepository = OrderRepository();
  int _nextOrderId = 1;

  /// Get all orders
  List<Commande> getOrders() {
    return List.unmodifiable(_orders);
  }

  /// Get order by ID
  Commande? getOrderById(int id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Create new order from cart items (in-memory only)
  Commande createOrder(List<LigneCommande> cartItems) {
    try {
      if (cartItems.isEmpty) {
        throw Exception('Cannot create order with empty cart');
      }

      final orderId = _nextOrderId++;
      final total = cartItems.fold(0.0, (sum, item) => sum + item.sousTotal);
      final deliveryFee = total * 0.05;
      final tax = total * 0.1;
      final totalWithTax = total + deliveryFee + tax;

      final order = Commande(
        id: orderId,
        dateCreation: DateTime.now(),
        total: total,
        totalWithTax: totalWithTax,
        statut: StatusCommande.created,
        lignes: List.from(cartItems),
      );

      _orders.add(order);
      return order;
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  /// Create order and save to Firestore with client ID
  Future<String> createOrderWithClientId(
    List<LigneCommande> cartItems,
    int clientId, {
    String? adresse,
    double? latitude,
    double? longitude,
  }) async {
    try {
      if (cartItems.isEmpty) {
        throw Exception('Cannot create order with empty cart');
      }

      // Get the highest order ID from Firestore for this specific client
      final orderId = await _orderRepository.getNextOrderId(clientId);

      final total = cartItems.fold(0.0, (sum, item) => sum + item.sousTotal);
      final deliveryFee = total * 0.05;
      final tax = total * 0.1;
      final totalWithTax = total + deliveryFee + tax;

      final order = Commande(
        id: orderId,
        dateCreation: DateTime.now(),
        total: total,
        totalWithTax: totalWithTax,
        statut: StatusCommande.created,
        lignes: List.from(cartItems),
        adresse: adresse,
        latitude: latitude,
        longitude: longitude,
      );

      // Save to Firestore
      final firestoreId = await _orderRepository.createOrderWithClientId(
        order,
        clientId,
      );

      // Also keep in memory
      _orders.add(order);

      // Update the in-memory counter to stay in sync
      if (orderId >= _nextOrderId) {
        _nextOrderId = orderId + 1;
      }

      return firestoreId;
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  /// Get orders from Firestore by client ID
  Future<List<Commande>> getOrdersByClientIdFromFirestore(int clientId) async {
    try {
      return await _orderRepository.getOrdersByClientId(clientId);
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  /// Update order status
  void updateOrderStatus(int orderId, StatusCommande newStatus) {
    try {
      final order = getOrderById(orderId);
      if (order != null) {
        order.changerStatut(newStatus);
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  /// Cancel order
  void cancelOrder(int orderId) {
    try {
      final order = getOrderById(orderId);
      if (order != null) {
        order.changerStatut(StatusCommande.cancelled);
      }
    } catch (e) {
      throw Exception('Error cancelling order: $e');
    }
  }

  /// Get orders by status
  List<Commande> getOrdersByStatus(StatusCommande status) {
    return _orders.where((o) => o.statut == status).toList();
  }

  /// Get recent orders (last N orders)
  List<Commande> getRecentOrders({int limit = 10}) {
    final sorted = List<Commande>.from(_orders);
    sorted.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return sorted.take(limit).toList();
  }

  /// Clear all orders (for testing)
  void clearOrders() {
    _orders.clear();
    _nextOrderId = 1;
  }

  /// Get total number of orders
  int getOrderCount() {
    return _orders.length;
  }

  /// Check if orders exist
  bool hasOrders() {
    return _orders.isNotEmpty;
  }
}
