import '../models/menu.dart';
import '../models/plat.dart';

/// Service for managing menus and dishes
class MenuService {
  static final MenuService _instance = MenuService._internal();

  factory MenuService() {
    return _instance;
  }

  MenuService._internal();

  final List<Menu> _menus = [];

  /// Get all menus
  List<Menu> getMenus() {
    return _menus;
  }

  /// Get menu by ID
  Menu? getMenuById(int id) {
    try {
      return _menus.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Create new menu
  void createMenu(Menu menu) {
    _menus.add(menu);
  }

  /// Update menu
  void updateMenu(Menu menu) {
    final index = _menus.indexWhere((m) => m.id == menu.id);
    if (index != -1) {
      _menus[index] = menu;
    }
  }

  /// Delete menu
  void deleteMenu(int id) {
    _menus.removeWhere((m) => m.id == id);
  }

  /// Get available dishes from menu
  List<Plat> getAvailableDishes(int menuId) {
    final menu = getMenuById(menuId);
    return menu?.getPlatDisponibles() ?? [];
  }

  /// Add dish to menu
  void addDishToMenu(int menuId, Plat plat) {
    final menu = getMenuById(menuId);
    if (menu != null) {
      menu.ajouterPlat(plat);
    }
  }

  /// Remove dish from menu
  void removeDishFromMenu(int menuId, Plat plat) {
    final menu = getMenuById(menuId);
    if (menu != null) {
      menu.supprimerPlat(plat);
    }
  }
}
