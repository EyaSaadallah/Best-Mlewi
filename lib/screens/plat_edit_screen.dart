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
      appBar: AppBar(
        title: Text(widget.plat == null ? 'New Dish' : 'Edit Dish'),
      ),
      body: SingleChildScrollView(
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categorieController,
                decoration: const InputDecoration(
                  labelText: 'Category Tag',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Spicy, Vegetarian',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                value: _disponible,
                onChanged: (value) => setState(() => _disponible = value),
              ),
              const SizedBox(height: 24),
              // Image upload section
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else if (_imageUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrlController.text,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton.icon(
                        onPressed: _isUploadingImage ? null : _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Select Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploadingImage ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploadingImage
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading...'),
                        ],
                      )
                    : const Text('Save Dish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
