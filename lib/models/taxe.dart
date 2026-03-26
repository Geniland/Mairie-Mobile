class Taxe {
  final int? id;
  final int communeId;
  final int contribuableId;
  final int typeTaxeId;
  final int agentId;
  final double montant;
  final DateTime periodeDebut;
  final DateTime periodeFin;
  final String statut;
  final String? contribuableNom;
  final String? typeTaxeNom;

  Taxe({
    this.id,
    required this.communeId,
    required this.contribuableId,
    required this.typeTaxeId,
    required this.agentId,
    required this.montant,
    required this.periodeDebut,
    required this.periodeFin,
    required this.statut,
    this.contribuableNom,
    this.typeTaxeNom,
  });

  factory Taxe.fromJson(Map<String, dynamic> json) {
    return Taxe(
      id: json['id'],
      communeId: json['commune_id'],
      contribuableId: json['contribuable_id'],
      typeTaxeId: json['type_taxe_id'],
      agentId: json['agent_id'],
       montant: double.tryParse(json['montant'].toString()) ?? 0.0,
      periodeDebut: DateTime.parse(json['periode_debut']),
      periodeFin: DateTime.parse(json['periode_fin']),
      statut: json['statut'],
      contribuableNom: json['contribuable'] != null ? json['contribuable']['nom'] : null,
      typeTaxeNom: json['type_taxe'] != null ? json['type_taxe']['nom'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'commune_id': communeId,
      'contribuable_id': contribuableId,
      'type_taxe_id': typeTaxeId,
      'agent_id': agentId,
      'montant': montant,
      'periode_debut': periodeDebut.toIso8601String().split('T')[0],
      'periode_fin': periodeFin.toIso8601String().split('T')[0],
      'statut': statut,
    };
  }
}
