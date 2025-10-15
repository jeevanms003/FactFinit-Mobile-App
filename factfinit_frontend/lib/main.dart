import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart' as receiveIntent;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const FactFinitApp(),
    ),
  );
}

class FactFinitApp extends StatefulWidget {
  const FactFinitApp({super.key});

  @override
  _FactFinitAppState createState() => _FactFinitAppState();
}

class _FactFinitAppState extends State<FactFinitApp> {
  String? _sharedUrl;
  StreamSubscription<receiveIntent.Intent?>? _intentSub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initReceiveIntent();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _initReceiveIntent() async {
    try {
      // Get initial shared intent
      final initialIntent = await receiveIntent.ReceiveIntent.getInitialIntent();
      if (initialIntent != null &&
          !initialIntent.isNull &&
          initialIntent.action == 'android.intent.action.SEND' &&
          initialIntent.data != null &&
          initialIntent.data!.trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _sharedUrl = initialIntent.data!.trim();
            print('Received URL (initial): ${initialIntent.data}');
          });
        }
      }

      // Listen for new intents
      _intentSub = receiveIntent.ReceiveIntent.receivedIntentStream.listen(
        (receiveIntent.Intent? intent) {
          if (intent != null &&
              !intent.isNull &&
              intent.action == 'android.intent.action.SEND' &&
              intent.data != null &&
              intent.data!.trim().isNotEmpty) {
            if (mounted) {
              setState(() {
                _sharedUrl = intent.data!.trim();
                print('Received URL (stream): ${intent.data}');
              });

              // Navigate to home with shared URL
              final currentRoute = ModalRoute.of(context)?.settings.name;
              if (currentRoute == '/home') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(sharedUrl: _sharedUrl),
                  ),
                );
              } else if (Provider.of<AuthProvider>(context, listen: false)
                  .isAuthenticated) {
                // If authenticated but not on home, navigate to home
                Navigator.pushNamed(context, '/home');
              }
            }
          }
        },
        onError: (err) {
          print('receivedIntentStream error: $err');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error receiving shared URL: $err',
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      );
    } on PlatformException catch (e) {
      print('PlatformException in receive_intent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Platform error receiving URL: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      print('Error in _initReceiveIntent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to initialize URL sharing: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FactFinit',
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitCircle(
                      color: Color(0xFF4F46E5),
                      size: 50.0,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ) // ✅ <-- Added missing closing parenthesis here
          : Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return auth.isAuthenticated
                    ? HomeScreen(sharedUrl: _sharedUrl)
                    : const LoginScreen();
              },
            ),
      routes: {
        '/home': (context) => HomeScreen(sharedUrl: _sharedUrl),
        '/login': (context) => const LoginScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
