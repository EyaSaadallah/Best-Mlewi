import 'package:flutter/material.dart';
import '../models/plat.dart';

class PlatEditScreen extends StatefulWidget {
  final Plat? plat;

  const PlatEditScreen({super.key, this.plat});

  @override
  State<PlatEditScreen> createState() => _PlatEditScreenState();
}

class _PlatEditScreenState extends State<PlatEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _prixController;
  late TextEditingController _categorieController;
  bool _disponible = true;

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
    _disponible = widget.plat?.disponible ?? true;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _categorieController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final prix = double.tryParse(_prixController.text) ?? 0.0;

    final plat = Plat(
      id: widget.plat?.id ?? DateTime.now().millisecondsSinceEpoch,
      nom: _nomController.text,
      description: _descriptionController.text,
      prix: prix,
      categorie: _categorieController.text,
      disponible: _disponible,
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
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Dish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
