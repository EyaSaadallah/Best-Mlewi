import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../repositories/menu_repository.dart';
import '../models/menu.dart';
import '../models/plat.dart';
import '../services/firebase_auth_service.dart';
import '../models/utilisateur.dart';
import '../models/enums.dart';
import '../services/notification_service.dart';
import '../models/notification.dart' as notif_model;
import '../services/cart_service.dart';
import '../models/commande.dart';
import '../repositories/order_repository.dart';
import 'cart_screen.dart';
import 'dish_details_screen.dart';
import 'login_screen.dart' as login_screen;
import 'profile_edit_screen.dart';
import 'client/client_order_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  int _selectedIndex = 0;

  Utilisateur? get _currentUser => _authService.currentUser;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String categoryTitle) {
    final key = _categoryKeys[categoryTitle];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // -------------------- UI TAB BUILDERS --------------------
  Widget _buildHomeTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Cart Button
                if (_currentUser != null && _currentUser!.role == Role.client)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Special Offer Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.asset(
                            'images/home_banner_modern.png', // Ensure this exists or use a placeholder
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'SPECIAL OFFER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'SAVE NOW!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black45,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Categories Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey[600]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Menu/Categories List
                  FutureBuilder<List<Menu>>(
                    future: _menuRepository.getAll(),
                    builder: (context, snapshot) {
                      // Debug prints
                      print('=== MENU DEBUG ===');
                      print('Connection state: ${snapshot.connectionState}');
                      print('Has error: ${snapshot.hasError}');
                      if (snapshot.hasError) {
                        print('Error: ${snapshot.error}');
                      }
                      print('Has data: ${snapshot.hasData}');
                      if (snapshot.hasData) {
                        print('Menu count: ${snapshot.data!.length}');
                        for (var menu in snapshot.data!) {
                          print(
                            'Menu: ${menu.titre}, Dishes: ${menu.plats.length}',
                          );
                        }
                      }
                      print('=== END DEBUG ===');

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading menu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  '${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No menu available'));
                      }

                      final menus = snapshot.data!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Horizontal Categories (Menus)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: menus.length,
                              itemBuilder: (context, index) {
                                final menu = menus[index];
                                return GestureDetector(
                                  onTap: () {
                                    // Scroll to the category section
                                    _scrollToCategory(menu.titre);
                                  },
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.grey[100],
                                          child: const Icon(
                                            Icons.fastfood,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          menu.titre,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Vertical Categories with Dishes
                          ...menus.map((menu) {
                            final dishes = menu.getPlatDisponibles();
                            if (dishes.isEmpty) return const SizedBox.shrink();

                            // Create or get GlobalKey for this category
                            _categoryKeys.putIfAbsent(
                              menu.titre,
                              () => GlobalKey(),
                            );

                            return Column(
                              key: _categoryKeys[menu.titre],
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    16,
                                  ),
                                  child: Text(
                                    menu.titre,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                    itemCount: dishes.length,
                                    itemBuilder: (context, index) {
                                      return _buildDishCard(dishes[index]);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          }).toList(),

                          const SizedBox(
                            height: 80,
                          ), // Bottom padding for nav bar
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(Plat plat) {
    final cartService = CartService();
    final user = _currentUser;
    final isClientLoggedIn = user != null && user.role == Role.client;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DishDetailsScreen(plat: plat)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 140,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: plat.imageUrl.isNotEmpty
                    ? _buildDishImage(plat.imageUrl)
                    : Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        plat.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        plat.categorie,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${plat.prix.toStringAsFixed(2)}dt',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isClientLoggedIn)
                          GestureDetector(
                            onTap: () {
                              cartService.addToCart(plat, 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${plat.nom} added to cart'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Colors.black,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 14,
                              ),
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
  }

  Widget _buildProfileTab() {
    final user = _currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Premium Header with Avatar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 40),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey[900],
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
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileEditScreen(user: user),
                          ),
                        );

                        if (result != null && result is Map<String, dynamic>) {
                          try {
                            // Update local state if needed
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
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${user.prenom} ${user.nom}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoGroup([
                  _buildProfileItem(
                    Icons.email_outlined,
                    'Email Address',
                    user.email,
                  ),
                  _buildProfileItem(
                    Icons.phone_outlined,
                    'Phone Number',
                    user.telephone,
                  ),
                  if (user.adresse != null && user.adresse!.isNotEmpty)
                    _buildProfileItem(
                      Icons.location_on_outlined,
                      'Main Address',
                      user.adresse!,
                    ),
                  _buildProfileItem(
                    Icons.calendar_today_outlined,
                    'Member Since',
                    user.dateInscription.toString().split(' ')[0],
                  ),
                ]),

                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _authService.logout();
                      setState(() {
                        _selectedIndex = 0; // Reset to Home tab
                      });
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (idx < children.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.grey[50], height: 1),
                ),
            ],
          );
        }).toList(),
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
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll notify you when something happens',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            final color = _getNotifColor(notif.type);

            return Dismissible(
              key: Key(notif.id.toString()),
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _notificationService.deleteNotification(notif.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: notif.lu ? Colors.white : color.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: notif.lu
                        ? Colors.grey[100]!
                        : color.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    if (!notif.lu)
                      BoxShadow(
                        color: color.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (!notif.lu) {
                          _notificationService.markAsRead(notif.id);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: notif.lu
                                    ? Colors.grey[50]
                                    : color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _getNotifIcon(notif.type),
                                color: notif.lu ? Colors.grey[400] : color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        notif.type.name.toUpperCase(),
                                        style: TextStyle(
                                          color: notif.lu
                                              ? Colors.grey[400]
                                              : color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'HH:mm',
                                        ).format(notif.dateEnvoi),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif.message,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: notif.lu
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (notif.latitude != null &&
                                      notif.longitude != null &&
                                      !notif.message.contains(
                                        'assigned to your Point of Sale',
                                      )) ...[
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => _openInMaps(
                                        notif.latitude!,
                                        notif.longitude!,
                                      ),
                                      icon: const Icon(
                                        Icons.map_outlined,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'VIEW ON MAP',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: Colors.black45,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(notif.dateEnvoi),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!notif.lu)
                              Container(
                                margin: const EdgeInsets.only(left: 12, top: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _notificationService
                                  .deleteNotification(notif.id),
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: Colors.grey[300],
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getNotifColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.redAccent;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.indigo;
    }
  }

  IconData _getNotifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline_rounded;
      case NotificationType.error:
        return Icons.error_outline_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }

  Widget _buildOrdersTab() {
    final user = _currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view orders'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('commandes')
          .where('clientId', isEqualTo: user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _onItemTapped(0);
                  },
                ),
              ],
            ),
          );
        }

        // Sort docs by dateCreation field
        final sortedDocs = docs.toList();
        sortedDocs.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['dateCreation'] as Timestamp;
          final bTime =
              (b.data() as Map<String, dynamic>)['dateCreation'] as Timestamp;
          return bTime.compareTo(aTime);
        });

        // Remove duplicate orders with the same order ID
        // Keep only the most recent version (based on Firestore document)
        final Map<int, DocumentSnapshot> uniqueOrders = {};
        for (final doc in sortedDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final orderId = data['id'] as int;

          // If this order ID hasn't been seen yet, add it
          if (!uniqueOrders.containsKey(orderId)) {
            uniqueOrders[orderId] = doc;
          }
        }

        // Convert back to list for display
        final uniqueDocs = uniqueOrders.values.toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: uniqueDocs.length,
            itemBuilder: (context, index) {
              final doc = uniqueDocs[index];
              final order = OrderRepository().fromFirestore(doc);
              return _buildOrderCard(order, doc.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Commande order, String docId) {
    final statusColor = _getStatusColor(order.statut);
    final deliveryFee = order.total * 0.05;
    final tax = order.total * 0.1;

    final totalWithTax = order.totalWithTax > 0
        ? order.totalWithTax
        : (order.total + deliveryFee + tax);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClientOrderDetailsScreen(order: order, docId: docId),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: #ID and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • HH:mm',
                            ).format(order.dateCreation),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(order.statut),
                              color: statusColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              order.statut.name.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),

                  // Items Preview
                  ...order.lignes.map((ligne) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${ligne.quantite}x',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ligne.plat.nom,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '${ligne.sousTotal.toStringAsFixed(2)} TND',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),

                  // Total and Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          Text(
                            '${totalWithTax.toStringAsFixed(2)} TND',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      if (order.statut == StatusCommande.delivering)
                        _buildActionButton(
                          'Track',
                          Icons.radar_rounded,
                          Colors.black,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientOrderDetailsScreen(
                                order: order,
                                docId: docId,
                              ),
                            ),
                          ),
                        )
                      else if (order.statut != StatusCommande.cancelled &&
                          order.statut != StatusCommande.created)
                        _buildActionButton(
                          'Details',
                          Icons.arrow_forward_ios,
                          Colors.grey[800]!,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientOrderDetailsScreen(
                                order: order,
                                docId: docId,
                              ),
                            ),
                          ),
                          isSmall: true,
                        )
                      else if (order.statut == StatusCommande.created)
                        _buildActionButton(
                          'Cancel',
                          Icons.close,
                          Colors.red[600]!,
                          () => _handleCancelOrder(order.id),
                        ),
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isSmall = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isSmall ? 14 : 18),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isSmall ? 12 : 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  IconData _getStatusIcon(StatusCommande status) {
    switch (status) {
      case StatusCommande.created:
        return Icons.timer_outlined;
      case StatusCommande.accepted:
        return Icons.check_circle_outline;
      case StatusCommande.preparing:
        return Icons.restaurant_menu;
      case StatusCommande.ready:
        return Icons.shopping_bag_outlined;
      case StatusCommande.delivering:
        return Icons.delivery_dining;
      case StatusCommande.delivered:
        return Icons.home_work_outlined;
      case StatusCommande.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Future<void> _handleCancelOrder(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel Order #$orderId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await OrderRepository().updateStatusById(
          orderId,
          StatusCommande.cancelled,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh list
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
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

  // Bottom navigation
  List<BottomNavigationBarItem> _navItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
    ];
    final user = _currentUser;
    if (user != null && user.role == Role.client) {
      items.addAll([
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
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
    return Scaffold(
      body: _currentTab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: _navItems(),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
        ),
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
          return Container(
            color: Colors.grey[100],
            child: const Icon(Icons.restaurant, color: Colors.grey),
          );
        },
      );
    }

    // Otherwise treat as network URL
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[100],
          child: const Icon(Icons.restaurant, color: Colors.grey),
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

  Future<void> _openInMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
