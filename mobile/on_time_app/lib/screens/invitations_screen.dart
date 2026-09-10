import 'package:flutter/material.dart';

import '../models/invitation.dart';
import '../services/invitation_service.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() =>
      _InvitationsScreenState();
}

class _InvitationsScreenState
    extends State<InvitationsScreen> {
  final InvitationService _invitationService =
      InvitationService();

  List<Invitation> _invitations = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    try {
      final invitations =
          await _invitationService.getInvitations();

      if (!mounted) return;

      setState(() {
        _invitations = invitations;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Kunde inte hämta dina inbjudningar.';
      });
    }
  }

  Future<void> _respond(
    Invitation invitation,
    String status,
  ) async {
    try {
      await _invitationService.respondToInvitation(
        participantId: invitation.participantId,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        final index = _invitations.indexWhere(
          (item) =>
              item.participantId ==
              invitation.participantId,
        );

        if (index != -1) {
          _invitations[index] = Invitation(
            participantId: invitation.participantId,
            status: status,
            meetingId: invitation.meetingId,
            title: invitation.title,
            location: invitation.location,
            date: invitation.date,
            stake: invitation.stake,
            createdByName:
                invitation.createdByName,
          );
        }
      });

      final message = status == 'Accepted'
          ? 'Du accepterade inbjudan!'
          : 'Du tackade nej till inbjudan.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kunde inte svara på inbjudan.',
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month ${date.year} • '
        '$hour:$minute';
  }

  String _statusText(String status) {
    switch (status) {
      case 'Accepted':
        return 'Accepterad';

      case 'Declined':
        return 'Tackat nej';

      default:
        return 'Väntar på svar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mina inbjudningar',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });

                _loadInvitations();
              },
              child: const Text(
                'Försök igen',
              ),
            ),
          ],
        ),
      );
    }

    if (_invitations.isEmpty) {
      return const Center(
        child: Text(
          'Du har inga inbjudningar ännu.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvitations,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _invitations.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final invitation =
              _invitations[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    invitation.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inbjuden av '
                    '${invitation.createdByName}',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 19,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          invitation.location,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 19,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(
                          invitation.date,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .emoji_events_outlined,
                        size: 19,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'På spel: '
                          '${invitation.stake}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Status: '
                    '${_statusText(invitation.status)}',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (invitation.status ==
                      'Invited')
                    Row(
                      children: [
                        Expanded(
                          child:
                              FilledButton.icon(
                            onPressed: () {
                              _respond(
                                invitation,
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
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child:
                              OutlinedButton.icon(
                            onPressed: () {
                              _respond(
                                invitation,
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
        },
      ),
    );
  }
}