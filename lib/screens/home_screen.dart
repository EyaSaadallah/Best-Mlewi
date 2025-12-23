import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../models/enums.dart';
import '../models/utilisateur.dart';
import '../models/client.dart';
import 'pos_management_screen.dart';
import 'menu_management_screen.dart';
import 'collaborateur_management_screen.dart';
import 'gerant/orders_management_screen.dart';
import '../repositories/utilisateur_repository.dart';
import '../services/notification_service.dart';
import '../models/notification.dart' as notif_model;
import 'profile_edit_screen.dart';
import '../widgets/gerant_dashboard.dart';
import 'coordinateur/coordinateur_orders_screen.dart';
import 'livreur/livreur_orders_screen.dart';

/// Home screen showing different content based on user role
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = FirebaseAuthService();
  final _userRepository = UtilisateurRepository();
  final _notificationService = NotificationService();
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0; // IndexedStack index
  int _selectedButtonIndex = 0; // BottomNavigationBar index
  bool _isUpdatingAvailability = false;

  Future<void> _toggleAvailability(bool value) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isUpdatingAvailability = true);
    try {
      await _userRepository.updateIsAvailable(user.id, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Availability updated to ${value ? "Available" : "Unavailable"}',
            ),
          ),
        );
        // Force rebuild to fetch fresh data
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating availability: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvailability = false);
      }
    }
  }

  Widget _buildAvailabilitySwitch(bool currentStatus) {
    return SwitchListTile(
      title: const Text('Available for Assignment'),
      subtitle: Text(
        currentStatus
            ? 'You are visible to managers'
            : 'You are hidden from managers',
      ),
      value: currentStatus,
      onChanged: _isUpdatingAvailability
          ? null
          : (value) {
              _toggleAvailability(value);
            },
    );
  }

  Color _getRoleColor(Role role) {
    // Consistent black theme for all roles
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('BestMlewi')),
        body: const Center(child: Text('Please login first')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Handle nested navigation back press
        if (_selectedIndex == 0 &&
            _homeNavigatorKey.currentState != null &&
            _homeNavigatorKey.currentState!.canPop()) {
          _homeNavigatorKey.currentState!.pop();
          return;
        }

        // If on other tabs, go back to home
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }

        // If at root of home, let system handle exit (or show dialog)
        // For now we allow exit if we are at root
        // To actually exit, we need to manually trigger it or allow pop
        // But since we set canPop: false, we are blocking it.
        // We can use SystemNavigator.pop() or just return if we want to block.
        // Let's allow pop if we are at root.
        // Since we can't change canPop dynamically easily here without setState,
        // we'll just leave it as is (blocking back button at root) or implement proper exit logic.
        // For this requirement, blocking accidental exit is fine, or we can show a dialog.
      },
      child: Scaffold(
        // No AppBar here, each tab/screen handles its own AppBar
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(user),
            _buildNotificationsTab(),
            _buildProfileTab(user),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(user.role),
      ),
    );
  }

  Widget _buildHomeTab(Utilisateur user) {
    return Navigator(
      key: _homeNavigatorKey,
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = _buildDashboard(user);
            break;
          case '/pos':
            page = const PosManagementScreen();
            break;
          case '/collaborateurs':
            page = const CollaborateurManagementScreen();
            break;
          case '/menu':
            page = const MenuManagementScreen();
            break;
          default:
            page = _buildDashboard(user);
        }
        return MaterialPageRoute(builder: (_) => page);
      },
    );
  }

  Widget _buildDashboard(Utilisateur user) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        // Explicitly add drawer button for gerant, coordinateur, and livreur
        leading:
            (user.role == Role.gerant ||
                user.role == Role.coordinateur ||
                user.role == Role.livreur)
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              )
            : null,
        title: const Text('BestMlewi'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${user.prenom} (${user.role.name})',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      // Add drawer for gerant, coordinateur, and livreur
      drawer:
          (user.role == Role.gerant ||
              user.role == Role.coordinateur ||
              user.role == Role.livreur)
          ? _buildAppDrawer()
          : null,
      body: Column(
        children: [
          // Only show banner for clients, not for staff
          if (user.role == Role.client)
            Image.asset(
              'images/home_banner_modern.png',
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Expanded(
            child: FutureBuilder<Utilisateur?>(
              future: _userRepository.getByEmail(user.email),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final freshUser = snapshot.data ?? user;
                return _buildContent(freshUser.role, freshUser);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDrawer() {
    final user = _authService.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${user?.prenom} ${user?.nom}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.role.name.toUpperCase() ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.black),
            title: const Text('Dashboard'),
            onTap: () {
              _scaffoldKey.currentState?.closeDrawer();
            },
          ),
          const Divider(),

          if (user?.role == Role.gerant) ...[
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.black),
              title: const Text('Manage Commands'),
              subtitle: const Text('View and manage all orders'),
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrdersManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.black),
              title: const Text('Sales Points'),
              subtitle: const Text('Manage restaurant locations'),
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                _homeNavigatorKey.currentState?.pushNamed('/pos');
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant, color: Colors.black),
              title: const Text('Manage Categories'),
              subtitle: const Text('Manage menus and dishes'),
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                _homeNavigatorKey.currentState?.pushNamed('/menu');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.black),
              title: const Text('Collaborators'),
              subtitle: const Text('Manage staff and team members'),
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                _homeNavigatorKey.currentState?.pushNamed('/collaborateurs');
              },
            ),
          ],

          if (user?.role == Role.coordinateur) ...[
            ListTile(
              leading: const Icon(Icons.checklist_rtl, color: Colors.black),
              title: const Text('Coordinate Orders'),
              subtitle: const Text('View active orders for your POS'),
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoordinateurOrdersScreen(),
                  ),
                );
              },
            ),
          ],

          if (user?.role == Role.livreur) ...[
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.black),
              title: const Text('My Deliveries'),
              subtitle: const Text('View your assigned orders'),
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LivreurOrdersScreen(),
                  ),
                );
              },
            ),
          ],

          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.black),
            title: const Text('System Settings'),
            subtitle: const Text('Configure system parameters'),
            onTap: () {
              _scaffoldKey.currentState?.closeDrawer();
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final user = _authService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Delete All button
          if (user != null)
            StreamBuilder<List<notif_model.Notification>>(
              stream: _notificationService.getUserNotifications(user.id),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) return const SizedBox.shrink();

                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Delete All',
                  onPressed: () async {
                    // Show confirmation dialog
                    final shouldDeleteAll = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete All Notifications'),
                        content: Text(
                          'Are you sure you want to delete all ${notifications.length} notification(s)?',
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Delete All'),
                          ),
                        ],
                      ),
                    );

                    if (shouldDeleteAll == true) {
                      await _notificationService.deleteAllNotifications(
                        user.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications deleted'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: _buildNotifications(),
    );
  }

  Widget _buildProfileTab(Utilisateur user) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Utilisateur?>(
        future: _userRepository.getByEmail(user.email),
        builder: (context, snapshot) {
          final freshUser = snapshot.data ?? user;
          return _buildProfile(freshUser);
        },
      ),
    );
  }

  Widget _buildNotifications() {
    final user = _authService.currentUser;
    if (user == null) return const Center(child: Text('Please login'));

    return StreamBuilder<List<notif_model.Notification>>(
      stream: _notificationService.getUserNotifications(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return Dismissible(
              key: Key(notif.id.toString()),
              background: Container(
                color: Colors.black,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _notificationService.deleteNotification(notif.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Icon(
                      notif.type == NotificationType.error
                          ? Icons.error
                          : Icons.info,
                      color: Colors.black,
                    ),
                  ),
                  title: Text(
                    notif.message,
                    style: TextStyle(
                      fontWeight: !notif.lu
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notif.dateEnvoi.toString().split('.')[0],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!notif.lu)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: const CircleAvatar(
                            radius: 4,
                            backgroundColor: Colors.black,
                          ),
                        ),
                      // Delete button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            // Show confirmation dialog
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Notification'),
                                content: const Text(
                                  'Are you sure you want to delete this notification?',
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete == true) {
                              await _notificationService.deleteNotification(
                                notif.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notification deleted'),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.black54,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!notif.lu) {
                      _notificationService.markAsRead(notif.id);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfile(Utilisateur user) {
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
                    onPressed: () => _handleEditProfile(user),
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

          // Info Cards
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

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Availability for staff (except Gerant)
          if (user.role != Role.client &&
              user.role != Role.visiteur &&
              user.role != Role.gerant) ...[
            _buildAvailabilitySwitch(user.isAvailable),
            const SizedBox(height: 24),
          ],

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _authService.signOutGoogle();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/visitor');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditProfile(Utilisateur user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileEditScreen(user: user)),
    );

    if (result != null && result is Map<String, dynamic>) {
      try {
        // Update user details based on user type
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

        await _userRepository.updateUser(updatedUser);
        _authService.updateCurrentUser(updatedUser);

        // Update password if provided
        if (result['password'] != null && result['oldPassword'] != null) {
          await _authService.updatePasswordWithReauth(
            result['oldPassword'],
            result['password'],
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          setState(() {}); // Refresh UI
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
        }
      }
    }
  }

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

  Widget _buildContent(Role role, Utilisateur user) {
    switch (role) {
      case Role.client:
        return _buildClientContent();
      case Role.gerant:
        return _buildGerantContent();
      case Role.coordinateur:
        return _buildCoordinateurContent(user);
      case Role.livreur:
        return _buildLivreurContent(user);
      case Role.collaborateur:
        return _buildCollaborateurContent(user);
      case Role.visiteur:
        return _buildVisiteurContent();
    }
  }

  Widget _buildClientContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Client!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildMenuCard(
            'Browse Menu',
            'View available dishes',
            Icons.restaurant_menu,
            () {},
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'My Orders',
            'Check your orders',
            Icons.shopping_bag,
            () {},
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'Order History',
            'View past orders',
            Icons.history,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGerantContent() {
    final user = _authService.currentUser;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Gerant! 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome ${user?.prenom} ${user?.nom}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.menu, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Open the menu to access management tools',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Dashboard with Statistics and Charts
          const GerantDashboard(),
        ],
      ),
    );
  }

  Widget _buildCoordinateurContent(Utilisateur user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello Coordinateur! 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome ${user.prenom} ${user.nom}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coordinator Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                _buildMenuCard(
                  'Track Preparation',
                  'Monitor order preparation',
                  Icons.track_changes,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CoordinateurOrdersScreen(),
                      ),
                    );
                  },
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurContent(Utilisateur user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello Livreur! 🛵',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome ${user.prenom} ${user.nom}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                _buildMenuCard(
                  'Active Deliveries',
                  'Track current deliveries',
                  Icons.local_shipping,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LivreurOrdersScreen(),
                      ),
                    );
                  },
                  color: Colors.black,
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  'Update Location',
                  'Update delivery location',
                  Icons.location_on,
                  () {},
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborateurContent(Utilisateur user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello Collaborateur! 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome ${user.prenom} ${user.nom}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collaborator Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                _buildMenuCard(
                  'Availability',
                  'Manage your availability',
                  Icons.calendar_today,
                  () {},
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisiteurContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to BestMlewi',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildMenuCard(
            'Browse Menu',
            'View our dishes',
            Icons.restaurant_menu,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    final themeColor = color ?? Colors.black;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 32, color: themeColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNav(Role role) {
    final user = _authService.currentUser;
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    ];

    if (role == Role.client || role == Role.visiteur) {
      if (role == Role.client) {
        items.addAll([
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: user?.imageUrl != null
                ? CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(user!.imageUrl!),
                  )
                : const Icon(Icons.person),
            label: 'Profile',
          ),
        ]);
      } else {
        // Visitor
        items.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Login',
          ),
        );
      }
    } else {
      // Staff roles
      // Only add notifications for non-gerant staff
      if (role != Role.gerant) {
        items.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        );
      }
      items.add(
        BottomNavigationBarItem(
          icon: user?.imageUrl != null
              ? CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(user!.imageUrl!),
                )
              : const Icon(Icons.person),
          label: 'Profile',
        ),
      );
    }

    return BottomNavigationBar(
      currentIndex: _selectedButtonIndex,
      onTap: (index) {
        // Map navigation bar index to IndexedStack index
        int stackIndex = index;

        // For gerant: skip notifications index
        if (role == Role.gerant && index > 0) {
          stackIndex =
              index + 1; // Profile is at index 2, but button is at index 1
        }

        if (stackIndex == _selectedIndex && stackIndex == 0) {
          // If already on Home, pop to root of nested navigator
          _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        } else {
          setState(() {
            _selectedIndex = stackIndex;
            _selectedButtonIndex = index;
          });
        }
      },
      items: items,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _getRoleColor(role),
      unselectedItemColor: Colors.grey,
    );
  }
}
