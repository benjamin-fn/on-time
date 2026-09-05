import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/participant.dart';

class ParticipantService {
  static const String _baseUrl = 'http://10.0.2.2:5054';

  Future<List<Participant>> getParticipants(String meetingId) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/meetings/$meetingId/participants',
      ),
    );

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

  Future<Participant> createParticipant(
    String meetingId,
    String name,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/api/meetings/$meetingId/participants',
      ),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'name': name,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Kunde inte lägga till deltagare. Status: ${response.statusCode}',
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
    final response = await http.put(
      Uri.parse(
        '$_baseUrl/api/participants/$participantId/status',
      ),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

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