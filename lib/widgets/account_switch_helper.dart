import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/firebase_auth_service.dart';

class AccountSwitchHelper {
  static Future<void> showSwitchAccountModal(
    BuildContext context,
    FirebaseAuthService authService,
    Function(bool success) onResult,
  ) async {
    final currentUser = authService.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Switch Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: FutureBuilder<List<SavedAccount>>(
                  future: AccountService().getSavedAccounts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final accounts = snapshot.data ?? [];

                    // If no accounts are saved, show a prompt to add one
                    if (accounts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            const Text('No saved accounts found.'),
                            const SizedBox(height: 24),
                            _buildAddButton(context, authService, onResult),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: accounts.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == accounts.length) {
                          return _buildAddButton(
                            context,
                            authService,
                            onResult,
                          );
                        }

                        final account = accounts[index];
                        final isCurrent = currentUser?.email == account.email;

                        return ListTile(
                          onTap: isCurrent
                              ? null
                              : () => _handleSwitchAccount(
                                  context,
                                  account.email,
                                  authService,
                                  onResult,
                                ),
                          contentPadding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isCurrent
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          tileColor: isCurrent ? Colors.grey[50] : Colors.white,
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: account.imageUrl != null
                                ? NetworkImage(account.imageUrl!)
                                : null,
                            child: account.imageUrl == null
                                ? Text(
                                    account.name.isNotEmpty
                                        ? account.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            account.email,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: isCurrent
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.black,
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildAddButton(
    BuildContext context,
    FirebaseAuthService authService,
    Function(bool success) onResult,
  ) {
    return ListTile(
      onTap: () async {
        Navigator.pop(context); // Close sheet
        // If logged in, logout first to add new account
        if (authService.currentUser != null) {
          await authService.logout();
        }
        // Navigate to login (this might vary depending on context)
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/visitor', (route) => false);
          // The visitor screen defaults to login tab when not authenticated
        }
      },
      contentPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
      title: const Text(
        'Add Another Account',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  static Future<void> _handleSwitchAccount(
    BuildContext context,
    String email,
    FirebaseAuthService authService,
    Function(bool success) onResult,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final password = await AccountService().getPassword(email);
      if (password != null) {
        final success = await authService.login(email, password);

        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          Navigator.pop(context); // Pop sheet

          if (success) {
            onResult(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switched account successfully')),
            );
          } else {
            onResult(false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to switch account')),
            );
          }
        }
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credentials not found, please login again'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
