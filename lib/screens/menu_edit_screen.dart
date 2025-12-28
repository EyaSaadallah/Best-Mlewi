import 'package:flutter/material.dart';
import '../models/menu.dart';
import '../models/plat.dart';
import '../repositories/menu_repository.dart';
import '../services/imagekit_service.dart';
import 'plat_edit_screen.dart';

class MenuEditScreen extends StatefulWidget {
  final Menu? menu;

  const MenuEditScreen({super.key, this.menu});

  @override
  State<MenuEditScreen> createState() => _MenuEditScreenState();
}

class _MenuEditScreenState extends State<MenuEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = MenuRepository();

  late TextEditingController _titreController;
  late List<Plat> _plats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.menu?.titre ?? '');
    _plats = List.from(widget.menu?.plats ?? []);
  }

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final menu = Menu(
      id: widget.menu?.id ?? DateTime.now().millisecondsSinceEpoch,
      titre: _titreController.text,
      plats: _plats,
    );

    try {
      if (widget.menu == null) {
        await _repository.create(menu);
      } else {
        await _repository.updateByIntId(menu.id, menu);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category saved successfully')),
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

  Future<void> _delete() async {
    if (widget.menu == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${widget.menu!.titre}?'),
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
        await _repository.deleteByIntId(widget.menu!.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Category deleted')));
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

  Future<void> _addPlat() async {
    final result = await Navigator.push<Plat>(
      context,
      MaterialPageRoute(builder: (context) => const PlatEditScreen()),
    );

    if (result != null) {
      setState(() {
        _plats.add(result);
      });
    }
  }

  Future<void> _editPlat(Plat plat) async {
    final result = await Navigator.push<Plat>(
      context,
      MaterialPageRoute(builder: (context) => PlatEditScreen(plat: plat)),
    );

    if (result != null) {
      setState(() {
        final index = _plats.indexOf(plat);
        if (index != -1) {
          _plats[index] = result;
        }
      });
    }
  }

  Future<void> _deletePlat(Plat plat) async {
    // Delete image from ImageKit if it exists
    if (plat.imageUrl.isNotEmpty) {
      try {
        final imageKitService = ImageKitService();
        await imageKitService.deleteImage(plat.imageUrl);
      } catch (e) {
        // Log error but continue with dish deletion
        debugPrint('Error deleting image from ImageKit: $e');
      }
    }

    setState(() {
      _plats.remove(plat);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dish deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.menu == null ? 'New Category' : 'Edit Category',
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
          if (widget.menu != null)
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
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            'General Info',
                            Icons.info_outline_rounded,
                          ),
                          _buildInputGroup([
                            _buildTextField(
                              controller: _titreController,
                              label: 'Category Name (e.g. Pizza)',
                              icon: Icons.label_important_outline_rounded,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ]),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle(
                                'Dishes (${_plats.length})',
                                Icons.restaurant_rounded,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextButton.icon(
                                  onPressed: _addPlat,
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 20,
                                  ),
                                  label: const Text('Add Dish'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildDishList(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
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
                          'Save Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
      child: Column(children: children),
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

  Widget _buildDishList() {
    if (_plats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 48,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Text(
              'No dishes in this category',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _plats.asMap().entries.map((entry) {
        final idx = entry.key;
        final plat = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[100],
                    child: plat.imageUrl.isNotEmpty
                        ? Image.network(plat.imageUrl, fit: BoxFit.cover)
                        : Icon(Icons.fastfood_rounded, color: Colors.grey[300]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plat.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plat.prix.toStringAsFixed(2)} \$',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildAvailabilityTag(plat.disponible),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch(
                      value: plat.disponible,
                      activeColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          _plats[idx] = Plat(
                            id: plat.id,
                            nom: plat.nom,
                            description: plat.description,
                            prix: plat.prix,
                            categorie: plat.categorie,
                            disponible: val,
                            imageUrl: plat.imageUrl,
                          );
                        });
                      },
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editPlat(plat),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _deletePlat(plat),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvailabilityTag(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'AVAILABLE' : 'OUT OF STOCK',
        style: TextStyle(
          color: isOpen ? Colors.green[700] : Colors.red[700],
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
