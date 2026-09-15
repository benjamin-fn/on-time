import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meeting.dart';
import 'auth_service.dart';

class MeetingService {
  static const String _baseUrl =
      'http://10.0.2.2:5054';

  final AuthService _authService =
      AuthService();

  Future<Map<String, String>>
      _getHeaders() async {
    final token =
        await _authService.getToken();

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

  Future<List<Meeting>>
      getMeetings() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/meetings',
      ),
      headers: headers,
    );

    if (response.statusCode == 401) {
      throw Exception(
        'Din inloggning har gått ut.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Kunde inte hämta träffar. '
        'Status: ${response.statusCode}',
      );
    }

    final List<dynamic> data =
        jsonDecode(response.body);

    return data.map((item) {
      return Meeting(
        id: item['id'],
        title: item['title'],
        location: item['location'],
        date: DateTime.parse(
          item['date'],
        ).toLocal(),
        stake: item['stake'],
        isCreator:
            item['isCreator'] ?? false,
      );
    }).toList();
  }

  Future<Meeting> createMeeting(
    Meeting meeting,
  ) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/api/meetings',
      ),
      headers: headers,
      body: jsonEncode({
        'title': meeting.title,
        'location': meeting.location,
        'date': meeting.date
            .toUtc()
            .toIso8601String(),
        'stake': meeting.stake,
      }),
    );

    if (response.statusCode == 401) {
      throw Exception(
        'Din inloggning har gått ut.',
      );
    }

    if (response.statusCode != 201) {
      throw Exception(
        'Kunde inte skapa träffen. '
        'Status: ${response.statusCode}',
      );
    }

    final data =
        jsonDecode(response.body);

    return Meeting(
      id: data['id'],
      title: data['title'],
      location: data['location'],
      date: DateTime.parse(
        data['date'],
      ).toLocal(),
      stake: data['stake'],
      isCreator:
          data['isCreator'] ?? true,
    );
  }
}