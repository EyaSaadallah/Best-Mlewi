import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/utilisateur.dart';

import '../models/enums.dart';
import '../services/imagekit_service.dart';
import 'map_picker_screen.dart';
import 'package:latlong2/latlong.dart';

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
  double? _latitude;
  double? _longitude;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user.nom);
    _prenomController = TextEditingController(text: widget.user.prenom);
    _telephoneController = TextEditingController(text: widget.user.telephone);
    _adresseController = TextEditingController(text: widget.user.adresse ?? '');
    _latitude = widget.user.latitude;
    _longitude = widget.user.longitude;
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
    const themeColor = Colors.black;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header section with Avatar
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 40, top: 20),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.grey[900],
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (_imageUrl != null
                                              ? NetworkImage(_imageUrl!)
                                              : null)
                                          as ImageProvider?,
                                child: (_imageFile == null && _imageUrl == null)
                                    ? Text(
                                        widget.user.prenom.isNotEmpty
                                            ? widget.user.prenom[0]
                                                  .toUpperCase()
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
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (_imageFile != null || _imageUrl != null)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _imageFile = null;
                                    _imageUrl = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Upload Profile Photo',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Basic Information'),
                          _buildInputGroup([
                            _buildTextField(
                              controller: _prenomController,
                              label: 'First Name',
                              icon: Icons.person_outline_rounded,
                            ),
                            _buildTextField(
                              controller: _nomController,
                              label: 'Last Name',
                              icon: Icons.person_outline_rounded,
                            ),
                            _buildTextField(
                              controller: _telephoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ]),
                          const SizedBox(height: 32),

                          if (widget.user.role != Role.gerant) ...[
                            _buildSectionTitle('Location'),
                            _buildInputGroup([_buildAddressField(themeColor)]),
                            const SizedBox(height: 32),
                          ],

                          _buildSectionTitle('Security'),
                          _buildInputGroup([
                            _buildTextField(
                              controller: _oldPasswordController,
                              label: 'Old Password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              obscureText: _obscureOldPassword,
                              onToggleVisibility: () => setState(
                                () =>
                                    _obscureOldPassword = !_obscureOldPassword,
                              ),
                              helperText: 'Required to change password',
                            ),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'New Password',
                              icon: Icons.lock_reset_rounded,
                              isPassword: true,
                              obscureText: _obscureNewPassword,
                              onToggleVisibility: () => setState(
                                () =>
                                    _obscureNewPassword = !_obscureNewPassword,
                              ),
                              helperText: 'Optional',
                            ),
                          ]),
                          const SizedBox(height: 48),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Save Profile Changes',
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
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
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
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText ?? false,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          helperText: helperText,
          helperStyle: const TextStyle(fontSize: 10),
          prefixIcon: Icon(icon, color: Colors.black87, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (obscureText ?? false)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (!isPassword && (value == null || value.isEmpty)) {
            return 'Field required';
          }
          if (controller == _oldPasswordController &&
              _passwordController.text.isNotEmpty &&
              (value == null || value.isEmpty)) {
            return 'Required for password change';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAddressField(Color themeColor) {
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
                  Icons.location_on_outlined,
                  color: Colors.black87,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              maxLines: 1,
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

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        String? newImageUrl = _imageUrl;
        final imageService = ImageKitService();

        if (_imageFile != null) {
          if (widget.user.imageUrl != null) {
            await imageService.deleteImage(widget.user.imageUrl!);
          }
          final fileName =
              'user_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final imageUrl = await imageService.uploadImage(
            _imageFile!,
            fileName,
            folder: 'bestmlewi/profiles',
          );
          newImageUrl = imageUrl;
        } else if (_imageUrl == null && widget.user.imageUrl != null) {
          await imageService.deleteImage(widget.user.imageUrl!);
          newImageUrl = null;
        }

        final Map<String, dynamic> result = {
          'nom': _nomController.text,
          'prenom': _prenomController.text,
          'telephone': _telephoneController.text,
          'password': _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          'oldPassword': _oldPasswordController.text.isNotEmpty
              ? _oldPasswordController.text
              : null,
          'imageUrl': newImageUrl,
        };

        if (widget.user.role != Role.gerant) {
          result['adresse'] = _adresseController.text.isNotEmpty
              ? _adresseController.text
              : null;
          result['latitude'] = _latitude;
          result['longitude'] = _longitude;
        }

        if (mounted) Navigator.pop(context, result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
