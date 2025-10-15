import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/url_input_form.dart';

class HomeScreen extends StatelessWidget {
  final String? sharedUrl;

  const HomeScreen({super.key, this.sharedUrl});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isWideScreen = MediaQuery.of(context).size.width > 600;

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
              color: Theme.of(context).appBarTheme.foregroundColor ??
                  Theme.of(context).colorScheme.primary,
              size: isWideScreen ? 24 : 22,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).appBarTheme.foregroundColor ??
                  Theme.of(context).colorScheme.primary,
              size: isWideScreen ? 24 : 22,
            ),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: isWideScreen ? 60 : 48,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Failed to load logo at assets/images/logo.png: $error');
                      return const Text(
                        'F',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FactFinit',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Video Fact-Checking',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.verified,
                color: Theme.of(context).colorScheme.primary,
                size: isWideScreen ? 24 : 22,
              ),
              title: Text(
                'Verify Video',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isWideScreen ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.primary,
                size: isWideScreen ? 24 : 22,
              ),
              title: Text(
                'History',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isWideScreen ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/history');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
                size: isWideScreen ? 24 : 22,
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isWideScreen ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: UrlInputForm(initialUrl: sharedUrl),
            ),
          );
        },
      ),
    );
  }
}