import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/login_response.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart'; // Added import for HomeScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isLoginMode = true;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = _isLoginMode
            ? await _apiService.login(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              )
            : await _apiService.register(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              );

        setState(() {
          _isLoading = false;
          if (response.error != null) {
            _errorMessage = response.error;
          } else if (response.token != null) {
            Provider.of<AuthProvider>(context, listen: false).login(response.token!);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            _errorMessage = _isLoginMode ? 'Login failed: No token received.' : 'Registration failed: No token received.';
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = _isLoginMode ? 'Failed to login. Please try again.' : 'Failed to register. Please try again.';
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final padding = isWideScreen ? MediaQuery.of(context).size.width * 0.15 : 24.0;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: isWideScreen ? 40 : 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                print('Failed to load logo at assets/images/logo.png: $error');
                return const Text(
                  'F',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'FactFinit',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.primary,
              size: isWideScreen ? 24 : 22,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isLoginMode ? Icons.lock : Icons.person_add,
                      color: Theme.of(context).colorScheme.primary,
                      size: isWideScreen ? 32 : 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLoginMode ? 'Login to FactFinit' : 'Register for FactFinit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isWideScreen ? 28 : 26,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode
                      ? 'Enter your credentials to access video fact-checking.'
                      : 'Create an account to start fact-checking videos.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isWideScreen ? 16 : 14,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'e.g., user@example.com',
                    prefixIcon: Icon(
                      Icons.email,
                      color: Theme.of(context).colorScheme.primary,
                      size: isWideScreen ? 22 : 20,
                    ),
                    suffixIcon: _emailController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              size: isWideScreen ? 22 : 20,
                            ),
                            onPressed: () {
                              _emailController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailPattern.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Theme.of(context).colorScheme.primary,
                      size: isWideScreen ? 22 : 20,
                    ),
                    suffixIcon: _passwordController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              size: isWideScreen ? 22 : 20,
                            ),
                            onPressed: () {
                              _passwordController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  obscureText: true,
                  onChanged: (value) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        vertical: isWideScreen ? 16 : 14,
                        horizontal: isWideScreen ? 32 : 24,
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SpinKitCircle(
                                color: Colors.white,
                                size: 20.0,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLoginMode ? 'Logging in...' : 'Registering...',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: isWideScreen ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLoginMode ? Icons.login : Icons.person_add,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: isWideScreen ? 20 : 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLoginMode ? 'Login' : 'Register',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: isWideScreen ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms).scaleXY(begin: 0.95, end: 1.0),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(
                    _isLoginMode ? 'Need an account? Register' : 'Already have an account? Login',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isWideScreen ? 14 : 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: isWideScreen ? 22 : 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isWideScreen ? 14 : 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _submit,
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: isWideScreen ? 14 : 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}