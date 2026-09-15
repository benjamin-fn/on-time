import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthService {
  static const String _baseUrl =
      'http://10.0.2.2:5054';

  static const String _tokenKey =
      'auth_token';

  static const String _userIdKey =
      'user_id';

  static const String _userNameKey =
      'user_name';

  static const String _userEmailKey =
      'user_email';

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/api/auth/register',
      ),
      headers: {
        'Content-Type':
            'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Registrering misslyckades. '
        'Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    final user = User.fromJson(data);

    await _saveUser(user);

    await registerDeviceToken();

    return user;
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/api/auth/login',
      ),
      headers: {
        'Content-Type':
            'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Inloggning misslyckades. '
        'Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    final user = User.fromJson(data);

    await _saveUser(user);

    await registerDeviceToken();

    return user;
  }

  Future<void> _saveUser(
    User user,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      user.token,
    );

    await prefs.setString(
      _userIdKey,
      user.id,
    );

    await prefs.setString(
      _userNameKey,
      user.name,
    );

    await prefs.setString(
      _userEmailKey,
      user.email,
    );
  }

  Future<User?> getSavedUser() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString(_tokenKey);

    final id =
        prefs.getString(_userIdKey);

    final name =
        prefs.getString(_userNameKey);

    final email =
        prefs.getString(_userEmailKey);

    if (token == null ||
        id == null ||
        name == null ||
        email == null) {
      return null;
    }

    return User(
      id: id,
      name: name,
      email: email,
      token: token,
    );
  }

  Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _tokenKey,
    );
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null &&
        token.isNotEmpty;
  }

  Future<void> registerDeviceToken() async {
    final authToken = await getToken();

    if (authToken == null ||
        authToken.isEmpty) {
      return;
    }

    final fcmToken =
        await FirebaseMessaging.instance
            .getToken();

    if (fcmToken == null ||
        fcmToken.isEmpty) {
      return;
    }

    final response = await http.put(
      Uri.parse(
        '$_baseUrl/api/users/device-token',
      ),
      headers: {
        'Content-Type':
            'application/json; charset=utf-8',
        'Authorization':
            'Bearer $authToken',
      },
      body: jsonEncode({
        'fcmToken': fcmToken,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Kunde inte registrera enheten '
        'för pushnotiser. '
        'Status: ${response.statusCode}',
      );
    }

    debugPrint(
      'FCM-token sparad i backend.',
    );
  }

  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _tokenKey,
    );

    await prefs.remove(
      _userIdKey,
    );

    await prefs.remove(
      _userNameKey,
    );

    await prefs.remove(
      _userEmailKey,
    );
  }
}