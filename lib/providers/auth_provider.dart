import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  final ApiService _apiService = ApiService();

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

Future<bool> login(String email, String password) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _apiService.post('login', {
      'email': email,
      'password': password,
    });

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    final data = jsonDecode(response.body);

    // 🔹 Utiliser le champ 'success' au lieu de 'status'
    if (response.statusCode == 200 && data['success'] == true) {
      final agentData = data['agent'];
      final token = data['token'];

      _user = User(
        id: agentData['id'],
        name: agentData['nom'],
        email: agentData['email'],
        token: token,
        role: agentData['role'],
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = data['message'] ?? 'Échec de la connexion';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  } catch (e) {
    print(e); // log complet de l'erreur
    _error = 'Erreur de connexion au serveur';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
  Future<void> logout() async {
    try {
      await _apiService.post('logout', {});
    } catch (e) {
      // Ignore error during logout
    }
    
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    notifyListeners();
  }
}
