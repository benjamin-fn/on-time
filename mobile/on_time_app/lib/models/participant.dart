class Participant {
  final String? id;
  final String name;
  final String meetingId;
  final String status;

  Participant({
    this.id,
    required this.name,
    required this.meetingId,
    required this.status,
  });
}