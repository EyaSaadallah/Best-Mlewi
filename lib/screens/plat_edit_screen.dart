import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/plat.dart';
import '../services/imagekit_service.dart';

class PlatEditScreen extends StatefulWidget {
  final Plat? plat;

  const PlatEditScreen({super.key, this.plat});

  @override
  State<PlatEditScreen> createState() => _PlatEditScreenState();
}

class _PlatEditScreenState extends State<PlatEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _imageKitService = ImageKitService();

  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _prixController;
  late TextEditingController _categorieController;
  late TextEditingController _imageUrlController;
  bool _disponible = true;
  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.plat?.nom ?? '');
    _descriptionController = TextEditingController(
      text: widget.plat?.description ?? '',
    );
    _prixController = TextEditingController(
      text: widget.plat?.prix.toString() ?? '',
    );
    _categorieController = TextEditingController(
      text: widget.plat?.categorie ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.plat?.imageUrl ?? '',
    );
    _disponible = widget.plat?.disponible ?? true;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _categorieController.dispose();
    _imageUrlController.dispose();
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
          _selectedImage = File(pickedFile.path);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if image is selected (either new or existing)
    if (_selectedImage == null && _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image for the dish')),
      );
      return;
    }

    // Upload image if a new one was selected
    if (_selectedImage != null) {
      setState(() => _isUploadingImage = true);

      try {
        // Delete old image if we're editing and replacing the image
        if (widget.plat != null && widget.plat!.imageUrl.isNotEmpty) {
          try {
            await _imageKitService.deleteImage(widget.plat!.imageUrl);
          } catch (deleteError) {
            debugPrint('Error deleting old image: $deleteError');
            // Continue with upload even if delete fails
          }
        }

        final fileName = 'dish_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageUrl = await _imageKitService.uploadImage(
          _selectedImage!,
          fileName,
          folder: 'bestmlewi/dishes',
        );

        setState(() {
          _imageUrlController.text = imageUrl;
          _isUploadingImage = false;
        });
      } catch (uploadError) {
        setState(() => _isUploadingImage = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading image: $uploadError'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // Don't save if upload failed
      }
    }

    final prix = double.tryParse(_prixController.text) ?? 0.0;

    final plat = Plat(
      id: widget.plat?.id ?? DateTime.now().millisecondsSinceEpoch,
      nom: _nomController.text,
      description: _descriptionController.text,
      prix: prix,
      categorie: _categorieController.text,
      disponible: _disponible,
      imageUrl: _imageUrlController.text,
    );

    Navigator.pop(context, plat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.plat == null ? 'New Dish' : 'Edit Dish',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isUploadingImage
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
                      'Dish Presentation',
                      Icons.photo_library_outlined,
                    ),
                    _buildImageSection(),
                    const SizedBox(height: 32),

                    _buildSectionTitle(
                      'Basic Details',
                      Icons.info_outline_rounded,
                    ),
                    _buildInputGroup([
                      _buildTextField(
                        controller: _nomController,
                        label: 'Dish Name',
                        icon: Icons.restaurant_rounded,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _prixController,
                              label: 'Price',
                              icon: Icons.attach_money_rounded,
                              isNumber: true,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (double.tryParse(value!) == null)
                                  return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey[100],
                          ),
                          Expanded(
                            child: _buildTextField(
                              controller: _categorieController,
                              label: 'Category Tag',
                              icon: Icons.label_outline_rounded,
                              hint: 'e.g. Spicy',
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionTitle(
                      'Status',
                      Icons.check_circle_outline_rounded,
                    ),
                    _buildInputGroup([
                      _buildSwitch(
                        label: 'Availability',
                        subtitle: 'Customers can see and order this dish',
                        value: _disponible,
                        onChanged: (v) => setState(() => _disponible = v),
                      ),
                    ]),
                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploadingImage ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.plat == null
                              ? 'Add Dish to Menu'
                              : 'Save Changes',
                          style: const TextStyle(
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
    int maxLines = 1,
    bool isNumber = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : _imageUrlController.text.isNotEmpty
                ? Image.network(
                    _imageUrlController.text,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
          InkWell(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.02),
                border: Border(top: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_rounded,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _imageUrlController.text.isEmpty && _selectedImage == null
                        ? 'Upload Dish Photo'
                        : 'Change Photo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_rounded, size: 48, color: Colors.grey[200]),
          const SizedBox(height: 12),
          Text(
            'No Image Selected',
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
