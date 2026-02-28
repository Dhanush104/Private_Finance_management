import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isAdmin => _user?.role == 'admin';

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('rsb_token');
    
    if (_token != null) {
      await fetchMe();
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> fetchMe() async {
    try {
      final response = await ApiService.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('rsb_user', jsonEncode(_user!.toJson()));
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await ApiService.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('rsb_token', _token!);
        await prefs.setString('rsb_user', jsonEncode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Login failed
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rsb_token');
    await prefs.remove('rsb_user');
    
    notifyListeners();
  }
}
