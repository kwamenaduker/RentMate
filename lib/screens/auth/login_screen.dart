import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Show forgot password dialog
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController resetEmailController = TextEditingController();
    String? resetError;
    bool isResetLoading = false;
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter your email address and we will send you a link to reset your password.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: resetEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => Validators.validateEmail(value),
                    ),
                    if (resetError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          resetError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                isResetLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: () async {
                          final email = resetEmailController.text.trim();
                          final emailError = Validators.validateEmail(email);
                          
                          if (emailError != null) {
                            setState(() {
                              resetError = emailError;
                            });
                            return;
                          }
                          
                          setState(() {
                            isResetLoading = true;
                            resetError = null;
                          });
                          
                          try {
                            final authService = context.read<AuthService>();
                            await authService.resetPassword(email);
                            
                            if (mounted) {
                              Navigator.of(context).pop();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password reset link sent. Please check your email.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              resetError = 'Failed to send reset email: ${e.toString()}';
                              isResetLoading = false;
                            });
                          }
                        },
                        child: const Text('Reset Password'),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = context.read<AuthService>();
        
        // All validation is handled in AuthService, including:
        // - Email format validation
        // - Account lockout after failed attempts
        // - Input sanitization
        await authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        setState(() {
          _errorMessage = _getMessageFromErrorCode(e.toString());
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _getMessageFromErrorCode(String errorCode) {
    // Most error handling is done in AuthService now, but keeping this as a backup
    if (errorCode.contains('user-not-found')) {
      return 'No user found with this email.';
    } else if (errorCode.contains('wrong-password')) {
      return 'Wrong password provided.';
    } else if (errorCode.contains('invalid-email')) {
      return 'The email address is not valid.';
    } else if (errorCode.contains('user-disabled')) {
      return 'This user has been disabled.';
    } else if (errorCode.contains('too-many-requests')) {
      return 'Too many unsuccessful login attempts. Please try again later.';
    } else if (errorCode.contains('operation-not-allowed')) {
      return 'Email/password accounts are not enabled.';
    } else if (errorCode.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    }
    // Just display the actual error message from the service for other validation errors
    return errorCode.replaceAll('Exception: ', '');
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
                  'Welcome Back',
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Sign in to access your account',
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
                      // Email field with enhanced validation
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.validateEmail(value),
                        autocorrect: false,
                      ),
                      const SizedBox(height: 16),
                      
                      // Password field
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
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
                      
                      // Login button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
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
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sign up link
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: AppTheme.bodyStyle,
                          children: [
                            TextSpan(
                              text: 'Sign Up',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).pushReplacementNamed('/signup');
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
