class Mouvement {
  final String id;
  final String equipementId;
  final String equipementNom;
  final String typeMouvement; // 'Entree' | 'Sortie'
  final int quantite;
  final double prixUnitaire;
  final String fournisseur;
  final String clientId;
  final String clientNom;
  final String dateMouvement; // format AAAA-MM-JJ
  final String notes;
  final String
  auteur; // qui a fait le mouvement (CDC 3.2.2 : "traçable, qui a fait l'entrée")

  Mouvement({
    required this.id,
    required this.equipementId,
    required this.equipementNom,
    required this.typeMouvement,
    required this.quantite,
    this.prixUnitaire = 0,
    this.fournisseur = '',
    this.clientId = '',
    this.clientNom = '',
    required this.dateMouvement,
    this.notes = '',
    this.auteur = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'equipement_id': equipementId,
    'equipement_nom': equipementNom,
    'type_mouvement': typeMouvement,
    'quantite': quantite,
    'prix_unitaire': prixUnitaire,
    'fournisseur': fournisseur,
    'client_id': clientId,
    'client_nom': clientNom,
    'date_mouvement': dateMouvement,
    'notes': notes,
    'auteur': auteur,
  };

  factory Mouvement.fromMap(Map map) => Mouvement(
    id: map['id'] as String,
    equipementId: map['equipement_id'] as String? ?? '',
    equipementNom: map['equipement_nom'] as String? ?? '',
    typeMouvement: map['type_mouvement'] as String? ?? 'Entree',
    quantite: (map['quantite'] as num?)?.toInt() ?? 0,
    prixUnitaire: (map['prix_unitaire'] as num?)?.toDouble() ?? 0,
    fournisseur: map['fournisseur'] as String? ?? '',
    clientId: map['client_id'] as String? ?? '',
    clientNom: map['client_nom'] as String? ?? '',
    dateMouvement: map['date_mouvement'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    auteur: map['auteur'] as String? ?? '',
  );
}
