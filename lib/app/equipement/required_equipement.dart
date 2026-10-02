class Equipement {
  final String id;
  final String nom;
  final String marque;
  final String categorie;
  final double prixAchat;
  final double prixVente;
  final int stock;
  final int seuilAlerte;
  final String description;

  Equipement({
    required this.id,
    required this.nom,
    this.marque = '',
    required this.categorie,
    this.prixAchat = 0,
    this.prixVente = 0,
    this.stock = 0,
    this.seuilAlerte = 0,
    this.description = '',
  });

  Equipement copyWith({int? stock}) {
    return Equipement(
      id: id,
      nom: nom,
      marque: marque,
      categorie: categorie,
      prixAchat: prixAchat,
      prixVente: prixVente,
      stock: stock ?? this.stock,
      seuilAlerte: seuilAlerte,
      description: description,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'marque': marque,
    'categorie': categorie,
    'prix_achat': prixAchat,
    'prix_vente': prixVente,
    'stock': stock,
    'seuil_alerte': seuilAlerte,
    'description': description,
  };

  factory Equipement.fromMap(Map map) => Equipement(
    id: map['id'] as String,
    nom: map['nom'] as String? ?? '',
    marque: map['marque'] as String? ?? '',
    categorie: map['categorie'] as String? ?? 'Autre',
    prixAchat: (map['prix_achat'] as num?)?.toDouble() ?? 0,
    prixVente: (map['prix_vente'] as num?)?.toDouble() ?? 0,
    stock: (map['stock'] as num?)?.toInt() ?? 0,
    seuilAlerte: (map['seuil_alerte'] as num?)?.toInt() ?? 0,
    description: map['description'] as String? ?? '',
  );
}
