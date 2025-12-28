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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.pos == null ? 'New Sales Point' : 'Edit Sales Point',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (widget.pos != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                onPressed: _isLoading ? null : _delete,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'Basic Information',
                      Icons.info_outline_rounded,
                    ),
                    _buildInputGroup([
                      _buildTextField(
                        controller: _nomController,
                        label: 'Sales Point Name',
                        icon: Icons.store_rounded,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      _buildAddressField(),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Working Hours', Icons.schedule_rounded),
                    _buildInputGroup([_buildTimePickerRow()]),
                    const SizedBox(height: 32),

                    _buildSectionTitle(
                      'Settings & Staff',
                      Icons.admin_panel_settings_outlined,
                    ),
                    _buildInputGroup([
                      _buildSwitch(
                        label: 'Active & Operational',
                        subtitle: 'Point of sale is visible to customers',
                        value: _actif,
                        onChanged: (v) => setState(() => _actif = v),
                      ),
                      _buildCoordinatorDropdown(),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionTitle(
                      'Available Collaborators (${_selectedCollaborateurIds.length})',
                      Icons.people_outline_rounded,
                    ),
                    _buildCollaboratorsList(),
                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Point of Sale',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.black87, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _adresseController,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Address',
                labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixIcon: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.black87,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.map_rounded,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPickerScreen(
                      initialLocation: _latitude != null && _longitude != null
                          ? LatLng(_latitude!, _longitude!)
                          : null,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _latitude = (result['location'] as LatLng).latitude;
                    _longitude = (result['location'] as LatLng).longitude;
                    _adresseController.text = result['address'];
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeSelector(
              label: 'Opening',
              time: _openingTime,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _openingTime,
                );
                if (picked != null) setState(() => _openingTime = picked);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.grey[300],
              size: 20,
            ),
          ),
          Expanded(
            child: _buildTimeSelector(
              label: 'Closing',
              time: _closingTime,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _closingTime,
                );
                if (picked != null) setState(() => _closingTime = picked);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Colors.black87,
                ),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.black,
      activeTrackColor: Colors.black12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
    );
  }

  Widget _buildCoordinatorDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned Coordinator',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButtonFormField<int>(
              value: _coordinateurs.any((u) => u.id == _selectedCoordinateurId)
                  ? _selectedCoordinateurId
                  : null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('No Coordinator Assigned'),
                ),
                ..._coordinateurs.map((user) {
                  return DropdownMenuItem<int>(
                    value: user.id,
                    child: Text('${user.prenom} ${user.nom}'),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _selectedCoordinateurId = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (_collaborateurs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No available collaborators found',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            ..._collaborateurs.map((user) {
              final isSelected = _selectedCollaborateurIds.contains(user.id);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withOpacity(0.02)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CheckboxListTile(
                  value: isSelected,
                  activeColor: Colors.black,
                  checkColor: Colors.white,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    '${user.prenom} ${user.nom}',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? Colors.black : Colors.black87,
                    ),
                  ),
                  secondary: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[100],
                    child: Text(
                      user.prenom.isNotEmpty
                          ? user.prenom[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        _selectedCollaborateurIds.add(user.id);
                      } else {
                        _selectedCollaborateurIds.remove(user.id);
                      }
                    });
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}
