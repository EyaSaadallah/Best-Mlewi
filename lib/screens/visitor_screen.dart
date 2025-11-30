import 'package:flutter/material.dart';
import 'dart:io';
import '../repositories/menu_repository.dart';
import '../repositories/utilisateur_repository.dart';
import '../models/menu.dart';
import '../models/plat.dart';
import '../services/firebase_auth_service.dart';
import '../models/utilisateur.dart';
import '../models/client.dart';
import '../models/enums.dart';
import '../services/notification_service.dart';
import '../models/notification.dart' as notif_model;
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../models/commande.dart';
import 'cart_screen.dart';
import 'login_screen.dart' as login_screen;
import 'profile_edit_screen.dart';

/// Visitor screen – unauthenticated users can browse the menu.
/// When a client is logged in, extra tabs (Profile, Notifications, Orders)
/// appear while keeping the menu as the Home tab.
class VisitorScreen extends StatefulWidget {
  const VisitorScreen({super.key});

  @override
  State<VisitorScreen> createState() => _VisitorScreenState();
}

class _VisitorScreenState extends State<VisitorScreen> {
  final _menuRepository = MenuRepository();
  final _authService = FirebaseAuthService();
  final _notificationService = NotificationService();

  int _selectedIndex = 0;

  Utilisateur? get _currentUser => _authService.currentUser;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // -------------------- UI TAB BUILDERS --------------------
  Widget _buildHomeTab() {
    return Column(
      children: [
        // Welcome banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple[400]!, Colors.deepPurple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Welcome to BestMlewi! 🍽️',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Browse our delicious menu. Login to place orders!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
        // Menu list
        Expanded(
          child: FutureBuilder<List<Menu>>(
            future: _menuRepository.getAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error loading menu'),
                    ],
                  ),
                );
              }
              final menus = snapshot.data ?? [];
              if (menus.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No menu available yet'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: menus.length,
                itemBuilder: (context, index) => _buildMenuCard(menus[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final user = _currentUser;
    if (user == null) return const Center(child: Text('Please log in'));
    final themeColor = _getRoleColor(user.role);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: themeColor,
                backgroundImage: user.imageUrl != null
                    ? NetworkImage(user.imageUrl!)
                    : null,
                child: user.imageUrl == null
                    ? Text(
                        user.prenom.isNotEmpty
                            ? user.prenom[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: themeColor,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileEditScreen(user: user),
                        ),
                      );

                      if (result != null && result is Map<String, dynamic>) {
                        try {
                          Utilisateur updatedUser;
                          if (user.role == Role.client) {
                            updatedUser = Client(
                              id: user.id,
                              nom: result['nom'],
                              prenom: result['prenom'],
                              email: user.email,
                              motDePasse: user.motDePasse,
                              telephone: result['telephone'],
                              dateInscription: user.dateInscription,
                              isActive: user.isActive,
                              isAffected: user.isAffected,
                              isAvailable: user.isAvailable,
                              adresse: result['adresse'],
                              imageUrl: result['imageUrl'],
                            );
                          } else {
                            updatedUser = Utilisateur(
                              id: user.id,
                              nom: result['nom'],
                              prenom: result['prenom'],
                              email: user.email,
                              motDePasse: user.motDePasse,
                              telephone: result['telephone'],
                              dateInscription: user.dateInscription,
                              role: user.role,
                              isActive: user.isActive,
                              isAffected: user.isAffected,
                              isAvailable: user.isAvailable,
                              imageUrl: result['imageUrl'],
                            );
                          }

                          await UtilisateurRepository().updateUser(updatedUser);
                          _authService.updateCurrentUser(updatedUser);

                          if (result['password'] != null &&
                              result['oldPassword'] != null) {
                            await _authService.updatePasswordWithReauth(
                              result['oldPassword'],
                              result['password'],
                            );
                          }

                          setState(() {});

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating profile: $e'),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${user.prenom} ${user.nom}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.withOpacity(0.3)),
            ),
            child: Text(
              user.role.name.toUpperCase(),
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileItem(Icons.email, 'Email', user.email),
          _buildProfileItem(Icons.phone, 'Phone', user.telephone),
          if (user is Client &&
              user.adresse != null &&
              user.adresse!.isNotEmpty)
            _buildProfileItem(Icons.location_on, 'Address', user.adresse!),
          _buildProfileItem(
            Icons.calendar_today,
            'Joined',
            user.dateInscription.toString().split(' ')[0],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final user = _currentUser;
    if (user == null) return const Center(child: Text('Please log in'));
    return StreamBuilder<List<notif_model.Notification>>(
      stream: _notificationService.getUserNotifications(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No notifications yet'),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  notif.message,
                  style: TextStyle(
                    fontWeight: notif.lu ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(notif.dateEnvoi.toString().split('.')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await _notificationService.deleteNotification(notif.id);
                    setState(() {});
                  },
                ),
                onTap: () => _notificationService.markAsRead(notif.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    final orderService = OrderService();
    final orders = orderService.getRecentOrders();

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding items to your cart',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Menu'),
              onPressed: () {
                _onItemTapped(0);
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Commande order) {
    final statusColor = _getStatusColor(order.statut);
    final deliveryFee = order.total * 0.05;
    final tax = order.total * 0.1;

    // Ensure totalWithTax is valid
    final totalWithTax = order.totalWithTax > 0
        ? order.totalWithTax
        : (order.total + deliveryFee + tax);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.dateCreation.toString().split('.')[0],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    order.statut.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Order items
            Text(
              'Items (${order.lignes.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...order.lignes.map((ligne) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${ligne.plat.nom} x${ligne.quantite}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${ligne.sousTotal.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Order summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: TextStyle(color: Colors.grey[700])),
                Text(
                  '\$${order.total.toStringAsFixed(2)} DT',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery', style: TextStyle(color: Colors.grey[700])),
                Text(
                  '\$${deliveryFee.toStringAsFixed(2)} DT',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax', style: TextStyle(color: Colors.grey[700])),
                Text(
                  '\$${tax.toStringAsFixed(2)} DT',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '\$${totalWithTax.toStringAsFixed(2)} DT',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(StatusCommande status) {
    switch (status) {
      case StatusCommande.created:
        return Colors.blue;
      case StatusCommande.preparing:
        return Colors.orange;
      case StatusCommande.ready:
        return Colors.purple;
      case StatusCommande.delivering:
        return Colors.teal;
      case StatusCommande.delivered:
        return Colors.green;
      case StatusCommande.cancelled:
        return Colors.red;
    }
  }

  Widget _buildLoginTab() {
    return const login_screen.LoginScreen();
  }

  // Helper widget for profile rows
  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.gerant:
        return Colors.deepPurple;
      case Role.coordinateur:
        return Colors.orange;
      case Role.livreur:
        return Colors.green;
      case Role.collaborateur:
        return Colors.blue;
      case Role.client:
        return Colors.deepPurple;
      default:
        return Colors.deepPurple;
    }
  }

  // Menu card helpers
  Widget _buildMenuCard(Menu menu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          menu.titre,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${menu.plats.length} dishes available'),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple[100],
          child: const Icon(Icons.restaurant, color: Colors.deepPurple),
        ),
        children: menu.getPlatDisponibles().map(_buildDishTile).toList(),
      ),
    );
  }

  Widget _buildDishTile(Plat plat) {
    final cartService = CartService();
    final user = _currentUser;
    final isClientLoggedIn = user != null && user.role == Role.client;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Dish image or icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: plat.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildDishImage(plat.imageUrl),
                    )
                  : const Icon(
                      Icons.restaurant_menu,
                      color: Colors.deepPurple,
                      size: 35,
                    ),
            ),
            const SizedBox(width: 12),
            // Dish details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plat.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plat.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plat.categorie,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '\$${plat.prix.toStringAsFixed(2)} DT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Add to cart button
            if (isClientLoggedIn)
              IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                color: Colors.green,
                onPressed: () {
                  cartService.addToCart(plat, 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${plat.nom} added to cart'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Bottom navigation
  List<BottomNavigationBarItem> _navItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    ];
    final user = _currentUser;
    if (user != null && user.role == Role.client) {
      items.addAll([
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Orders',
        ),
      ]);

      // Update Profile icon if image exists
      if (user.imageUrl != null) {
        items[1] = BottomNavigationBarItem(
          icon: CircleAvatar(
            radius: 12,
            backgroundImage: NetworkImage(user.imageUrl!),
          ),
          label: 'Profile',
        );
      }
    } else {
      // Add a Login tab for unauthenticated users
      // BottomNavigationBar requires at least 2 items
      items.add(
        const BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
      );
    }
    return items;
  }

  Widget _currentTab() {
    if (_selectedIndex == 0) return _buildHomeTab();
    final user = _currentUser;
    if (user != null && user.role == Role.client) {
      switch (_selectedIndex) {
        case 1:
          return _buildProfileTab();
        case 2:
          return _buildNotificationsTab();
        case 3:
          return _buildOrdersTab();
      }
    } else {
      // For unauthenticated users, index 1 is the Login tab
      if (_selectedIndex == 1) return _buildLoginTab();
    }
    return _buildHomeTab();
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final isClientLoggedIn = user != null && user.role == Role.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BestMlewi'),
        actions: [
          // Cart button (only for logged-in clients)
          if (isClientLoggedIn)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  tooltip: 'Shopping Cart',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
                // Cart badge showing item count
                if (CartService().getCartItemCount() > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${CartService().getCartItemCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          // Profile button (only for logged-in clients)
          if (isClientLoggedIn)
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileEditScreen(user: user),
                  ),
                );
                if (result != null) setState(() {});
              },
            ),
          // Logout button (only for logged-in clients)
          if (isClientLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _authService.signOutGoogle();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/visitor');
                  }
                }
              },
            ),
        ],
      ),
      body: _currentTab(),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems(),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Build dish image - handles both local files and network URLs
  Widget _buildDishImage(String imageUrl) {
    // Check if it's a local file path
    if (File(imageUrl).existsSync()) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.restaurant_menu,
            color: Colors.deepPurple,
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
        return const Icon(
          Icons.restaurant_menu,
          color: Colors.deepPurple,
          size: 35,
        );
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
