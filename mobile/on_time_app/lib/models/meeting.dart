class Meeting {
  final String? id;
  final String title;
  final String location;
  final DateTime date;
  final String stake;
  final bool isCreator;

  Meeting({
    this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.stake,
    this.isCreator = true,
  });
}