import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  bool get isAuthenticated => _token != null;

  String? get token => _token;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      _token = await _prefs.getString('auth_token');
      notifyListeners(); // Notify even if token is null to ensure UI updates
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  Future<void> login(String token) async {
    try {
      _token = token;
      await _prefs.setString('auth_token', token);
      print('Token saved: $token'); // Debug print
      notifyListeners();
    } catch (e) {
      print('Error saving token: $e');
      throw Exception('Failed to save token');
    }
  }

  Future<void> logout() async {
    try {
      _token = null;
      await _prefs.remove('auth_token');
      notifyListeners();
    } catch (e) {
      print('Error removing token: $e');
      throw Exception('Failed to remove token');
    }
  }
}