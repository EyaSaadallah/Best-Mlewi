import 'package:flutter/material.dart';
import '../models/point_de_vente.dart';
import '../repositories/point_de_vente_repository.dart';
import '../repositories/utilisateur_repository.dart';
import '../models/utilisateur.dart';
import '../models/enums.dart';
import 'map_picker_screen.dart';
import 'package:latlong2/latlong.dart';

import '../services/notification_service.dart';

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
  final _notificationService = NotificationService();

  late TextEditingController _nomController;
  late TextEditingController _adresseController;
  TimeOfDay _openingTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);
  double? _latitude;
  double? _longitude;
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
    if (widget.pos != null) {
      _openingTime = _parseTime(widget.pos!.openingTime);
      _closingTime = _parseTime(widget.pos!.closingTime);
    }
    _latitude = widget.pos?.latitude;
    _longitude = widget.pos?.longitude;
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
    super.dispose();
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return const TimeOfDay(hour: 8, minute: 0);
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final pos = PointDeVente(
      id: widget.pos?.id ?? DateTime.now().millisecondsSinceEpoch,
      nom: _nomController.text,
      adresse: _adresseController.text,
      latitude: _latitude,
      longitude: _longitude,
      openingTime: _formatTime(_openingTime),
      closingTime: _formatTime(_closingTime),
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
      await _userRepository.updateIsAffected(userId, isAffected);

      // Create notification
      final message = isAffected
          ? 'You have been assigned to ${_nomController.text}'
          : 'You have been removed from ${_nomController.text}';

      await _notificationService.createNotification(
        userId: userId,
        message: message,
        type: NotificationType.info,
      );
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
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
                        ),
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapPickerScreen(
                                  initialLocation:
                                      (_latitude != null && _longitude != null)
                                      ? LatLng(_latitude!, _longitude!)
                                      : null,
                                ),
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                _latitude =
                                    (result['location'] as LatLng).latitude;
                                _longitude =
                                    (result['location'] as LatLng).longitude;
                                _adresseController.text = result['address'];
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Working Hours',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _openingTime,
                              );
                              if (picked != null) {
                                setState(() => _openingTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Opening Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(_openingTime.format(context)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _closingTime,
                              );
                              if (picked != null) {
                                setState(() => _closingTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Closing Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time_filled),
                              ),
                              child: Text(_closingTime.format(context)),
                            ),
                          ),
                        ),
                      ],
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
