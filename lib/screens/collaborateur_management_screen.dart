import 'package:flutter/material.dart';
import '../models/utilisateur.dart';

import '../models/enums.dart';
import '../repositories/utilisateur_repository.dart';
import '../services/email_service.dart';
import 'collaborateur_signup_screen.dart';
import 'collaborateur_edit_screen.dart';

class CollaborateurManagementScreen extends StatefulWidget {
  const CollaborateurManagementScreen({super.key});

  @override
  State<CollaborateurManagementScreen> createState() =>
      _CollaborateurManagementScreenState();
}

class _CollaborateurManagementScreenState
    extends State<CollaborateurManagementScreen> {
  final _repository = UtilisateurRepository();
  late Future<List<Utilisateur>> _futureCollaborateurs;
  Role? _selectedFilter; // null means 'All'
  final PageController _pageController = PageController();
  final List<Role?> _roleTabs = [
    null,
    Role.collaborateur,
    Role.livreur,
    Role.coordinateur,
  ];

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _refreshList() {
    setState(() {
      _futureCollaborateurs = Future.wait([
        _repository.getByRole(Role.collaborateur),
        _repository.getByRole(Role.livreur),
        _repository.getByRole(Role.coordinateur),
      ]).then((results) => results.expand((x) => x).toList());
    });
  }

  Future<void> _deleteCollaborateur(Utilisateur user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deactivation'),
        content: Text(
          'Are you sure you want to deactivate ${user.prenom} ${user.nom}? They will no longer be able to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deactivated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshList();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deactivating user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Staff Management',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CollaborateurSignupScreen(),
            ),
          );
          _refreshList();
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Staff',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<Utilisateur>>(
        future: _futureCollaborateurs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final allStaff = snapshot.data ?? [];
          if (allStaff.isEmpty) {
            return _buildEmptyState();
          }

          // Calculate counts for badges
          final counts = {
            null: allStaff.length,
            Role.collaborateur: allStaff
                .where((u) => u.role == Role.collaborateur)
                .length,
            Role.livreur: allStaff.where((u) => u.role == Role.livreur).length,
            Role.coordinateur: allStaff
                .where((u) => u.role == Role.coordinateur)
                .length,
          };

          return Column(
            children: [
              _buildFilterSection(counts),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _selectedFilter = _roleTabs[index]);
                  },
                  itemCount: _roleTabs.length,
                  itemBuilder: (context, pageIndex) {
                    final currentRole = _roleTabs[pageIndex];
                    final displayList = currentRole == null
                        ? allStaff
                        : allStaff.where((u) => u.role == currentRole).toList();

                    if (displayList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${currentRole?.name ?? "Staff"} members yet',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100, top: 8),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) =>
                          _buildStaffMemberCard(displayList[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(Map<Role?, int> counts) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterButton('All Staff', counts[null]!, null, 0),
            _buildFilterButton(
              'Collaborateurs',
              counts[Role.collaborateur]!,
              Role.collaborateur,
              1,
            ),
            _buildFilterButton(
              'Livreurs',
              counts[Role.livreur]!,
              Role.livreur,
              2,
            ),
            _buildFilterButton(
              'Coordinateurs',
              counts[Role.coordinateur]!,
              Role.coordinateur,
              3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, int count, Role? role, int index) {
    final isSelected = _selectedFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        selectedColor: Colors.black,
        backgroundColor: Colors.grey[100],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
        elevation: isSelected ? 4 : 0,
      ),
    );
  }

  Widget _buildStaffMemberCard(Utilisateur user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(18),
                image:
                    user.imageUrl != null &&
                        user.imageUrl!.isNotEmpty &&
                        user.imageUrl != 'none'
                    ? DecorationImage(
                        image: NetworkImage(user.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child:
                  user.imageUrl == null ||
                      user.imageUrl!.isEmpty ||
                      user.imageUrl == 'none'
                  ? Center(
                      child: Text(
                        user.prenom.isNotEmpty
                            ? user.prenom[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : null,
            ),
            title: Text(
              '${user.prenom} ${user.nom}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const SizedBox(height: 4), _buildRoleBadge(user.role)],
            ),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Divider(color: Colors.grey[50]),
                    const SizedBox(height: 8),
                    _buildStaffDetailRow(Icons.email_outlined, user.email),
                    const SizedBox(height: 8),
                    _buildStaffDetailRow(Icons.phone_outlined, user.telephone),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _editStaff(user),
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          label: const Text('Modify Details'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _deleteCollaborateur(user),
                          icon: const Icon(
                            Icons.no_accounts_rounded,
                            color: Colors.red,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(Role role) {
    Color color;
    IconData icon;
    switch (role) {
      case Role.coordinateur:
        color = Colors.blue;
        icon = Icons.layers_outlined;
        break;
      case Role.livreur:
        color = Colors.orange;
        icon = Icons.delivery_dining_rounded;
        break;
      default:
        color = Colors.green;
        icon = Icons.restaurant_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            role.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _editStaff(Utilisateur user) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollaborateurEditScreen(collaborateur: user),
      ),
    );
    if (updated != null && updated is Utilisateur) {
      try {
        final roleChanged = user.role != updated.role;
        final oldRoleName = user.role.name.toUpperCase();
        final newRoleName = updated.role.name.toUpperCase();

        await _repository.updateUser(updated);

        if (roleChanged) {
          await EmailService().sendRoleChangeNotification(
            toEmail: updated.email,
            firstName: updated.prenom,
            lastName: updated.nom,
            oldRole: oldRoleName,
            newRole: newRoleName,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                roleChanged
                    ? 'Staff member updated and notification sent'
                    : 'Staff member updated',
              ),
              backgroundColor: Colors.black,
            ),
          );
          _refreshList();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 80,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Staff Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CollaborateurSignupScreen(),
                  ),
                );
                _refreshList();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Register First Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
