import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/utilisateur.dart';
import '../models/client.dart';
import '../models/enums.dart';
import '../services/imagekit_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final Utilisateur user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;
  late TextEditingController _passwordController;
  late TextEditingController _oldPasswordController;

  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  File? _imageFile;
  String? _imageUrl;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user.nom);
    _prenomController = TextEditingController(text: widget.user.prenom);
    _telephoneController = TextEditingController(text: widget.user.telephone);
    _adresseController = TextEditingController(
      text: widget.user is Client ? (widget.user as Client).adresse ?? '' : '',
    );
    _passwordController = TextEditingController();
    _oldPasswordController = TextEditingController();
    _imageUrl = widget.user.imageUrl;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _passwordController.dispose();
    _oldPasswordController.dispose();
    super.dispose();
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
      default:
        return Colors.deepPurple;
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getRoleColor(widget.user.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: themeColor,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_imageUrl != null ? NetworkImage(_imageUrl!) : null)
                              as ImageProvider?,
                    child: (_imageFile == null && _imageUrl == null)
                        ? Text(
                            widget.user.prenom.isNotEmpty
                                ? widget.user.prenom[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18),
                        color: themeColor,
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                  if (_imageFile != null || _imageUrl != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 15,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _imageFile = null;
                              _imageUrl = null;
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _prenomController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telephoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              // Show address field only for clients
              if (widget.user.role == Role.client) ...[
                TextFormField(
                  controller: _adresseController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on, color: themeColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeColor, width: 2),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  helperText: 'Required only if changing password',
                  prefixIcon: Icon(Icons.lock_outline, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: themeColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureOldPassword = !_obscureOldPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureOldPassword,
                validator: (value) {
                  if (_passwordController.text.isNotEmpty &&
                      (value == null || value.isEmpty)) {
                    return 'Old password is required to set a new one';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password (Optional)',
                  helperText: 'Leave empty to keep current password',
                  prefixIcon: Icon(Icons.lock, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: themeColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureNewPassword,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() => _isLoading = true);
                            try {
                              String? newImageUrl = _imageUrl;
                              final imageService = ImageKitService();

                              // Case 1: New image selected
                              if (_imageFile != null) {
                                // Delete old image if exists
                                if (widget.user.imageUrl != null) {
                                  await imageService.deleteImage(
                                    widget.user.imageUrl!,
                                  );
                                }

                                final fileName =
                                    'user_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                newImageUrl = await imageService.uploadImage(
                                  _imageFile!,
                                  fileName,
                                );
                              }
                              // Case 2: Image removed (and no new image selected)
                              else if (_imageUrl == null &&
                                  widget.user.imageUrl != null) {
                                await imageService.deleteImage(
                                  widget.user.imageUrl!,
                                );
                                newImageUrl = null;
                              }

                              final result = {
                                'nom': _nomController.text,
                                'prenom': _prenomController.text,
                                'telephone': _telephoneController.text,
                                'password': _passwordController.text.isNotEmpty
                                    ? _passwordController.text
                                    : null,
                                'oldPassword':
                                    _oldPasswordController.text.isNotEmpty
                                    ? _oldPasswordController.text
                                    : null,
                                'imageUrl': newImageUrl,
                              };

                              // Add address if user is client
                              if (widget.user.role == Role.client) {
                                result['adresse'] =
                                    _adresseController.text.isNotEmpty
                                    ? _adresseController.text
                                    : null;
                              }

                              if (mounted) {
                                Navigator.pop(context, result);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error saving profile: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
