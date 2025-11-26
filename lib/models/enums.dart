/// Enum for user roles in the BestMiawi system
enum Role { client, gerant, coordinateur, livreur, collaborateur, visiteur }

/// Enum for command status
enum StatusCommande {
  created,
  preparing,
  ready,
  delivering,
  delivered,
  cancelled,
}

/// Enum for notification types
enum NotificationType { info, warning, error, success }
