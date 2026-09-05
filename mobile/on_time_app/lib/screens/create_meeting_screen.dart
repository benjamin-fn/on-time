import 'package:flutter/material.dart';

import '../models/meeting.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() =>
      _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedStake;

  final List<String> _stakes = [
    'Betala fika',
    'Betala lunch',
    'Betala middag',
    'Betala första drinken',
    'Swisha valfritt belopp',
    'Egen regel',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: true,
        ),
        child: child!,
      );
    },
  );

  if (time != null) {
    setState(() {
      _selectedTime = time;
    });
  }
}

  void _saveMeeting() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Välj datum och tid'),
        ),
      );
      return;
    }

    if (_selectedStake == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Välj vad som står på spel'),
        ),
      );
      return;
    }

    final meetingDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final meeting = Meeting(
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      date: meetingDateTime,
      stake: _selectedStake!,
    );

    Navigator.pop(context, meeting);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skapa träff'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                hintText: 'Exempel: Fika med gänget',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Skriv en titel';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Plats',
                hintText: 'Exempel: Espresso House Stortorget',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Skriv en plats';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDate == null
                    ? 'Välj datum'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(
                _selectedTime == null
                    ? 'Välj tid'
                    : _selectedTime!.format(context),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickTime,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedStake,
              decoration: const InputDecoration(
                labelText: 'Vad står på spel?',
              ),
              items: _stakes.map((stake) {
                return DropdownMenuItem<String>(
                  value: stake,
                  child: Text(stake),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStake = value;
                });
              },
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveMeeting,
                child: const Text('Skapa träff'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}