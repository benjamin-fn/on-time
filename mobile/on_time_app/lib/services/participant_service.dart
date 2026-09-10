import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/participant.dart';
import 'auth_service.dart';

class ParticipantService {
  static const String _baseUrl = 'http://10.0.2.2:5054';

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Användaren är inte inloggad.');
    }

    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Participant>> getParticipants(
    String meetingId,
  ) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/meetings/$meetingId/participants',
      ),
      headers: headers,
    );

    if (response.statusCode == 401) {
      throw Exception('Din inloggning har gått ut.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Kunde inte hämta deltagare. Status: ${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map((item) {
      final rawStatus = item['status'] as String?;

      return Participant(
        id: item['id'],
        name: item['name'],
        meetingId: item['meetingId'],
        status: rawStatus == null || rawStatus.isEmpty
            ? 'Invited'
            : rawStatus,
      );
    }).toList();
  }

  Future<Participant> inviteParticipant(
    String meetingId,
    String email,
  ) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/api/meetings/$meetingId/participants',
      ),
      headers: headers,
      body: jsonEncode({
        'email': email.trim(),
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('Din inloggning har gått ut.');
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Ingen användare hittades med den e-postadressen.',
      );
    }

    if (response.statusCode == 409) {
      throw Exception(
        'Användaren är redan inbjuden.',
      );
    }

    if (response.statusCode == 400) {
      throw Exception(
        'Kunde inte skicka inbjudan.',
      );
    }

    if (response.statusCode != 201) {
      throw Exception(
        'Kunde inte bjuda in deltagaren. Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    return Participant(
      id: data['id'],
      name: data['name'],
      meetingId: data['meetingId'],
      status: data['status'],
    );
  }

  Future<Participant> updateStatus(
    String participantId,
    String status,
  ) async {
    final headers = await _getHeaders();

    final response = await http.put(
      Uri.parse(
        '$_baseUrl/api/participants/$participantId/status',
      ),
      headers: headers,
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('Din inloggning har gått ut.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Kunde inte ändra status. Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    return Participant(
      id: data['id'],
      name: data['name'],
      meetingId: data['meetingId'],
      status: data['status'],
    );
  }
}