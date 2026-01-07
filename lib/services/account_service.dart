import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';

class SavedAccount {
  final String email;
  final String name;
  final String role; // Store as string
  final String? imageUrl;
  final DateTime lastLogin;

  SavedAccount({
    required this.email,
    required this.name,
    required this.role,
    this.imageUrl,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'imageUrl': imageUrl,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      email: json['email'],
      name: json['name'],
      role: json['role'] ?? 'client',
      imageUrl: json['imageUrl'],
      lastLogin: DateTime.parse(json['lastLogin']),
    );
  }
}

class AccountService {
  static final AccountService _instance = AccountService._internal();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys
  static const String _accountsKey = 'saved_accounts_list';

  factory AccountService() {
    return _instance;
  }

  AccountService._internal();

  /// Save an account (credentials and metadata)
  Future<void> saveAccount({
    required String email,
    required String password,
    required String name,
    required Role role,
    String? imageUrl,
  }) async {
    // 1. Save password securely
    await _secureStorage.write(key: 'pass_$email', value: password);

    // 2. Update list of accounts
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString(_accountsKey);
    List<SavedAccount> accounts = [];

    if (accountsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(accountsJson);
        accounts = decoded.map((e) => SavedAccount.fromJson(e)).toList();
      } catch (e) {
        print('Error parsing saved accounts: $e');
      }
    }

    // Remove existing entry for this email if any
    accounts.removeWhere((a) => a.email == email);

    // Add new/updated entry
    accounts.add(
      SavedAccount(
        email: email,
        name: name,
        role: role.name,
        imageUrl: imageUrl,
        lastLogin: DateTime.now(),
      ),
    );

    // Save back to prefs
    await prefs.setString(
      _accountsKey,
      jsonEncode(accounts.map((e) => e.toJson()).toList()),
    );
  }

  /// Get all saved accounts sorted by last login
  Future<List<SavedAccount>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString(_accountsKey);

    if (accountsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      final accounts = decoded.map((e) => SavedAccount.fromJson(e)).toList();

      // Sort: most recently used first
      accounts.sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
      return accounts;
    } catch (e) {
      print('Error parsing saved accounts: $e');
      return [];
    }
  }

  /// Get password for an email
  Future<String?> getPassword(String email) async {
    return await _secureStorage.read(key: 'pass_$email');
  }

  /// Remove an account
  Future<void> removeAccount(String email) async {
    // Remove password
    await _secureStorage.delete(key: 'pass_$email');

    // Remove from list
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString(_accountsKey);

    if (accountsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(accountsJson);
        final accounts = decoded.map((e) => SavedAccount.fromJson(e)).toList();

        accounts.removeWhere((a) => a.email == email);

        await prefs.setString(
          _accountsKey,
          jsonEncode(accounts.map((e) => e.toJson()).toList()),
        );
      } catch (e) {
        print('Error removing account: $e');
      }
    }
  }

  /// Clear all accounts
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountsKey);
  }
}
