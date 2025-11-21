import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../models/enums.dart';
import 'pos_management_screen.dart';
import 'menu_management_screen.dart';

/// Home screen showing different content based on user role
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = FirebaseAuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('BestMiawi')),
        body: const Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BestMiawi'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${user.prenom} (${user.role.name})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () async {
                  await _authService.signOutGoogle();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: _buildContent(user.role),
      bottomNavigationBar: _buildBottomNav(user.role),
    );
  }

  Widget _buildContent(Role role) {
    switch (role) {
      case Role.client:
        return _buildClientContent();
      case Role.gerant:
        return _buildGerantContent();
      case Role.coordinateur:
        return _buildCoordinateurContent();
      case Role.livreur:
        return _buildLivreurContent();
      case Role.collaborateur:
        return _buildCollaborateurContent();
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
                  'You have full access to the BestMiawi management system',
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PosManagementScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'Manage Categories',
            'Manage menus and dishes',
            Icons.restaurant,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MenuManagementScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'Collaborators',
            'Manage staff and team members',
            Icons.people,
            () {},
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

  Widget _buildCoordinateurContent() {
    return SingleChildScrollView(
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
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurContent() {
    return SingleChildScrollView(
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
            () {},
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            'Update Location',
            'Update delivery location',
            Icons.location_on,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborateurContent() {
    return SingleChildScrollView(
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
            'Welcome to BestMiawi',
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
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  BottomNavigationBar? _buildBottomNav(Role role) {
    if (role == Role.visiteur) {
      return null;
    }

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
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}
