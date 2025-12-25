import 'package:flutter/material.dart';
import 'dart:io';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/firebase_auth_service.dart' as auth_service;
import '../models/ligne_commande.dart';
import 'map_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import '../models/utilisateur.dart';

/// Shopping cart screen
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartService.getCartItems();
    final cartTotal = _cartService.getCartTotal();

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart'), elevation: 0),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),
                _buildCartSummary(cartItems, cartTotal),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from the menu to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Continue Shopping'),
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(LigneCommande item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dish image or icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.plat.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildCartItemImage(item.plat.imageUrl),
                        )
                      : const Icon(
                          Icons.restaurant_menu,
                          color: Colors.black,
                          size: 35,
                        ),
                ),
                const SizedBox(width: 12),
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.plat.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.plat.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${item.prixUnitaire.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quantity controls and subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          color: Colors.black,
                          onPressed: () {
                            setState(() {
                              if (item.quantite > 1) {
                                _cartService.updateQuantity(
                                  item.plat.id,
                                  item.quantite - 1,
                                );
                              } else {
                                _cartService.removeFromCart(item.plat.id);
                              }
                            });
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantite}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          color: Colors.black,
                          onPressed: () {
                            setState(() {
                              _cartService.updateQuantity(
                                item.plat.id,
                                item.quantite + 1,
                              );
                            });
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                // Subtotal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '\$${item.sousTotal.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(List<LigneCommande> items, double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items (${items.length})',
                style: TextStyle(color: Colors.grey[700]),
              ),
              Text(
                '\$${total.toStringAsFixed(2)} DT',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: Colors.grey[700])),
              Text(
                '\$${(total * 0.05).toStringAsFixed(2)} DT',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax', style: TextStyle(color: Colors.grey[700])),
              Text(
                '\$${(total * 0.1).toStringAsFixed(2)} DT',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '\$${(total + (total * 0.05) + (total * 0.1)).toStringAsFixed(2)} DT',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _cartService.clearCart();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Clear Cart'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final authService = auth_service.FirebaseAuthService();
                      final currentUser = authService.currentUser;

                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to place an order'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      final orderService = OrderService();
                      final cartItems = _cartService.getCartItems();

                      if (cartItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cart is empty'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      // Show Address Selection Dialog
                      if (mounted) {
                        final addressResult =
                            await showDialog<Map<String, dynamic>>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => _AddressSelectionDialog(
                                currentUser: currentUser,
                              ),
                            );

                        if (addressResult == null) return; // User cancelled

                        final String? finalAddress = addressResult['address'];
                        final double? finalLat = addressResult['latitude'];
                        final double? finalLng = addressResult['longitude'];

                        // Create order and save to Firestore with client ID
                        final firestoreId = await orderService
                            .createOrderWithClientId(
                              cartItems,
                              currentUser.id,
                              adresse: finalAddress,
                              latitude: finalLat,
                              longitude: finalLng,
                            );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Order placed successfully! ID: $firestoreId',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );

                          // Clear cart after successful order
                          setState(() {
                            _cartService.clearCart();
                          });

                          Navigator.pop(context);
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error placing order: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Checkout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build cart item image - handles both local files and network URLs
  Widget _buildCartItemImage(String imageUrl) {
    // Check if it's a local file path
    if (File(imageUrl).existsSync()) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.restaurant_menu,
            color: Colors.black,
            size: 35,
          );
        },
      );
    }

    // Otherwise treat as network URL
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.restaurant_menu, color: Colors.black, size: 35);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }
}

class _AddressSelectionDialog extends StatefulWidget {
  final Utilisateur currentUser;

  const _AddressSelectionDialog({required this.currentUser});

  @override
  State<_AddressSelectionDialog> createState() =>
      _AddressSelectionDialogState();
}

class _AddressSelectionDialogState extends State<_AddressSelectionDialog> {
  bool _useProfileAddress = true;
  final _customAddressController = TextEditingController();
  double? _customLat;
  double? _customLng;

  @override
  void initState() {
    super.initState();
    _useProfileAddress = widget.currentUser.adresse != null;
  }

  @override
  void dispose() {
    _customAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delivery Address'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<bool>(
            title: const Text('My Profile Address'),
            subtitle: Text(
              widget.currentUser.adresse ?? 'No address set in profile',
              style: const TextStyle(fontSize: 12),
            ),
            value: true,
            groupValue: _useProfileAddress,
            onChanged: widget.currentUser.adresse != null
                ? (value) {
                    setState(() => _useProfileAddress = value!);
                  }
                : null,
          ),
          RadioListTile<bool>(
            title: const Text('Other Address'),
            value: false,
            groupValue: _useProfileAddress,
            onChanged: (value) {
              setState(() => _useProfileAddress = value!);
            },
          ),
          if (!_useProfileAddress) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customAddressController,
                    decoration: const InputDecoration(
                      hintText: 'Custom address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    readOnly: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapPickerScreen(
                          initialLocation:
                              (_customLat != null && _customLng != null)
                              ? LatLng(_customLat!, _customLng!)
                              : null,
                        ),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _customLat = (result['location'] as LatLng).latitude;
                        _customLng = (result['location'] as LatLng).longitude;
                        _customAddressController.text = result['address'];
                      });
                    }
                  },
                ),
              ],
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
            if (_useProfileAddress) {
              Navigator.pop(context, {
                'address': widget.currentUser.adresse,
                'latitude': widget.currentUser.latitude,
                'longitude': widget.currentUser.longitude,
              });
            } else {
              if (_customAddressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an address')),
                );
                return;
              }
              Navigator.pop(context, {
                'address': _customAddressController.text,
                'latitude': _customLat,
                'longitude': _customLng,
              });
            }
          },
          child: const Text('Confirm Order'),
        ),
      ],
    );
  }
}
