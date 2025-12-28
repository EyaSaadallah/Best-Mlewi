import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../services/email_service.dart';
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
  final _emailService = EmailService();
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
      final success = await _authService.registerSecondary(
        _emailController.text.trim(),
        _passwordController.text,
        _lastNameController.text.trim(),
        _firstNameController.text.trim(),
        _phoneController.text.trim(),
        role: _selectedRole,
      );

      if (success) {
        if (mounted) {
          // Show credentials dialog with option to send email
          await _showCredentialsDialog(
            _emailController.text.trim(),
            _passwordController.text,
            _firstNameController.text.trim(),
          );

          if (mounted) {
            Navigator.of(context).pop(); // Return to previous screen
          }
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

  Future<void> _showCredentialsDialog(
    String email,
    String password,
    String firstName,
  ) async {
    // Log credentials to console for debugging/fallback
    debugPrint('=== NEW COLLABORATOR CREDENTIALS ===');
    debugPrint('Email: $email');
    debugPrint('Password: $password');
    debugPrint('=====================================');

    // Auto-send email in background
    _emailService
        .sendCredentialsEmail(
          toEmail: email,
          password: password,
          firstName: firstName,
        )
        .then((sent) {
          if (sent) {
            debugPrint('✅ Auto-email sent successfully');
          } else {
            debugPrint('❌ Auto-email failed');
          }
        });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Collaborator Account Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The account has been created successfully.'),
            const SizedBox(height: 16),
            const Text(
              'Attempting to send credentials via email...',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            SelectableText.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Email: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '$email\n'),
                  const TextSpan(
                    text: 'Password: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: password),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'If the email is not received, please share these credentials manually.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Show loading indicator
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Sending email...')));

              final sent = await _emailService.sendCredentialsEmail(
                toEmail: email,
                password: password,
                firstName: firstName,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (sent) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email sent successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to send email. Please configure credentials in lib/services/email_service.dart',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Staff Onboarding',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'Staff Profile',
                      Icons.person_add_outlined,
                    ),
                    _buildInputGroup([
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.person_outline_rounded,
                        validator: (value) => Validators.validateName(value),
                      ),
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        icon: Icons.person_outline_rounded,
                        validator: (value) => Validators.validateName(value),
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Corporate Email',
                        icon: Icons.alternate_email_rounded,
                        isEmail: true,
                        validator: (value) => Validators.validateEmail(value),
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_iphone_rounded,
                        isPhone: true,
                        validator: (value) => Validators.validatePhone(value),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionTitle(
                      'Security & Access',
                      Icons.lock_outline_rounded,
                    ),
                    _buildInputGroup([
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Temporary Password',
                        icon: Icons.password_rounded,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onTogglePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        validator: (value) =>
                            Validators.validatePassword(value),
                      ),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.verified_user_outlined,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onTogglePassword: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        validator: (value) =>
                            Validators.validatePasswordConfirmation(
                              value,
                              _passwordController.text,
                            ),
                      ),
                      _buildRoleSelection(),
                    ]),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: _buildErrorBanner(_errorMessage!),
                      ),

                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Generate Staff Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (idx < children.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.grey[50], height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isEmail = false,
    bool isPhone = false,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : (isPhone ? TextInputType.phone : TextInputType.text),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.black87, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<Role>(
          value: _selectedRole,
          decoration: InputDecoration(
            labelText: 'Assigned Role',
            labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: Colors.black87,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black,
          ),
          items: const [
            DropdownMenuItem(
              value: Role.collaborateur,
              child: Text(
                'Collaborateur',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DropdownMenuItem(
              value: Role.livreur,
              child: Text(
                'Livreur',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DropdownMenuItem(
              value: Role.coordinateur,
              child: Text(
                'Coordinateur',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          onChanged: (Role? value) {
            if (value != null) setState(() => _selectedRole = value);
          },
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[900],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
