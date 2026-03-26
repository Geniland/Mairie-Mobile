class Payment {
  final int? id;
  final int? taxeId;
  
  final int? communeId;
  final int? contribuableId;
  final int? quartierId;
  final double montant;
  final String modePayement;
  final DateTime datePayement;
  final String? referenceTransaction;
  final String? reference;
  final String? contribuableNom;
  final String? taxeType;


  Payment({
    this.id,
    required this.taxeId,
    
    required this.communeId,
    required this.contribuableId,
    required this.quartierId,
    required this.montant,
    required this.modePayement,
    required this.datePayement,
    this.referenceTransaction,
    this.reference,
    this.contribuableNom,
    this.taxeType,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      taxeId: json['taxe_id'],
      
      communeId: json['commune_id'],
      contribuableId: json['contribuable_id'],
      quartierId: json['quartier_id'],
      montant: double.tryParse(json['montant'].toString()) ?? 0.0, 
      modePayement: json['mode_payement'],
      datePayement: DateTime.parse(json['date_payement']),
      referenceTransaction: json['reference_transaction'],
      reference: json['reference'],
      contribuableNom: json['contribuable'] != null ? json['contribuable']['nom'] : null,
      taxeType: json['taxe'] != null && json['taxe']['type_taxe'] != null ? json['taxe']['type_taxe']['nom'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'taxe_id': taxeId,
  
      'commune_id': communeId,
      'contribuable_id': contribuableId,
      'quartier_id': quartierId,
      'montant': montant,
      'mode_payement': modePayement,
      'date_payement': datePayement.toIso8601String().split('T')[0],
      'reference_transaction': referenceTransaction,
      'reference': reference,
    };
  }
}
