import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/invitation.dart';
import 'auth_service.dart';

class InvitationService {
  static const String _baseUrl =
      'http://10.0.2.2:5054';

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Användaren är inte inloggad.',
      );
    }

    return {
      'Content-Type':
          'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Invitation>> getInvitations() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$_baseUrl/api/invitations'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      throw Exception(
        'Din inloggning har gått ut.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Kunde inte hämta inbjudningar. '
        'Status: ${response.statusCode}',
      );
    }

    final List<dynamic> data =
        jsonDecode(response.body);

    return data
        .map(
          (item) => Invitation.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> respondToInvitation({
    required String participantId,
    required String status,
  }) async {
    final headers = await _getHeaders();

    final response = await http.put(
      Uri.parse(
        '$_baseUrl/api/participants/'
        '$participantId/status',
      ),
      headers: headers,
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode == 401) {
      throw Exception(
        'Din inloggning har gått ut.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Kunde inte svara på inbjudan. '
        'Status: ${response.statusCode}',
      );
    }
  }
}