// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/verify_response.dart';
import '../models/login_response.dart';
import '../models/history_response.dart';
import '../providers/auth_provider.dart';

class ApiService {
  Future<VerifyResponse> fetchTranscript({
    required String videoURL,
    required BuildContext context,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final url = Uri.parse('${Constants.apiBaseUrl}/api/verify');
    final body = {'videoURL': videoURL};

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode(body),
      );

      print('Backend response: ${response.statusCode} - ${response.body}');
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 404) {
        return VerifyResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to fetch transcript: ${response.statusCode} - ${jsonResponse['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('API error: $e');
      throw Exception('Error fetching transcript: $e');
    }
  }

  Future<LoginResponse> login({required String email, required String password}) async {
    final url = Uri.parse('${Constants.apiBaseUrl}/api/auth/login');
    final body = {'email': email, 'password': password};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('Login response: ${response.statusCode} - ${response.body}');
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${jsonResponse['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Login API error: $e');
      throw Exception('Error during login: $e');
    }
  }

  Future<LoginResponse> register({required String email, required String password}) async {
    final url = Uri.parse('${Constants.apiBaseUrl}/api/auth/register');
    final body = {'email': email, 'password': password};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('Register response: ${response.statusCode} - ${response.body}');
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return LoginResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Registration failed: ${response.statusCode} - ${jsonResponse['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Register API error: $e');
      throw Exception('Error during registration: $e');
    }
  }

  Future<HistoryResponse> fetchHistory({
    required BuildContext context,
    int page = 1,
    int limit = 10,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final url = Uri.parse('${Constants.apiBaseUrl}/api/history?page=$page&limit=$limit');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      print('History response: ${response.statusCode} - ${response.body}');
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return HistoryResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to fetch history: ${response.statusCode} - ${jsonResponse['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('History API error: $e');
      throw Exception('Error fetching history: $e');
    }
  }
}