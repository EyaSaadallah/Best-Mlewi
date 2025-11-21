/// Example usage of the BestMiawi system
/// This file demonstrates how to use the models and services
library usage_example;

import '../models/index.dart';
import '../services/index.dart';

/// Example: Creating and managing users
void exampleUserCreation() {
  // Create a client
  Client(
    id: 1,
    nom: 'Dupont',
    prenom: 'Jean',
    email: 'jean.dupont@email.com',
    motDePasse: 'password123',
    telephone: '+33612345678',
    dateInscription: DateTime.now(),
  );

  // Create a gerant (manager)
  Gerant(
    id: 2,
    nom: 'Martin',
    prenom: 'Pierre',
    email: 'pierre.martin@email.com',
    motDePasse: 'password456',
    telephone: '+33687654321',
    dateInscription: DateTime.now(),
  );

  // Create a delivery person
  Livreur(
    id: 3,
    nom: 'Bernard',
    prenom: 'Marc',
    email: 'marc.bernard@email.com',
    motDePasse: 'password789',
    telephone: '+33698765432',
    dateInscription: DateTime.now(),
  );

  // Client, Gerant, and Livreur created
}

/// Example: Creating menu and dishes
void exampleMenuCreation() {
  // Create dishes
  final pizza = Plat(
    id: 1,
    nom: 'Pizza Margherita',
    description: 'Classic pizza with tomato and mozzarella',
    prix: 12.99,
    categorie: 'Pizza',
    disponible: true,
  );

  final burger = Plat(
    id: 2,
    nom: 'Burger Classique',
    description: 'Beef burger with cheese and vegetables',
    prix: 9.99,
    categorie: 'Burger',
    disponible: true,
  );

  final salad = Plat(
    id: 3,
    nom: 'Salade César',
    description: 'Fresh caesar salad with croutons',
    prix: 8.99,
    categorie: 'Salad',
    disponible: false,
  );

  // Create menu
  final menu = Menu(
    id: 1,
    titre: 'Menu Principal',
    plats: [pizza, burger, salad],
  );

  // Get available dishes
  menu.getPlatDisponibles();
  // Menu created with ${menu.plats.length} dishes
}

/// Example: Creating and managing orders
void exampleOrderManagement() {
  final commandeService = CommandeService();

  // Create line items
  final ligne1 = LigneCommande(
    id: 1,
    quantite: 2,
    prixUnitaire: 12.99,
    sousTotal: 25.98,
    plat: Plat(
      id: 1,
      nom: 'Pizza Margherita',
      description: 'Classic pizza',
      prix: 12.99,
      categorie: 'Pizza',
      disponible: true,
    ),
  );

  final ligne2 = LigneCommande(
    id: 2,
    quantite: 1,
    prixUnitaire: 9.99,
    sousTotal: 9.99,
    plat: Plat(
      id: 2,
      nom: 'Burger Classique',
      description: 'Beef burger',
      prix: 9.99,
      categorie: 'Burger',
      disponible: true,
    ),
  );

  // Ligne commande created: Qty ${ligne1.quantite}

  // Create delivery
  final livraison = Livraison(
    id: 1,
    adresseLivraison: '123 Rue de Paris, 75001 Paris',
    dateHeureEstimee: DateTime.now().add(const Duration(hours: 1)),
    notes: 'Sonner à la porte',
  );

  // Livraison created: ${livraison.adresseLivraison}

  // Create order
  final commande = Commande(
    id: 1,
    dateCreation: DateTime.now(),
    total: 35.97,
    statut: StatusCommande.cree,
    lignes: [ligne1, ligne2],
    livraison: livraison,
  );

  // Add to service
  commandeService.createCommande(commande);

  // Update status
  commandeService.updateCommandeStatus(1, StatusCommande.enPreparation);

  // Get orders by status
  commandeService.getCommandesByStatus(StatusCommande.enPreparation);

  // Orders being prepared
}

/// Example: Managing notifications
void exampleNotificationManagement() {
  final notificationService = NotificationService();

  // Create notifications
  notificationService.createNotification(
    1,
    'Your order has been confirmed',
    NotificationType.success,
  );

  // Notification created: Your order has been confirmed

  notificationService.createNotification(
    2,
    'Your order is being prepared',
    NotificationType.info,
  );

  notificationService.createNotification(
    3,
    'Delivery delayed by 15 minutes',
    NotificationType.warning,
  );

  // Get unread notifications
  notificationService.getUnreadNotifications();
  // Unread notifications retrieved

  // Mark as read
  notificationService.markAsRead(1);

  // Get all notifications
  notificationService.getNotifications();
  // All notifications retrieved
}

/// Example: Managing sales points
void exampleSalesPointManagement() {
  // Create collaborators
  final collaborateur1 = Collaborateur(
    id: 1,
    nom: 'Durand',
    prenom: 'Sophie',
    email: 'sophie.durand@email.com',
    motDePasse: 'password123',
    telephone: '+33612345678',
    dateInscription: DateTime.now(),
  );

  final collaborateur2 = Collaborateur(
    id: 2,
    nom: 'Leclerc',
    prenom: 'Anne',
    email: 'anne.leclerc@email.com',
    motDePasse: 'password456',
    telephone: '+33687654321',
    dateInscription: DateTime.now(),
  );

  // Collaborateur created: ${collaborateur1.prenom} ${collaborateur1.nom}

  // Create menu
  final menu = Menu(id: 1, titre: 'Menu Principal', plats: []);

  // Create sales point
  PointDeVente(
    id: 1,
    nom: 'Restaurant Paris Centre',
    adresse: '123 Rue de Rivoli, 75001 Paris',
    horaires: '11:00 - 23:00',
    actif: true,
    collaborateurs: [collaborateur1, collaborateur2],
    menu: menu,
  );

  // Point de vente created
}

/// Example: Managing availability
void exampleAvailabilityManagement() {
  final disponibilite = Disponibilite(
    id: 1,
    titre: 'Morning Shift',
    dateDebut: DateTime.now(),
    dateFin: DateTime.now().add(const Duration(hours: 8)),
    actif: true,
  );

  // Disponibilite created: ${disponibilite.titre}

  // Activate/Deactivate
  disponibilite.activer();
  disponibilite.desactiver();
}

/// Run all examples
void runAllExamples() {
  print('=== BestMiawi System Examples ===\n');

  print('--- User Creation ---');
  exampleUserCreation();
  print('\n');

  print('--- Menu Creation ---');
  exampleMenuCreation();
  print('\n');

  print('--- Order Management ---');
  exampleOrderManagement();
  print('\n');

  print('--- Notification Management ---');
  exampleNotificationManagement();
  print('\n');

  print('--- Sales Point Management ---');
  exampleSalesPointManagement();
  print('\n');

  print('--- Availability Management ---');
  exampleAvailabilityManagement();
  print('\n');

  print('=== Examples Complete ===');
}
