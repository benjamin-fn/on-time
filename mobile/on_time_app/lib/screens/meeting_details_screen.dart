import 'package:flutter/material.dart';

import '../models/meeting.dart';
import '../models/participant.dart';
import '../services/participant_service.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final Meeting meeting;

  const MeetingDetailsScreen({
    super.key,
    required this.meeting,
  });

  @override
  State<MeetingDetailsScreen> createState() =>
      _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState
    extends State<MeetingDetailsScreen> {
  final ParticipantService _participantService =
      ParticipantService();

  final List<Participant> _participants = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final meetingId = widget.meeting.id;

    if (meetingId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Träffen saknar ID.';
      });
      return;
    }

    try {
      final participants =
          await _participantService.getParticipants(meetingId);

      if (!mounted) return;

      setState(() {
        _participants
          ..clear()
          ..addAll(participants);

        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Kunde inte hämta deltagare.';
      });
    }
  }

  Future<void> _showAddParticipantDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lägg till deltagare'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Namn',
              hintText: 'Exempel: Anna',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(context, value);
              },
              child: const Text('Lägg till'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null) return;

    await _addParticipant(name);
  }

  Future<void> _addParticipant(String name) async {
    final meetingId = widget.meeting.id;

    if (meetingId == null) {
      return;
    }

    try {
      final participant =
          await _participantService.createParticipant(
        meetingId,
        name,
      );

      if (!mounted) return;

      setState(() {
        _participants.add(participant);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name lades till'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kunde inte lägga till deltagaren.',
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month ${date.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Träff'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            meeting.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(meeting.location),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule),
              const SizedBox(width: 8),
              Text(_formatDate(meeting.date)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'På spel: ${meeting.stake}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Deltagare',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: _showAddParticipantDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Lägg till'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildParticipants(),
        ],
      ),
    );
  }

  Widget _buildParticipants() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          Text(_errorMessage!),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });

              _loadParticipants();
            },
            child: const Text('Försök igen'),
          ),
        ],
      );
    }

    if (_participants.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Inga deltagare ännu.',
          ),
        ),
      );
    }

    return Column(
      children: _participants.map((participant) {
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(participant.name),
          ),
        );
      }).toList(),
    );
  }
}