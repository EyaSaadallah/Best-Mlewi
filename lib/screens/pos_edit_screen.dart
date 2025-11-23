import 'package:flutter/material.dart';
import '../models/point_de_vente.dart';
import '../repositories/point_de_vente_repository.dart';
import '../repositories/utilisateur_repository.dart';
import '../models/utilisateur.dart';
import '../models/enums.dart';

class PosEditScreen extends StatefulWidget {
  final PointDeVente? pos;

  const PosEditScreen({super.key, this.pos});

  @override
  State<PosEditScreen> createState() => _PosEditScreenState();
}

class _PosEditScreenState extends State<PosEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = PointDeVenteRepository();

  final _userRepository = UtilisateurRepository();

  late TextEditingController _nomController;
  late TextEditingController _adresseController;
  late TextEditingController _horairesController;
  bool _actif = true;
  bool _isLoading = false;

  List<Utilisateur> _coordinateurs = [];
  List<Utilisateur> _collaborateurs = [];
  int? _selectedCoordinateurId;
  List<int> _selectedCollaborateurIds = [];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.pos?.nom ?? '');
    _adresseController = TextEditingController(text: widget.pos?.adresse ?? '');
    _horairesController = TextEditingController(
      text: widget.pos?.horaires ?? '',
    );
    _actif = widget.pos?.actif ?? true;
    _selectedCoordinateurId = widget.pos?.coordinateurId;
    _selectedCollaborateurIds = List.from(widget.pos?.collaborateurIds ?? []);
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final coordinateurs = await _userRepository.getByRole(Role.coordinateur);
      final collaborateurs = await _userRepository.getByRole(
        Role.collaborateur,
      );

      if (mounted) {
        setState(() {
          // Filter active users only
          // Also filter out users who are already affected, UNLESS they are assigned to this POS
          _coordinateurs = coordinateurs.where((u) {
            final isAssignedToThisPos = widget.pos?.coordinateurId == u.id;
            return u.isActive &&
                u.isAvailable &&
                (!u.isAffected || isAssignedToThisPos);
          }).toList();

          _collaborateurs = collaborateurs.where((u) {
            final isAssignedToThisPos =
                widget.pos?.collaborateurIds.contains(u.id) ?? false;
            return u.isActive &&
                u.isAvailable &&
                (!u.isAffected || isAssignedToThisPos);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _horairesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final pos = PointDeVente(
      id: widget.pos?.id ?? DateTime.now().millisecondsSinceEpoch,
      nom: _nomController.text,
      adresse: _adresseController.text,
      horaires: _horairesController.text,
      actif: _actif,
      collaborateurs: widget.pos?.collaborateurs ?? [],
      menu: widget.pos?.menu,
      coordinateurId: _selectedCoordinateurId,
      collaborateurIds: _selectedCollaborateurIds,
    );

    try {
      // Calculate changes in user assignments
      final oldCoordinateurId = widget.pos?.coordinateurId;
      final newCoordinateurId = _selectedCoordinateurId;

      final oldCollaborateurIds = widget.pos?.collaborateurIds ?? [];
      final newCollaborateurIds = _selectedCollaborateurIds;

      // Update POS
      if (widget.pos == null) {
        await _repository.create(pos);
      } else {
        await _repository.updateByIntId(pos.id, pos);
      }

      // Update Coordinateur status
      if (oldCoordinateurId != newCoordinateurId) {
        // If there was an old coordinator, free them
        if (oldCoordinateurId != null) {
          // final oldUser = await _userRepository.getById(oldCoordinateurId);
          // We can't update just one field easily with current repo,
          // but we can fetch, modify, update.
          // Ideally repo should support partial updates.
          // For now, assuming we need to update the whole user object or add a method.
          // Let's use a direct update helper if possible, or just update the object.
          // Since we don't have partial update in repo interface yet, let's try to update the object.
          // Actually, to avoid race conditions and complexity, let's add updateStatus to repo later.
          // For now, let's assume we can update the user.
          // Wait, `update` in repo takes a full object.
          // Let's create a helper to toggle isAffected.
          await _updateUserAffectedStatus(oldCoordinateurId, false);
        }
        // If there is a new coordinator, mark them as affected
        if (newCoordinateurId != null) {
          await _updateUserAffectedStatus(newCoordinateurId, true);
        }
      }

      // Update Collaborateurs status
      // Find removed
      for (final id in oldCollaborateurIds) {
        if (!newCollaborateurIds.contains(id)) {
          await _updateUserAffectedStatus(id, false);
        }
      }
      // Find added
      for (final id in newCollaborateurIds) {
        if (!oldCollaborateurIds.contains(id)) {
          await _updateUserAffectedStatus(id, true);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sales point saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUserAffectedStatus(int userId, bool isAffected) async {
    try {
      // final user = await _userRepository.getById(userId);
      // Create a copy with updated status
      // Since models are immutable and we don't have copyWith on base class easily accessible for all subclasses without casting,
      // we might need to cast or use a repo method.
      // Best approach: Add `updateIsAffected` to UtilisateurRepository.
      // Since I cannot modify repo interface in this step easily without breaking things,
      // I will use a direct firestore update if possible or cast.
      // Actually, let's just use the repo's update method and handle the casting/recreation.
      // This is getting complicated.
      // SIMPLER: Add `updateIsAffected` to `UtilisateurRepository`.
      // I will do that in a separate step. For now, I'll assume it exists or implement it.
      // Let's implement it in the repo first.
      await _userRepository.updateIsAffected(userId, isAffected);
    } catch (e) {
      debugPrint('Error updating user status: $e');
    }
  }

  Future<void> _delete() async {
    if (widget.pos == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${widget.pos!.nom}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _repository.deleteByIntId(widget.pos!.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sales point deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pos == null ? 'New Sales Point' : 'Edit Sales Point',
        ),
        actions: [
          if (widget.pos != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adresseController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _horairesController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Hours',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Mon-Sun 09:00-22:00',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter opening hours';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: _actif,
                      onChanged: (value) => setState(() => _actif = value),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Staff Assignment',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Coordinator Dropdown
                    DropdownButtonFormField<int>(
                      value:
                          _coordinateurs.any(
                            (u) => u.id == _selectedCoordinateurId,
                          )
                          ? _selectedCoordinateurId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Coordinator',
                        border: OutlineInputBorder(),
                        helperText: 'Select one coordinator',
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('None'),
                        ),
                        ..._coordinateurs.map((user) {
                          return DropdownMenuItem<int>(
                            value: user.id,
                            child: Text('${user.prenom} ${user.nom}'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCoordinateurId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Collaborators Multi-select
                    Text(
                      'Collaborators',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: _collaborateurs.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No active collaborators found'),
                                ),
                              ]
                            : _collaborateurs.map((user) {
                                final isSelected = _selectedCollaborateurIds
                                    .contains(user.id);
                                return CheckboxListTile(
                                  title: Text('${user.prenom} ${user.nom}'),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedCollaborateurIds.add(user.id);
                                      } else {
                                        _selectedCollaborateurIds.remove(
                                          user.id,
                                        );
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
