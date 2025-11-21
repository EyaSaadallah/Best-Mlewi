import 'package:flutter/material.dart';
import '../models/point_de_vente.dart';
import '../repositories/point_de_vente_repository.dart';
import 'pos_edit_screen.dart';

class PosManagementScreen extends StatefulWidget {
  const PosManagementScreen({super.key});

  @override
  State<PosManagementScreen> createState() => _PosManagementScreenState();
}

class _PosManagementScreenState extends State<PosManagementScreen> {
  final _repository = PointDeVenteRepository();
  late Future<List<PointDeVente>> _futurePos;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _futurePos = _repository.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sales Points'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PosEditScreen()),
          );
          _refreshList();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<PointDeVente>>(
        future: _futurePos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_mall_directory, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No sales points found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PosEditScreen()),
                      );
                      _refreshList();
                    },
                    child: const Text('Add First Sales Point'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final pos = list[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: pos.actif ? Colors.green : Colors.grey,
                    child: Icon(
                      Icons.store,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(pos.nom),
                  subtitle: Text(pos.adresse),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PosEditScreen(pos: pos),
                      ),
                    );
                    _refreshList();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
