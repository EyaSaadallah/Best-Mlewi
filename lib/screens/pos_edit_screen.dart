import 'package:flutter/material.dart';
import '../models/point_de_vente.dart';
import '../repositories/point_de_vente_repository.dart';

class PosEditScreen extends StatefulWidget {
  final PointDeVente? pos;

  const PosEditScreen({super.key, this.pos});

  @override
  State<PosEditScreen> createState() => _PosEditScreenState();
}

class _PosEditScreenState extends State<PosEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = PointDeVenteRepository();
  
  late TextEditingController _nomController;
  late TextEditingController _adresseController;
  late TextEditingController _horairesController;
  bool _actif = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.pos?.nom ?? '');
    _adresseController = TextEditingController(text: widget.pos?.adresse ?? '');
    _horairesController = TextEditingController(text: widget.pos?.horaires ?? '');
    _actif = widget.pos?.actif ?? true;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _horairesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final pos = PointDeVente(
      id: widget.pos?.id ?? DateTime.now().millisecondsSinceEpoch,
      nom: _nomController.text,
      adresse: _adresseController.text,
      horaires: _horairesController.text,
      actif: _actif,
      collaborateurs: widget.pos?.collaborateurs ?? [],
      menu: widget.pos?.menu,
    );

    try {
      if (widget.pos == null) {
        await _repository.create(pos);
      } else {
        await _repository.updateByIntId(pos.id, pos);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sales point saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sales point deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
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
      appBar: AppBar(
        title: Text(widget.pos == null ? 'New Sales Point' : 'Edit Sales Point'),
        actions: [
          if (widget.pos != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      controller: _adresseController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _horairesController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Hours',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Mon-Sun 09:00-22:00',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter opening hours';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: _actif,
                      onChanged: (value) => setState(() => _actif = value),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
