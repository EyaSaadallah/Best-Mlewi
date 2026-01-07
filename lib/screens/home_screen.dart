import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_auth_service.dart';
import '../models/enums.dart';
import '../models/utilisateur.dart';
import '../models/client.dart';
import '../models/livreur.dart';
import '../models/coordinateur.dart';
import '../models/collaborateur.dart';
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
import 'client/client_orders_screen.dart';
import 'visitor_screen.dart';
import '../widgets/account_switch_helper.dart';

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
      activeColor: Colors.black,
      activeTrackColor: Colors.black12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: const Text(
        'Available for Assignment',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        currentStatus
            ? 'You are visible to managers'
            : 'You are hidden from managers',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
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
                Text(
                  'Your inbox is empty',
                  style: const TextStyle(
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
                            // Type Indicator Icon
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
                            // Content
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

  Widget _buildProfile(Utilisateur user) {
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
                      onTap: () => _handleEditProfile(user),
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

                // Staff Specific Section
                if (user.role != Role.client &&
                    user.role != Role.visiteur &&
                    user.role != Role.gerant) ...[
                  const Text(
                    'Work Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: _buildAvailabilitySwitch(user.isAvailable),
                  ),
                  const SizedBox(height: 32),
                ],

                // Switch Account Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => AccountSwitchHelper.showSwitchAccountModal(
                      context,
                      _authService,
                      (success) {
                        if (success) {
                          setState(() {
                            // Home screen will automatically refresh with new user
                          });
                        }
                      },
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text(
                      'Switch Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
            latitude: result['latitude'],
            longitude: result['longitude'],
            imageUrl: result['imageUrl'],
          );
        } else if (user.role == Role.livreur) {
          updatedUser = Livreur(
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
            imageUrl: result['imageUrl'],
            adresse: result['adresse'],
            latitude: result['latitude'],
            longitude: result['longitude'],
          );
        } else if (user.role == Role.coordinateur) {
          updatedUser = Coordinateur(
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
            imageUrl: result['imageUrl'],
            adresse: result['adresse'],
            latitude: result['latitude'],
            longitude: result['longitude'],
          );
        } else if (user.role == Role.collaborateur) {
          updatedUser = Collaborateur(
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
            imageUrl: result['imageUrl'],
            adresse: result['adresse'],
            latitude: result['latitude'],
            longitude: result['longitude'],
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
            adresse: result['adresse'],
            latitude: result['latitude'],
            longitude: result['longitude'],
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
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VisitorScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'My Orders',
            'Check your orders',
            Icons.shopping_bag,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClientOrdersScreen(),
                ),
              );
            },
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

  Future<void> _openInMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
