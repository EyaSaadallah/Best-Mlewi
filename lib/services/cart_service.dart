import '../models/plat.dart';
import '../models/ligne_commande.dart';

/// Service for managing shopping cart
class CartService {
  static final CartService _instance = CartService._internal();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  final List<LigneCommande> _cartItems = [];

  /// Get all cart items
  List<LigneCommande> getCartItems() {
    return List.unmodifiable(_cartItems);
  }

  /// Get cart item count
  int getCartItemCount() {
    return _cartItems.length;
  }

  /// Get total quantity of items in cart
  int getTotalQuantity() {
    return _cartItems.fold(0, (sum, item) => sum + item.quantite);
  }

  /// Get cart total price
  double getCartTotal() {
    return _cartItems.fold(0.0, (sum, item) => sum + item.sousTotal);
  }

  /// Add item to cart
  void addToCart(Plat plat, int quantity) {
    try {
      // Check if item already exists in cart
      final existingIndex = _cartItems.indexWhere(
        (item) => item.plat.id == plat.id,
      );

      if (existingIndex != -1) {
        // Update quantity if item exists
        final existingItem = _cartItems[existingIndex];
        final newQuantity = existingItem.quantite + quantity;
        final newSousTotal = newQuantity * plat.prix;

        _cartItems[existingIndex] = LigneCommande(
          id: existingItem.id,
          quantite: newQuantity,
          prixUnitaire: plat.prix,
          sousTotal: newSousTotal,
          plat: plat,
        );
      } else {
        // Add new item to cart
        final sousTotal = quantity * plat.prix;
        final ligneCommande = LigneCommande(
          id: DateTime.now().millisecondsSinceEpoch,
          quantite: quantity,
          prixUnitaire: plat.prix,
          sousTotal: sousTotal,
          plat: plat,
        );
        _cartItems.add(ligneCommande);
      }
    } catch (e) {
      throw Exception('Error adding item to cart: $e');
    }
  }

  /// Remove item from cart
  void removeFromCart(int platId) {
    try {
      _cartItems.removeWhere((item) => item.plat.id == platId);
    } catch (e) {
      throw Exception('Error removing item from cart: $e');
    }
  }

  /// Update item quantity
  void updateQuantity(int platId, int newQuantity) {
    try {
      final index = _cartItems.indexWhere((item) => item.plat.id == platId);
      if (index != -1) {
        if (newQuantity <= 0) {
          removeFromCart(platId);
        } else {
          final item = _cartItems[index];
          final newSousTotal = newQuantity * item.prixUnitaire;
          _cartItems[index] = LigneCommande(
            id: item.id,
            quantite: newQuantity,
            prixUnitaire: item.prixUnitaire,
            sousTotal: newSousTotal,
            plat: item.plat,
          );
        }
      }
    } catch (e) {
      throw Exception('Error updating quantity: $e');
    }
  }

  /// Clear cart
  void clearCart() {
    _cartItems.clear();
  }

  /// Check if cart is empty
  bool isCartEmpty() {
    return _cartItems.isEmpty;
  }

  /// Get cart item by plat ID
  LigneCommande? getCartItem(int platId) {
    try {
      return _cartItems.firstWhere((item) => item.plat.id == platId);
    } catch (e) {
      return null;
    }
  }
}
