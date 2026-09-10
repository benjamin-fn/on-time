class Invitation {
  final String participantId;
  final String status;
  final String meetingId;
  final String title;
  final String location;
  final DateTime date;
  final String stake;
  final String createdByName;

  Invitation({
    required this.participantId,
    required this.status,
    required this.meetingId,
    required this.title,
    required this.location,
    required this.date,
    required this.stake,
    required this.createdByName,
  });

  factory Invitation.fromJson(
    Map<String, dynamic> json,
  ) {
    return Invitation(
      participantId: json['participantId'] as String,
      status: json['status'] as String,
      meetingId: json['meetingId'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      date: DateTime.parse(
        json['date'] as String,
      ).toLocal(),
      stake: json['stake'] as String,
      createdByName: json['createdByName'] as String,
    );
  }
}