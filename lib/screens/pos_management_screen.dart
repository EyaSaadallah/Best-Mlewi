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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manage Sales Points',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PosEditScreen()),
          );
          _refreshList();
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: FutureBuilder<List<PointDeVente>>(
        future: _futurePos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Sales Points Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Start by adding your first point of sale to manage availability and staff.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PosEditScreen(),
                            ),
                          );
                          _refreshList();
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Add First Sales Point'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: list.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final pos = list[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PosEditScreen(pos: pos),
                        ),
                      );
                      _refreshList();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: pos.isOpenNow
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.store_rounded,
                              color: pos.isOpenNow ? Colors.green : Colors.red,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pos.nom,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    _buildStatusBadge(pos.isOpenNow),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  pos.adresse,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${pos.openingTime} - ${pos.closingTime}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey[300],
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green[500] : Colors.red[500],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? Colors.green : Colors.red).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
