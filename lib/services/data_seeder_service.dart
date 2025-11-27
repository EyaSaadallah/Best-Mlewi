import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DataSeederService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  Future<void> seedDashboardData() async {
    try {
      debugPrint('Starting data seeding...');
      final batch = _firestore.batch();
      final now = DateTime.now();

      // 1. Create orders for "This Week" (Mon-Sun) to populate Line Chart
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        if (day.isAfter(now)) break;

        // Add 3-8 orders per day
        final ordersCount = 3 + _random.nextInt(6);

        for (int j = 0; j < ordersCount; j++) {
          final orderRef = _firestore.collection('commandes').doc();
          final orderDate = day.add(
            Duration(
              hours: 9 + _random.nextInt(12),
              minutes: _random.nextInt(60),
            ),
          );

          batch.set(orderRef, {
            'dateCommande': Timestamp.fromDate(orderDate),
            'statut': _getRandomStatus(),
            'total': 15.0 + _random.nextInt(85),
            'userId': 'seeded_user_${_random.nextInt(10)}',
            'items': [],
          });
        }
      }

      // 2. Create orders for "Today" to populate Pie Chart
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayStatuses = [
        'delivered',
        'pending',
        'pending',
        'in_transit',
        'delivered',
        'cancelled',
        'delivered',
        'in_transit',
        'pending',
        'delivered',
      ];

      for (var status in todayStatuses) {
        final orderRef = _firestore.collection('commandes').doc();
        final orderDate = todayStart.add(
          Duration(
            hours: 8 + _random.nextInt(12),
            minutes: _random.nextInt(60),
          ),
        );

        batch.set(orderRef, {
          'dateCommande': Timestamp.fromDate(orderDate),
          'statut': status,
          'total': 20.0 + _random.nextInt(50),
          'userId': 'seeded_user_${_random.nextInt(10)}',
          'items': [],
        });
      }

      // 3. Create past orders
      for (int i = 0; i < 50; i++) {
        final orderRef = _firestore.collection('commandes').doc();
        final pastDate = now.subtract(Duration(days: 10 + _random.nextInt(30)));

        batch.set(orderRef, {
          'dateCommande': Timestamp.fromDate(pastDate),
          'statut': 'delivered',
          'total': 15.0 + _random.nextInt(85),
          'userId': 'seeded_user_${_random.nextInt(10)}',
          'items': [],
        });
      }

      await batch.commit();
      debugPrint('Dashboard data seeding completed successfully!');
    } catch (e) {
      debugPrint('Error seeding dashboard data: $e');
      rethrow;
    }
  }

  Future<void> seedMenus() async {
    try {
      debugPrint('Starting menu seeding...');
      final batch = _firestore.batch();

      // 1. Delete existing menus to ensure clean state
      final existingMenus = await _firestore.collection('menus').get();
      for (var doc in existingMenus.docs) {
        batch.delete(doc.reference);
      }

      // 2. Create new menus with high-quality data

      // Menu 1: Mlewi & Sandwiches
      final menu1Ref = _firestore.collection('menus').doc();
      batch.set(menu1Ref, {
        'id': 1,
        'titre': 'Mlewi & Sandwiches',
        'plats': [
          {
            'id': 101,
            'nom': 'Mlewi Jambon Fromage',
            'description':
                'Traditional Tunisian flatbread with premium ham and melting cheese',
            'prix': 4.5,
            'categorie': 'Mlewi',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1585238342024-78d387f4a707?q=80&w=800&auto=format&fit=crop',
          },
          {
            'id': 102,
            'nom': 'Mlewi Thon',
            'description': 'Mlewi with tuna, harissa, olives, and salad',
            'prix': 5.0,
            'categorie': 'Mlewi',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?q=80&w=800&auto=format&fit=crop',
          },
          {
            'id': 103,
            'nom': 'Sandwich Escalope',
            'description':
                'Fresh baguette with breaded chicken breast and fries',
            'prix': 8.5,
            'categorie': 'Sandwich',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1627308595229-7830a5c91f9f?q=80&w=800&auto=format&fit=crop',
          },
          {
            'id': 104,
            'nom': 'Makloub Chawarma',
            'description': 'Folded pizza dough sandwich with spicy shawarma',
            'prix': 9.0,
            'categorie': 'Makloub',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1637949385162-e416fb15b2ce?q=80&w=800&auto=format&fit=crop',
          },
        ],
      });

      // Menu 2: Plates & Sides
      final menu2Ref = _firestore.collection('menus').doc();
      batch.set(menu2Ref, {
        'id': 2,
        'titre': 'Plates & Sides',
        'plats': [
          {
            'id': 201,
            'nom': 'Assiette Escalope',
            'description':
                'Grilled chicken breast plate served with fries and fresh salad',
            'prix': 14.0,
            'categorie': 'Plates',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800&auto=format&fit=crop',
          },
          {
            'id': 202,
            'nom': 'Crispy Fries',
            'description': 'Golden crispy french fries',
            'prix': 3.5,
            'categorie': 'Sides',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1573080496987-8198cb7fcd02?q=80&w=800&auto=format&fit=crop',
          },
          {
            'id': 203,
            'nom': 'Tunisian Salad',
            'description': 'Fresh salad with cucumber, tomato, onion, and tuna',
            'prix': 6.0,
            'categorie': 'Salads',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?q=80&w=800&auto=format&fit=crop',
          },
        ],
      });

      // Menu 3: Drinks
      final menu3Ref = _firestore.collection('menus').doc();
      batch.set(menu3Ref, {
        'id': 3,
        'titre': 'Drinks',
        'plats': [
          {
            'id': 301,
            'nom': 'Coca Cola',
            'description': '33cl can',
            'prix': 2.5,
            'categorie': 'Drinks',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?q=80&w=800&auto=format&fit=crop',
          },
          {
            'id': 302,
            'nom': 'Mineral Water',
            'description': '0.5L bottle',
            'prix': 1.5,
            'categorie': 'Drinks',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1560697529-7236591c0066?q=80&w=800&auto=format&fit=crop',
          },
          {
            'id': 303,
            'nom': 'Mint Tea',
            'description': 'Traditional Tunisian mint tea with pine nuts',
            'prix': 3.0,
            'categorie': 'Drinks',
            'disponible': true,
            'imageUrl':
                'https://images.unsplash.com/photo-1576092768241-dec231847233?q=80&w=800&auto=format&fit=crop',
          },
        ],
      });

      await batch.commit();
      debugPrint('Menu seeding completed successfully!');
    } catch (e) {
      debugPrint('Error seeding menus: $e');
      rethrow;
    }
  }

  String _getRandomStatus() {
    final statuses = ['pending', 'in_transit', 'delivered', 'cancelled'];
    final weights = [30, 20, 40, 10]; // Probabilities

    int totalWeight = weights.reduce((a, b) => a + b);
    int randomNum = _random.nextInt(totalWeight);

    int currentWeight = 0;
    for (int i = 0; i < statuses.length; i++) {
      currentWeight += weights[i];
      if (randomNum < currentWeight) {
        return statuses[i];
      }
    }
    return 'pending';
  }
}
