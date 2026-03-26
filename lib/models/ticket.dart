class Ticket {
  final int id;
  final String statut;
  final DateTime dateExpiration;
  final String? contribuableNom;
  final String? taxeNom;

  Ticket({
    required this.id,
    required this.statut,
    required this.dateExpiration,
    this.contribuableNom,
    this.taxeNom,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      statut: json['statut'],
      dateExpiration: DateTime.parse(json['date_expiration']),
      contribuableNom: json['contribuable']?['nom'],
      taxeNom: json['taxe']?['type_taxe']?['nom'],
    );
  }
}