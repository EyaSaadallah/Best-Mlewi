import '../models/commande.dart';
import '../models/enums.dart';

/// Service for managing commands/orders
class CommandeService {
  static final CommandeService _instance = CommandeService._internal();

  factory CommandeService() {
    return _instance;
  }

  CommandeService._internal();

  final List<Commande> _commandes = [];

  /// Get all commands
  List<Commande> getCommandes() {
    return _commandes;
  }

  /// Get command by ID
  Commande? getCommandeById(int id) {
    try {
      return _commandes.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Create new command
  void createCommande(Commande commande) {
    _commandes.add(commande);
  }

  /// Update command status
  void updateCommandeStatus(int id, StatusCommande newStatus) {
    final commande = getCommandeById(id);
    if (commande != null) {
      commande.changerStatut(newStatus);
    }
  }

  /// Delete command
  void deleteCommande(int id) {
    _commandes.removeWhere((c) => c.id == id);
  }

  /// Get commands by status
  List<Commande> getCommandesByStatus(StatusCommande status) {
    return _commandes.where((c) => c.statut == status).toList();
  }
}
