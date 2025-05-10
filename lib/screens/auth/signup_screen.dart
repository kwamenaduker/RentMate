import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String _passwordStrength = 'Empty';
  bool _emailVerificationSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Update password strength whenever password changes
  void _checkPasswordStrength(String password) {
    setState(() {
      // Simple assessment for visual indicator
      if (password.isEmpty) {
        _passwordStrength = 'Empty';
      } else if (password.length < 8) {
        _passwordStrength = 'Weak';
      } else {
        int strength = 0;
        if (password.contains(RegExp(r'[A-Z]'))) strength++;
        if (password.contains(RegExp(r'[a-z]'))) strength++;
        if (password.contains(RegExp(r'[0-9]'))) strength++;
        if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength++;
        
        if (strength <= 2) _passwordStrength = 'Moderate';
        else if (strength == 3) _passwordStrength = 'Strong';
        else _passwordStrength = 'Very Strong';
      }
    });
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = context.read<AuthService>();
        
        // All validation is handled in AuthService, including:
        // - Email format validation
        // - Password strength requirements
        // - Input sanitization
        // - Security checks
        await authService.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
        
        // Show email verification sent dialog instead of auto-navigation
        if (mounted) {
          setState(() {
            _emailVerificationSent = true;
            _isLoading = false;
          });
          
          // Show verification dialog
          await _showVerificationDialog();
          
          // Navigate to login after showing verification dialog
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        setState(() {
          _errorMessage = _getMessageFromErrorCode(e.toString());
        });
      } finally {
        if (mounted && !_emailVerificationSent) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  // Show verification dialog after signup
  Future<void> _showVerificationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verify Your Email'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('A verification email has been sent to your email address.'),
                SizedBox(height: 8),
                Text('Please check your inbox and follow the instructions to verify your account before logging in.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getMessageFromErrorCode(String errorCode) {
    // Most error handling is done in AuthService now, but keeping this as a backup
    if (errorCode.contains('email-already-in-use')) {
      return 'The email address is already in use by another account.';
    } else if (errorCode.contains('invalid-email')) {
      return 'The email address is not valid.';
    } else if (errorCode.contains('operation-not-allowed')) {
      return 'Email/password accounts are not enabled.';
    } else if (errorCode.contains('weak-password')) {
      return 'The password is too weak.';
    } else if (errorCode.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    }
    // Just display the actual error message from the service for other validation errors
    return errorCode.replaceAll('Exception: ', '');
  }
  
  // Helper method to build password requirement text
  Widget _buildRequirementText(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          color: isMet ? Colors.green : Colors.grey,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
  
  // Helper method to get color based on password strength
  Color _getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'Empty':
      case 'Weak':
        return Colors.red;
      case 'Moderate':
        return Colors.orange;
      case 'Strong':
        return Colors.green[300]!;
      case 'Very Strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                const Icon(
                  Icons.home_work,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Create Account',
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Sign up to get started with RentMate',
                  style: AppTheme.captionStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name field with enhanced validation
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.validateName(value),
                      ),
                      const SizedBox(height: 16),
                      
                      // Email field with enhanced validation
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.validateEmail(value),
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone field with enhanced validation
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.validatePhone(value),
                      ),
                      const SizedBox(height: 16),
                      
                      // Password field with enhanced security
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        onChanged: _checkPasswordStrength,
                        validator: (value) => Validators.validatePassword(value),
                      ),
                      const SizedBox(height: 8),
                      
                      // Password strength indicator
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Row(
                          children: [
                            const Text(
                              'Password Strength: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              _passwordStrength,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getPasswordStrengthColor(_passwordStrength),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Password requirements
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Password must contain:',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            _buildRequirementText(
                              'At least 8 characters',
                              _passwordController.text.length >= 8,
                            ),
                            _buildRequirementText(
                              'At least one uppercase letter (A-Z)',
                              _passwordController.text.contains(RegExp(r'[A-Z]')),
                            ),
                            _buildRequirementText(
                              'At least one lowercase letter (a-z)',
                              _passwordController.text.contains(RegExp(r'[a-z]')),
                            ),
                            _buildRequirementText(
                              'At least one number (0-9)',
                              _passwordController.text.contains(RegExp(r'[0-9]')),
                            ),
                            _buildRequirementText(
                              'At least one special character (!@#\$%^&*)',
                              _passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirm password field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Error message
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                      // Sign up button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Sign Up'),
                      ),
                      const SizedBox(height: 24),
                      
                      // Login link
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: AppTheme.bodyStyle,
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).pushReplacementNamed('/login');
                                },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
