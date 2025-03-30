import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  String? _token;
  int? _userId;
  String? _username;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get username => _username;
  int? get userId => _userId;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        _token = 'dummy_token'; // 实际应用中应该从响应中获取真实token
        _userId = responseData['user']['id'];
        _username = responseData['user']['username'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setInt('userId', _userId!);
        await prefs.setString('username', _username!);
      } else {
        _error = responseData['message'];
      }
    } catch (err) {
      _error = '登录失败，请检查网络连接';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await login(username, password);
      } else {
        _error = responseData['message'];
      }
    } catch (err) {
      _error = '注册失败，请检查网络连接';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId');
    final username = prefs.getString('username');

    if (token != null && userId != null && username != null) {
      _token = token;
      _userId = userId;
      _username = username;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _username = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('username');

    notifyListeners();
  }
}