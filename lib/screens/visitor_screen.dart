import 'package:flutter/material.dart';
import '../repositories/menu_repository.dart';
import '../models/menu.dart';
import '../models/plat.dart';
import '../services/firebase_auth_service.dart';
import '../models/utilisateur.dart';
import '../models/client.dart';
import '../services/notification_service.dart';
import '../models/notification.dart' as notif_model;
import '../models/enums.dart';
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
                child: Text(
                  user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
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
                      if (result != null) setState(() {});
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
    // Placeholder – real implementation would fetch client orders.
    return const Center(child: Text('Your orders will appear here'));
  }

  Widget _buildLoginTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 80, color: Colors.deepPurple[300]),
            const SizedBox(height: 24),
            const Text(
              'Please Log In',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'To access your profile, notifications, and place orders, please log in to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Go to Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.restaurant_menu, color: Colors.deepPurple),
      ),
      title: Text(
        plat.nom,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(plat.description),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              plat.categorie,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '\${plat.prix.toStringAsFixed(2)} DT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[900],
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Bottom navigation
  List<BottomNavigationBarItem> _navItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    ];
    if (_currentUser != null && _currentUser!.role == Role.client) {
      items.addAll(const [
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
      ]);
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
}
