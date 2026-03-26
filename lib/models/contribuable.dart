class Contribuable {
  final int? id;
  final int? agentId;
  final int communeId;
  final String nom;
  final String telephone;
  final String type;
  final String? numeroIdentifiant;
  final String? adresse;
  final String? communeName;

  Contribuable({
    this.id,
    this.agentId,
    required this.communeId,
    required this.nom,
    required this.telephone,
    required this.type,
    this.numeroIdentifiant,
    this.adresse,
    this.communeName,
  });

  factory Contribuable.fromJson(Map<String, dynamic> json) {
    return Contribuable(
      id: json['id'],
      agentId: json['agent_id'],
      communeId: json['commune_id'],
      nom: json['nom'],
      telephone: json['telephone'],
      type: json['type'],
      numeroIdentifiant: json['numero_identifiant'],
      adresse: json['adresse'],
      communeName: json['commune'] != null ? json['commune']['nom'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (agentId != null) 'agent_id': agentId,
      'commune_id': communeId,
      'nom': nom,
      'telephone': telephone,
      'type': type,
      if (numeroIdentifiant != null) 'numero_identifiant': numeroIdentifiant,
      'adresse': adresse,
    };
  }
}
