import 'package:flutter/material.dart';
import '../models/utilisateur.dart';
import '../models/enums.dart';
import '../utils/validators.dart';

class CollaborateurEditScreen extends StatefulWidget {
  final Utilisateur collaborateur;

  const CollaborateurEditScreen({super.key, required this.collaborateur});

  @override
  State<CollaborateurEditScreen> createState() =>
      _CollaborateurEditScreenState();
}

class _CollaborateurEditScreenState extends State<CollaborateurEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late Role _selectedRole;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.collaborateur.prenom,
    );
    _lastNameController = TextEditingController(text: widget.collaborateur.nom);
    _phoneController = TextEditingController(
      text: widget.collaborateur.telephone,
    );
    _selectedRole = widget.collaborateur.role;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = Utilisateur(
      id: widget.collaborateur.id,
      nom: _lastNameController.text.trim(),
      prenom: _firstNameController.text.trim(),
      email: widget.collaborateur.email,
      motDePasse: widget.collaborateur.motDePasse,
      telephone: _phoneController.text.trim(),
      dateInscription: widget.collaborateur.dateInscription,
      role: _selectedRole,
      isActive: widget.collaborateur.isActive,
      isAffected: widget.collaborateur.isAffected,
      isAvailable: widget.collaborateur.isAvailable,
      fcmToken: widget.collaborateur.fcmToken,
      imageUrl: widget.collaborateur.imageUrl,
      adresse: widget.collaborateur.adresse,
      latitude: widget.collaborateur.latitude,
      longitude: widget.collaborateur.longitude,
    );

    Navigator.pop(context, updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Member',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Staff Profile', Icons.badge_outlined),
              _buildInputGroup([
                // Read-only Email
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alternate_email_rounded,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Address (Immutable)',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.collaborateur.email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: Colors.grey[50], height: 1),
                ),
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) => Validators.validateName(value),
                ),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) => Validators.validateName(value),
                ),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_iphone_rounded,
                  isPhone: true,
                  validator: (value) => Validators.validatePhone(value),
                ),
              ]),
              const SizedBox(height: 32),

              _buildSectionTitle(
                'Permissions & Role',
                Icons.admin_panel_settings_outlined,
              ),
              _buildInputGroup([_buildRoleSelection()]),
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
                    'Update Staff Member',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
    bool isPhone = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
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

  Widget _buildRoleSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<Role>(
          value: _selectedRole,
          decoration: InputDecoration(
            labelText: 'Operational Role',
            labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: Colors.black87,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black,
          ),
          items: const [
            DropdownMenuItem(
              value: Role.collaborateur,
              child: Text('Collaborateur'),
            ),
            DropdownMenuItem(value: Role.livreur, child: Text('Livreur')),
            DropdownMenuItem(
              value: Role.coordinateur,
              child: Text('Coordinateur'),
            ),
          ],
          onChanged: (Role? value) {
            if (value != null) setState(() => _selectedRole = value);
          },
        ),
      ),
    );
  }
}
