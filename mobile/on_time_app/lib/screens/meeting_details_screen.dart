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
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return const _AddParticipantDialog();
      },
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    await _addParticipant(name.trim());
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

  Future<void> _updateParticipantStatus(
    Participant participant,
    String status,
  ) async {
    final participantId = participant.id;

    if (participantId == null) {
      return;
    }

    try {
      final updatedParticipant =
          await _participantService.updateStatus(
        participantId,
        status,
      );

      if (!mounted) return;

      final index = _participants.indexWhere(
        (item) => item.id == participantId,
      );

      if (index == -1) {
        return;
      }

      setState(() {
        _participants[index] = updatedParticipant;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kunde inte ändra deltagarens status.',
          ),
        ),
      );
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'Accepted':
        return 'Accepterat';
      case 'Declined':
        return 'Tackat nej';
      case 'Invited':
      default:
        return 'Inbjuden';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Accepted':
        return Icons.check_circle_outline;
      case 'Declined':
        return Icons.cancel_outlined;
      case 'Invited':
      default:
        return Icons.mail_outline;
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
            children: [
              const Expanded(
                child: Text(
                  'Deltagare',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    participant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        _statusIcon(participant.status),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusText(participant.status),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: participant.status == 'Accepted'
                            ? null
                            : () {
                                _updateParticipantStatus(
                                  participant,
                                  'Accepted',
                                );
                              },
                        icon: const Icon(
                          Icons.check,
                        ),
                        label: const Text(
                          'Acceptera',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: participant.status == 'Declined'
                            ? null
                            : () {
                                _updateParticipantStatus(
                                  participant,
                                  'Declined',
                                );
                              },
                        icon: const Icon(
                          Icons.close,
                        ),
                        label: const Text(
                          'Tacka nej',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AddParticipantDialog extends StatefulWidget {
  const _AddParticipantDialog();

  @override
  State<_AddParticipantDialog> createState() =>
      _AddParticipantDialogState();
}

class _AddParticipantDialogState
    extends State<_AddParticipantDialog> {
  final TextEditingController _controller =
      TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lägg till deltagare'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Namn',
          hintText: 'Exempel: Anna',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Lägg till'),
        ),
      ],
    );
  }
}