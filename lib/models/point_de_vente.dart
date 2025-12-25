import 'collaborateur.dart';
import 'menu.dart';

/// Sales point/Restaurant location model
class PointDeVente {
  final int id;
  final String nom;
  final String adresse;
  final double? latitude;
  final double? longitude;
  final String openingTime; // Format: HH:mm
  final String closingTime; // Format: HH:mm
  final bool actif;
  final List<Collaborateur> collaborateurs;
  final Menu? menu;
  final int? coordinateurId;
  final List<int> collaborateurIds;

  PointDeVente({
    required this.id,
    required this.nom,
    required this.adresse,
    this.latitude,
    this.longitude,
    required this.openingTime,
    required this.closingTime,
    required this.actif,
    required this.collaborateurs,
    this.menu,
    this.coordinateurId,
    this.collaborateurIds = const [],
  });

  /// Check if the POS is currently open based on current time
  bool get isOpenNow {
    if (!actif) return false;

    try {
      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;

      final openParts = openingTime.split(':');
      final closeParts = closingTime.split(':');

      if (openParts.length != 2 || closeParts.length != 2) return false;

      final openMinutes =
          int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeMinutes =
          int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

      if (closeMinutes > openMinutes) {
        // Standard range (e.g., 08:00 to 22:00)
        return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
      } else {
        // Overnight range (e.g., 20:00 to 02:00)
        return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
      }
    } catch (e) {
      return false;
    }
  }

  /// Activate point of sale
  void activer() {
    // Implementation for activation
  }

  /// Deactivate point of sale
  void desactiver() {
    // Implementation for deactivation
  }

  @override
  String toString() =>
      'PointDeVente(id: $id, nom: $nom, adresse: $adresse, actif: $actif, coordinateurId: $coordinateurId)';
}
