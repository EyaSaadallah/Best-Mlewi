import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../utils/validators.dart';
import '../models/enums.dart';

/// Sign up screen for adding a new collaborator
class CollaborateurSignupScreen extends StatefulWidget {
  const CollaborateurSignupScreen({super.key});

  @override
  State<CollaborateurSignupScreen> createState() =>
      _CollaborateurSignupScreenState();
}

class _CollaborateurSignupScreenState extends State<CollaborateurSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = FirebaseAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  Role _selectedRole = Role.collaborateur;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _lastNameController.text.trim(),
        _firstNameController.text.trim(),
        _phoneController.text.trim(),
        role: _selectedRole,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collaborator account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Return to previous screen
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
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
        title: const Text('Add Collaborator'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Title
              Text(
                'New Collaborator',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new account for a staff member',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              // First Name field
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  hintText: 'Enter first name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  enabled: !_isLoading,
                ),
                validator: (value) => Validators.validateName(value),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Last Name field
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Enter last name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  enabled: !_isLoading,
                ),
                validator: (value) => Validators.validateName(value),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                  enabled: !_isLoading,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => Validators.validateEmail(value),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                  enabled: !_isLoading,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => Validators.validatePhone(value),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter a strong password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  enabled: !_isLoading,
                ),
                obscureText: _obscurePassword,
                validator: (value) => Validators.validatePassword(value),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              // Password requirements hint
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  'Password must contain:\n• At least 8 characters\n• Uppercase letter (A-Z)\n• Lowercase letter (a-z)\n• Number (0-9)\n• Special character (@\$!%*?&)',
                  style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                ),
              ),
              const SizedBox(height: 16),
              // Confirm Password field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  enabled: !_isLoading,
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) => Validators.validatePasswordConfirmation(
                  value,
                  _passwordController.text,
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              // Role selection
              DropdownButtonFormField<Role>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                  enabled: !_isLoading,
                ),
                items: const [
                  DropdownMenuItem(
                    value: Role.collaborateur,
                    child: Text('Collaborateur'),
                  ),
                  DropdownMenuItem(value: Role.livreur, child: Text('Livreur')),
                  DropdownMenuItem(
                    value: Role.coordinateur,
                    child: Text('Coordinateur'),
                  ),
                ],
                onChanged: (Role? value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),
              // Sign up button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
