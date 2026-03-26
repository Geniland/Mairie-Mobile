class Quartier {
  final int id;
  final String nom;
  final int communeId;

  Quartier({
    required this.id,
    required this.nom,
    required this.communeId,
  });

  factory Quartier.fromJson(Map<String, dynamic> json) {
    return Quartier(
      id: json['id'],
      nom: json['nom'],
      communeId: json['commune_id'],
    );
  }
}

class TypeTaxe {
  final int id;
  final String nom;
  final double? montantDefaut;

  TypeTaxe({
    required this.id,
    required this.nom,
    this.montantDefaut,
  });

  factory TypeTaxe.fromJson(Map<String, dynamic> json) {
    return TypeTaxe(
      id: json['id'],
      nom: json['nom'],
      montantDefaut: json['montant_defaut'] != null ? (json['montant_defaut'] as num).toDouble() : null,
    );
  }
}

class Commune {
  final int id;
  final String nom;

  Commune({
    required this.id,
    required this.nom,
  });

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      id: json['id'],
      nom: json['nom'],
    );
  }
}
