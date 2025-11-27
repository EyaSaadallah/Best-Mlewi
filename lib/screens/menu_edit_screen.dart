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
      appBar: AppBar(
        title: Text(widget.menu == null ? 'New Category' : 'Edit Category'),
        actions: [
          if (widget.menu != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titreController,
                          decoration: const InputDecoration(
                            labelText: 'Category Name (e.g. Pizza)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a category name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text('Save Category'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dishes (${_plats.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: Theme.of(context).primaryColor,
                        onPressed: _addPlat,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _plats.length,
                    itemBuilder: (context, index) {
                      final plat = _plats[index];
                      return ListTile(
                        title: Text(plat.nom),
                        subtitle: Text('${plat.prix.toStringAsFixed(2)} \$'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: plat.disponible,
                              onChanged: (val) {
                                setState(() {
                                  // Create new plat with updated availability
                                  _plats[index] = Plat(
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
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editPlat(plat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _deletePlat(plat),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
