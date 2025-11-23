import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../models/enums.dart';
import '../models/utilisateur.dart';
import 'pos_management_screen.dart';
import 'menu_management_screen.dart';
import 'collaborateur_management_screen.dart';
import '../repositories/utilisateur_repository.dart';
import '../services/notification_service.dart';
import 'profile_edit_screen.dart';

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

  int _selectedIndex = 0;
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
      case Role.visiteur:
      default:
        return Colors.deepPurple;
    }
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
      appBar: AppBar(
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
      body: FutureBuilder<Utilisateur?>(
        future: _userRepository.getByEmail(user.email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final freshUser = snapshot.data ?? user;
          return _buildContent(freshUser.role, freshUser);
        },
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
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
    final notifications = _notificationService.getNotifications();
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
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
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: notif.type == NotificationType.error
                  ? Colors.red[100]
                  : Colors.blue[100],
              child: Icon(
                notif.type == NotificationType.error ? Icons.error : Icons.info,
                color: notif.type == NotificationType.error
                    ? Colors.red
                    : Colors.blue,
              ),
            ),
            title: Text(notif.message),
            subtitle: Text(
              notif.dateEnvoi.toString().split('.')[0],
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: !notif.lu
                ? const CircleAvatar(radius: 4, backgroundColor: Colors.blue)
                : null,
          ),
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
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
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
        // Update user details
        final updatedUser = Utilisateur(
          id: user.id,
          nom: result['nom'],
          prenom: result['prenom'],
          email: user.email,
          motDePasse: user.motDePasse, // Password not stored here
          telephone: result['telephone'],
          dateInscription: user.dateInscription,
          role: user.role,
          isActive: user.isActive,
          isAffected: user.isAffected,
          isAvailable: user.isAvailable,
        );

        await _userRepository.updateUser(updatedUser);

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple[400]!, Colors.deepPurple[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
                Text(
                  'You have full access to the BestMlewi management system',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Dashboard title
          Text(
            'Management Dashboard',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Menu cards
          _buildMenuCard(
            'Manage Commands',
            'View and manage all orders',
            Icons.assignment,
            () {},
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'Sales Points',
            'Manage restaurant locations',
            Icons.location_on,
            () {
              _homeNavigatorKey.currentState?.pushNamed('/pos');
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'Manage Categories',
            'Manage menus and dishes',
            Icons.restaurant,
            () {
              _homeNavigatorKey.currentState?.pushNamed('/menu');
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'Collaborators',
            'Manage staff and team members',
            Icons.people,
            () {
              _homeNavigatorKey.currentState?.pushNamed('/collaborateurs');
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'System Settings',
            'Configure system parameters',
            Icons.settings,
            () {},
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'Reports',
            'View analytics and reports',
            Icons.bar_chart,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateurContent(Utilisateur user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 24),
          _buildAvailabilitySwitch(user.isAvailable),
          const SizedBox(height: 24),
          Text(
            'Coordinator Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildMenuCard(
            'Track Preparation',
            'Monitor order preparation',
            Icons.track_changes,
            () {},
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurContent(Utilisateur user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 24),
          _buildAvailabilitySwitch(user.isAvailable),
          const SizedBox(height: 24),
          Text(
            'Delivery Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildMenuCard(
            'Active Deliveries',
            'Track current deliveries',
            Icons.local_shipping,
            () {},
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'Update Location',
            'Update delivery location',
            Icons.location_on,
            () {},
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborateurContent(Utilisateur user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 24),
          _buildAvailabilitySwitch(user.isAvailable),
          const SizedBox(height: 24),
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
            color: Colors.blue,
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
    final themeColor = color ?? Colors.deepPurple;
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

  BottomNavigationBar? _buildBottomNav(Role role) {
    if (role == Role.visiteur) {
      return null;
    }

    final themeColor = _getRoleColor(role);

    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: themeColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == _selectedIndex && index == 0) {
          // If already on Home, pop to root of nested navigator
          _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
    );
  }
}
