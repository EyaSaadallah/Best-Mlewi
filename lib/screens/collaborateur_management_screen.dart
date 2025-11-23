import 'package:flutter/material.dart';
import '../models/utilisateur.dart';

import '../models/enums.dart';
import '../repositories/utilisateur_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshList();
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
      appBar: AppBar(title: const Text('Manage Staff')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CollaborateurSignupScreen(),
            ),
          );
          _refreshList();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Utilisateur>>(
        future: _futureCollaborateurs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No staff members found',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CollaborateurSignupScreen(),
                        ),
                      );
                      _refreshList();
                    },
                    child: const Text('Add First Staff Member'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final user = list[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.prenom.isNotEmpty
                          ? user.prenom[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text('${user.prenom} ${user.nom}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CollaborateurEditScreen(collaborateur: user),
                            ),
                          );
                          if (updated != null && updated is Utilisateur) {
                            try {
                              await _repository.updateUser(updated);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Staff member updated'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _refreshList();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCollaborateur(user),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
