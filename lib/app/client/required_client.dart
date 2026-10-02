class Client {
  final String id;
  final String nom;
  final String typeClient;
  final String telephone;
  final String email;
  final String ville;
  final String pays;
  final String adresse;
  final String notes;
  final String statut;
  final String dateEntree;
  final bool fidele;

  Client({
    required this.id,
    required this.nom,
    this.typeClient = '',
    this.telephone = '',
    this.email = '',
    this.ville = '',
    this.pays = '',
    this.adresse = '',
    this.notes = '',
    required this.statut,
    this.dateEntree = '',
    this.fidele = false,
  });

  Client copyWith({
    String? nom,
    String? typeClient,
    String? telephone,
    String? email,
    String? ville,
    String? pays,
    String? adresse,
    String? notes,
    String? statut,
    bool? fidele,
  }) {
    return Client(
      id: id,
      nom: nom ?? this.nom,
      typeClient: typeClient ?? this.typeClient,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      adresse: adresse ?? this.adresse,
      notes: notes ?? this.notes,
      statut: statut ?? this.statut,
      dateEntree: dateEntree,
      fidele: fidele ?? this.fidele,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'type_client': typeClient,
    'telephone': telephone,
    'email': email,
    'ville': ville,
    'pays': pays,
    'adresse': adresse,
    'notes': notes,
    'statut': statut,
    'date_entree': dateEntree,
    'fidele': fidele,
  };

  factory Client.fromMap(Map map) => Client(
    id: map['id'] as String,
    nom: map['nom'] as String? ?? '',
    typeClient: map['type_client'] as String? ?? '',
    telephone: map['telephone'] as String? ?? '',
    email: map['email'] as String? ?? '',
    ville: map['ville'] as String? ?? '',
    pays: map['pays'] as String? ?? '',
    adresse: map['adresse'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    statut: map['statut'] as String? ?? 'Actif',
    dateEntree: map['date_entree'] as String? ?? '',
    fidele: map['fidele'] as bool? ?? false,
  );
}
