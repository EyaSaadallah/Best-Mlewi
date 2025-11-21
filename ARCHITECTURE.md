# BestMiawi System Architecture

## Overview
BestMiawi is a comprehensive food delivery management system built with Flutter. The architecture follows clean code principles with clear separation of concerns across models, services, and UI layers.

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Domain models
│   ├── enums.dart           # System enumerations (Role, StatusCommande, etc.)
│   ├── utilisateur.dart     # Base user class
│   ├── client.dart          # Client user type
│   ├── gerant.dart          # Manager user type
│   ├── coordinateur.dart    # Coordinator user type
│   ├── livreur.dart         # Delivery person user type
│   ├── collaborateur.dart   # Staff member user type
│   ├── visiteur.dart        # Visitor user type
│   ├── notification.dart    # Notification model
│   ├── commande.dart        # Order/Command model
│   ├── ligne_commande.dart  # Order line item model
│   ├── livraison.dart       # Delivery model
│   ├── plat.dart            # Dish model
│   ├── menu.dart            # Menu model
│   ├── point_de_vente.dart  # Sales point/Restaurant location
│   └── disponibilite.dart   # Availability model
├── services/                # Business logic layer
│   ├── auth_service.dart    # Authentication service
│   ├── commande_service.dart # Order management service
│   ├── menu_service.dart    # Menu management service
│   └── notification_service.dart # Notification management service
└── screens/                 # UI layer
    ├── login_screen.dart    # User login screen
    └── home_screen.dart     # Main dashboard (role-based)
```

## Architecture Layers

### 1. Models Layer (`lib/models/`)
Represents the domain entities from the class diagrams:

- **Enums**: `Role`, `StatusCommande`, `NotificationType`
- **User Types**: Inheritance hierarchy with `Utilisateur` as base class
  - `Client`: Can browse menu, place orders, check status
  - `Gerant`: Manages commands and collaborators
  - `Coordinateur`: Tracks command preparation
  - `Livreur`: Manages deliveries
  - `Collaborateur`: Staff member with availability management
  - `Visiteur`: Guest user
- **Business Entities**:
  - `Commande`: Order with line items and delivery info
  - `LigneCommande`: Order line item with quantity and price
  - `Plat`: Dish with availability and pricing
  - `Menu`: Collection of dishes
  - `Livraison`: Delivery information and tracking
  - `PointDeVente`: Sales location with staff and menu
  - `Disponibilite`: Availability slots for staff
  - `Notification`: System notifications

### 2. Services Layer (`lib/services/`)
Implements business logic and data management:

- **AuthService**: Singleton pattern for user authentication
  - `login()`: Authenticate user
  - `logout()`: Clear current user
  - `isAuthenticated()`: Check auth status

- **CommandeService**: Singleton pattern for order management
  - CRUD operations for commands
  - Filter by status
  - Update command status

- **MenuService**: Singleton pattern for menu management
  - CRUD operations for menus
  - Manage dishes in menus
  - Get available dishes

- **NotificationService**: Singleton pattern for notifications
  - Create and manage notifications
  - Mark as read
  - Get unread notifications

### 3. UI Layer (`lib/screens/`)
Flutter screens for user interaction:

- **LoginScreen**: Authentication interface
  - Email and password input
  - Error handling and loading states
  - Navigation to home on success

- **HomeScreen**: Role-based dashboard
  - Different content for each user role
  - Bottom navigation for authenticated users
  - Logout functionality
  - Quick access to role-specific features

## Design Patterns Used

### 1. Singleton Pattern
Services use singleton pattern to ensure single instance:
```dart
static final AuthService _instance = AuthService._internal();
factory AuthService() => _instance;
```

### 2. Inheritance
User types inherit from `Utilisateur` base class:
```dart
class Client extends Utilisateur { ... }
class Gerant extends Utilisateur { ... }
```

### 3. Composition
Complex entities use composition:
- `Commande` contains `List<LigneCommande>`
- `Menu` contains `List<Plat>`
- `PointDeVente` contains `List<Collaborateur>`

### 4. Enumerations
Type-safe status and role management using enums

## User Roles and Permissions

| Role | Capabilities |
|------|--------------|
| **Client** | Browse menu, place orders, check status, cancel orders |
| **Gerant** | Manage commands, manage sales points, manage staff |
| **Coordinateur** | Track command preparation |
| **Livreur** | Track deliveries, update location |
| **Collaborateur** | Manage availability status |
| **Visiteur** | Browse menu (read-only) |

## Data Flow

### Authentication Flow
1. User enters credentials on `LoginScreen`
2. `AuthService.login()` validates credentials
3. On success, navigate to `HomeScreen`
4. `HomeScreen` displays role-specific content

### Order Management Flow
1. Client places order via UI
2. `CommandeService.createCommande()` stores order
3. `CommandeService.updateCommandeStatus()` tracks status changes
4. Notifications sent via `NotificationService`

## Future Enhancements

1. **Backend Integration**: Replace mock data with API calls
2. **State Management**: Integrate Provider or Riverpod for state management
3. **Persistence**: Add local database (SQLite/Hive) for offline support
4. **Real-time Updates**: Implement WebSocket for live order tracking
5. **Payment Integration**: Add payment gateway support
6. **Maps Integration**: Real-time delivery tracking with maps
7. **Push Notifications**: Firebase Cloud Messaging integration
8. **Analytics**: User behavior and business metrics tracking

## Key Implementation Notes

- All services use singleton pattern for global state management
- Models are immutable where possible (final fields)
- Error handling with try-catch blocks
- Null safety enabled throughout
- Role-based UI rendering in `HomeScreen`
- Placeholder implementations marked with `TODO` comments

## Getting Started

1. Ensure Flutter is installed
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application
4. Login with any email/password (currently accepts all)
5. Navigate through role-specific dashboards

## Testing Recommendations

1. Unit tests for service layer
2. Widget tests for UI components
3. Integration tests for user flows
4. Mock backend responses for testing
