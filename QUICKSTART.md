# BestMiawi Quick Start Guide

## Installation & Setup

### Prerequisites
- Flutter SDK installed
- Dart SDK (comes with Flutter)
- IDE (VS Code, Android Studio, or IntelliJ)

### Getting Started

1. **Navigate to project directory**
   ```bash
   cd d:\devFlutter\Flutter_apps\bestmlewi2
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## First Run

### Login Screen
- Email: `any@email.com` (accepts any email for demo)
- Password: `any_password` (accepts any password for demo)
- Click "Login" to proceed

### Home Screen
After login, you'll see a role-based dashboard. The demo creates a **Client** user by default.

**Client Dashboard includes:**
- Browse Menu
- My Orders
- Order History

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Domain entities
├── services/                 # Business logic
├── screens/                  # UI screens
└── examples/                 # Usage examples
```

## Key Components

### Models (`lib/models/`)
Domain entities representing the business logic:
- Users: `Client`, `Gerant`, `Coordinateur`, `Livreur`, `Collaborateur`, `Visiteur`
- Orders: `Commande`, `LigneCommande`, `Livraison`
- Menu: `Menu`, `Plat`
- System: `Notification`, `PointDeVente`, `Disponibilite`

### Services (`lib/services/`)
Singleton services managing business logic:
- `AuthService` - Authentication
- `CommandeService` - Order management
- `MenuService` - Menu management
- `NotificationService` - Notifications

### Screens (`lib/screens/`)
Flutter UI components:
- `LoginScreen` - User authentication
- `HomeScreen` - Role-based dashboard

## Using the Services

### Authentication
```dart
import 'services/auth_service.dart';

final authService = AuthService();
await authService.login('email@example.com', 'password');

if (authService.isAuthenticated()) {
  print('User logged in: ${authService.currentUser?.prenom}');
}

authService.logout();
```

### Order Management
```dart
import 'services/commande_service.dart';
import 'models/index.dart';

final commandeService = CommandeService();

// Create order
commandeService.createCommande(commande);

// Get orders
final orders = commandeService.getCommandes();

// Update status
commandeService.updateCommandeStatus(1, StatusCommande.enPreparation);

// Filter by status
final preparing = commandeService.getCommandesByStatus(
  StatusCommande.enPreparation
);
```

### Menu Management
```dart
import 'services/menu_service.dart';

final menuService = MenuService();

// Create menu
menuService.createMenu(menu);

// Get available dishes
final dishes = menuService.getAvailableDishes(menuId);

// Add dish
menuService.addDishToMenu(menuId, plat);
```

### Notifications
```dart
import 'services/notification_service.dart';

final notificationService = NotificationService();

// Create notification
notificationService.createNotification(
  1,
  'Order confirmed',
  NotificationType.success,
);

// Get unread
final unread = notificationService.getUnreadNotifications();

// Mark as read
notificationService.markAsRead(1);
```

## User Roles

| Role | Capabilities |
|------|--------------|
| **Client** | Browse menu, place orders, check status, cancel |
| **Gerant** | Manage commands, staff, sales points |
| **Coordinateur** | Track preparation |
| **Livreur** | Track deliveries, update location |
| **Collaborateur** | Manage availability |
| **Visiteur** | Browse menu (read-only) |

## Common Tasks

### Create a New User
```dart
import 'models/index.dart';

final client = Client(
  id: 1,
  nom: 'Dupont',
  prenom: 'Jean',
  email: 'jean@example.com',
  motDePasse: 'password123',
  telephone: '+33612345678',
  dateInscription: DateTime.now(),
);
```

### Create an Order
```dart
final commande = Commande(
  id: 1,
  dateCreation: DateTime.now(),
  total: 35.97,
  statut: StatusCommande.cree,
  lignes: [ligne1, ligne2],
  livraison: livraison,
);
```

### Create a Menu
```dart
final menu = Menu(
  id: 1,
  titre: 'Menu Principal',
  plats: [pizza, burger, salad],
);
```

## Debugging

### Enable Debug Logging
Add to `main.dart`:
```dart
void main() {
  // Enable debug mode
  debugPrintBeginFrameBanner = true;
  runApp(const MyApp());
}
```

### Check Current User
```dart
final authService = AuthService();
print('Current user: ${authService.currentUser}');
print('Is authenticated: ${authService.isAuthenticated()}');
```

## Hot Reload
Press `r` in the terminal to hot reload the app during development.

## Hot Restart
Press `R` in the terminal to restart the app (use when state needs to reset).

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Troubleshooting

### App won't start
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`

### Login not working
- Check that email and password fields are not empty
- Currently accepts any credentials for demo purposes

### Lint errors
Run `flutter analyze` to check for issues:
```bash
flutter analyze
```

## Next Steps

1. **Explore the code** - Check `lib/examples/usage_example.dart` for usage patterns
2. **Read documentation** - See `ARCHITECTURE.md` for detailed architecture
3. **Modify screens** - Customize `lib/screens/` for your needs
4. **Add features** - Extend services and models as needed
5. **Connect backend** - Replace mock data with API calls

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design](https://material.io/design)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)

## Support

For issues or questions:
1. Check the `ARCHITECTURE.md` file
2. Review `lib/examples/usage_example.dart`
3. Check Flutter documentation
4. Review the code comments

---

**Happy coding! 🚀**
