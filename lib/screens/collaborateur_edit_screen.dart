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
      appBar: AppBar(title: const Text('Edit Collaborator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Read-only Email
              TextFormField(
                initialValue: widget.collaborateur.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  enabled: false,
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => Validators.validateName(value),
              ),
              const SizedBox(height: 16),
              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => Validators.validateName(value),
              ),
              const SizedBox(height: 16),
              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => Validators.validatePhone(value),
              ),
              const SizedBox(height: 16),
              // Role selection
              DropdownButtonFormField<Role>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.badge),
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
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
