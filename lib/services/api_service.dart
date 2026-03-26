import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    final headers = await _getHeaders();
    return await http.post(url, headers: headers, body: jsonEncode(data));
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    final headers = await _getHeaders();
    return await http.get(url, headers: headers);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    final headers = await _getHeaders();
    return await http.put(url, headers: headers, body: jsonEncode(data));
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    final headers = await _getHeaders();
    return await http.delete(url, headers: headers);
  }
}
