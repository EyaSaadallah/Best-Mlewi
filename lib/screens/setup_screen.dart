import 'package:flutter/material.dart';
import '../utils/seed_data.dart';

/// Setup screen to initialize gerant account
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _createGerantAccount() async {
    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = false;
    });

    try {
      print('Starting gerant account creation...');
      await SeedData.createGerantAccount(
        email: 'benjdidiaomar@gmail.com',
        password: 'Gerant@2024',
        nom: 'Ben Jdidia',
        prenom: 'Omar',
        telephone: '+216',
      );

      print('✓ Gerant account created successfully!');
      setState(() {
        _message =
            '✓ Gerant account created successfully!\n\nEmail: benjdidiaomar@gmail.com\nPassword: Gerant@2024\n\nYou can now login with these credentials.';
        _isSuccess = true;
      });

      // Auto-navigate back after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('✗ Error creating gerant: $e');
      setState(() {
        _message = '✗ Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup - Create Gerant'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            // Icon
            Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.deepPurple[300],
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Create Gerant Account',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              'Initialize the super user (gerant) account for BestMiawi',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            // Account details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Details:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Name:', 'Omar BenJdidia'),
                  _buildDetailRow('Email:', 'benjdidiaomar@gmail.com'),
                  _buildDetailRow('Password:', 'Omar1998*'),
                  _buildDetailRow('Role:', 'Gerant (Super User)'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Message
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? Colors.green[300]! : Colors.red[300]!,
                  ),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green[900] : Colors.red[900],
                  ),
                ),
              ),
            if (_message != null) const SizedBox(height: 24),
            // Create button
            ElevatedButton(
              onPressed: _isLoading ? null : _createGerantAccount,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Gerant Account',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
            const SizedBox(height: 16),
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                '⚠️ This will create a new gerant account in Firebase. If the account already exists, it will be skipped.',
                style: TextStyle(fontSize: 12, color: Colors.amber[900]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
