/// Équivalent d'un "identifiant d'équipement configuré chez un client" (CDC 3.2.3).
/// Modèle unique utilisé par ConfigurerEquipementPage, FicheClientPage,
/// DetailEquipementClientPage et la future vue globale des identifiants.
class Identifiant {
  final String id;
  final String clientId;
  final String clientNom;
  final String equipementId;
  final String equipementNom;
  final String numeroSerie;
  final String dateConfig;
  final String adresseIp;
  final String nomSsid;
  final String loginAdmin;
  final String membreLogin;
  final String codeMembre;
  final String statut; // En service / En panne / Retourné / Remplacement
  final String notes;

  Identifiant({
    required this.id,
    required this.clientId,
    required this.clientNom,
    required this.equipementId,
    required this.equipementNom,
    required this.numeroSerie,
    required this.dateConfig,
    this.adresseIp = '',
    this.nomSsid = '',
    this.loginAdmin = '',
    this.membreLogin = '',
    this.codeMembre = '',
    this.statut = 'En service',
    this.notes = '',
  });

  Identifiant copyWith({
    String? numeroSerie,
    String? adresseIp,
    String? nomSsid,
    String? loginAdmin,
    String? membreLogin,
    String? codeMembre,
    String? statut,
    String? notes,
  }) {
    return Identifiant(
      id: id,
      clientId: clientId,
      clientNom: clientNom,
      equipementId: equipementId,
      equipementNom: equipementNom,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      dateConfig: dateConfig,
      adresseIp: adresseIp ?? this.adresseIp,
      nomSsid: nomSsid ?? this.nomSsid,
      loginAdmin: loginAdmin ?? this.loginAdmin,
      membreLogin: membreLogin ?? this.membreLogin,
      codeMembre: codeMembre ?? this.codeMembre,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'client_id': clientId,
    'client_nom': clientNom,
    'equipement_id': equipementId,
    'equipement_nom': equipementNom,
    'numero_serie': numeroSerie,
    'date_config': dateConfig,
    'adresse_ip': adresseIp,
    'nom_ssid': nomSsid,
    'login_admin': loginAdmin,
    'membre_login': membreLogin,
    'code_membre': codeMembre,
    'statut': statut,
    'notes': notes,
  };

  factory Identifiant.fromMap(Map map) => Identifiant(
    id: map['id'] as String,
    clientId: map['client_id'] as String? ?? '',
    clientNom: map['client_nom'] as String? ?? '',
    equipementId: map['equipement_id'] as String? ?? '',
    equipementNom: map['equipement_nom'] as String? ?? '',
    numeroSerie: map['numero_serie'] as String? ?? '',
    dateConfig: map['date_config'] as String? ?? '',
    adresseIp: map['adresse_ip'] as String? ?? '',
    nomSsid: map['nom_ssid'] as String? ?? '',
    loginAdmin: map['login_admin'] as String? ?? '',
    membreLogin: map['membre_login'] as String? ?? '',
    codeMembre: map['code_membre'] as String? ?? '',
    statut: map['statut'] as String? ?? 'En service',
    notes: map['notes'] as String? ?? '',
  );
}
