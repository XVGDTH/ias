// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:ias/app/abonnement/required_abonnement.dart';
// import 'package:ias/app/abonnement/utils_abonnement.dart';
// import 'package:ias/app/client/required_client.dart';
// import 'package:ias/app/equipement/required_equipement.dart';
// import 'package:ias/app/identifiant/identifiant.dart';
// import 'package:ias/app/mouvement_stock/required_mouvement.dart';
// import 'package:ias/app/paiment/paimenent.dart';

// /// Stockage LOCAL persistant (Hive — base NoSQL embarquée), en attendant que
// /// ton backend soit prêt. Tant que tu n'as pas branché ta propre API, TOUTES
// /// les pages lisent/écrivent ici — les données survivent donc aux hot
// /// restarts et aux fermetures de l'app (contrairement aux TODO précédents
// /// qui repartaient de zéro à chaque chargement).
// ///
// /// Quand ton backend sera prêt : remplace les appels `LocalStore.xxx(...)`
// /// dans chaque page par tes appels HTTP — la signature de chaque méthode a
// /// été pensée pour correspondre à ce que faisaient les services React
// /// (clientService.js, equipementsService.js, abonnementService.js) que tu
// /// m'avais donnés, donc le remplacement doit rester direct.
// class LocalStore {
//   LocalStore._();

//   static const _boxClients = 'clients';
//   static const _boxEquipements = 'equipements';
//   static const _boxMouvements = 'mouvements';
//   static const _boxIdentifiants = 'identifiants';
//   static const _boxAbonnements = 'abonnements';

//   static bool _initialise = false;

//   /// À appeler une seule fois, avant runApp().
//   static Future<void> init() async {
//     if (_initialise) return;
//     await Hive.initFlutter();
//     await Hive.openBox(_boxClients);
//     await Hive.openBox(_boxEquipements);
//     await Hive.openBox(_boxMouvements);
//     await Hive.openBox(_boxIdentifiants);
//     await Hive.openBox(_boxAbonnements);
//     _initialise = true;
//   }

//   static Box get _clients => Hive.box(_boxClients);
//   static Box get _equipements => Hive.box(_boxEquipements);
//   static Box get _mouvements => Hive.box(_boxMouvements);
//   static Box get _identifiants => Hive.box(_boxIdentifiants);
//   static Box get _abonnements => Hive.box(_boxAbonnements);

//   /// Génère un identifiant unique simple (suffisant en local ; ton backend
//   /// utilisera probablement un UUID ou un id auto-incrémenté en base).
//   static String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

//   // ===========================================================
//   // CLIENTS — équivalent de clientService.js
//   // ===========================================================

//   static Future<List<Client>> getClients() async {
//     return _clients.values
//         .map((m) => Client.fromMap(Map<String, dynamic>.from(m as Map)))
//         .toList()
//       ..sort((a, b) => b.dateEntree.compareTo(a.dateEntree));
//   }

//   static Future<Client?> getClientById(String id) async {
//     final m = _clients.get(id);
//     if (m == null) return null;
//     return Client.fromMap(Map<String, dynamic>.from(m as Map));
//   }

//   static Future<List<Client>> searchClients(String terme) async {
//     final t = terme.toLowerCase();
//     final tous = await getClients();
//     return tous
//         .where(
//           (c) =>
//               c.nom.toLowerCase().contains(t) ||
//               c.telephone.toLowerCase().contains(t) ||
//               c.ville.toLowerCase().contains(t) ||
//               c.pays.toLowerCase().contains(t),
//         )
//         .toList();
//   }

//   static Future<List<Client>> filterClients({
//     String pays = '',
//     String ville = '',
//     String statut = '',
//   }) async {
//     final tous = await getClients();
//     return tous.where((c) {
//       final matchPays =
//           pays.isEmpty || c.pays.toLowerCase() == pays.toLowerCase();
//       final matchVille =
//           ville.isEmpty || c.ville.toLowerCase() == ville.toLowerCase();
//       final matchStatut = statut.isEmpty || c.statut == statut;
//       return matchPays && matchVille && matchStatut;
//     }).toList();
//   }

//   static Future<Client> addClient({
//     required String nom,
//     String typeClient = 'Particulier',
//     String telephone = '',
//     String email = '',
//     String ville = '',
//     String pays = '',
//     String adresse = '',
//     String notes = '',
//     String statut = 'Actif',
//   }) async {
//     final client = Client(
//       id: _genId(),
//       nom: nom,
//       typeClient: typeClient,
//       telephone: telephone,
//       email: email,
//       ville: ville,
//       pays: pays,
//       adresse: adresse,
//       notes: notes,
//       statut: statut,
//       dateEntree: formaterDate(),
//       fidele: false,
//     );
//     await _clients.put(client.id, client.toMap());
//     return client;
//   }

//   static Future<Client> updateClient(String id, Client client) async {
//     await _clients.put(id, client.toMap());
//     return client;
//   }

//   /// Équivalent de "Archiver ou désactiver un client" (CDC 3.1.2) —
//   /// jamais de suppression définitive, juste un changement de statut.
//   static Future<void> archiverClient(String id) async {
//     final client = await getClientById(id);
//     if (client == null) return;
//     await updateClient(id, client.copyWith(statut: 'Inactif'));
//   }

//   static Future<void> deleteClient(String id) async {
//     await _clients.delete(id);
//   }

//   // ===========================================================
//   // ÉQUIPEMENTS (catalogue) — équivalent de equipementsService.js
//   // ===========================================================

//   static Future<List<Equipement>> getEquipements() async {
//     return _equipements.values
//         .map((m) => Equipement.fromMap(Map<String, dynamic>.from(m as Map)))
//         .toList();
//   }

//   static Future<Equipement?> getEquipementById(String id) async {
//     final m = _equipements.get(id);
//     if (m == null) return null;
//     return Equipement.fromMap(Map<String, dynamic>.from(m as Map));
//   }

//   static Future<Equipement> addEquipement({
//     required String nom,
//     required String categorie,
//     String marque = '',
//     double prixAchat = 0,
//     double prixVente = 0,
//     int seuilAlerte = 0,
//     String description = '',
//   }) async {
//     final eq = Equipement(
//       id: _genId(),
//       nom: nom,
//       categorie: categorie,
//       marque: marque,
//       prixAchat: prixAchat,
//       prixVente: prixVente,
//       stock:
//           0, // le stock démarre à 0, il se remplit via les entrées (comme dans equipementsService.js)
//       seuilAlerte: seuilAlerte,
//       description: description,
//     );
//     await _equipements.put(eq.id, eq.toMap());
//     return eq;
//   }

//   static Future<Equipement> updateEquipement(Equipement equipement) async {
//     await _equipements.put(equipement.id, equipement.toMap());
//     return equipement;
//   }

//   /// Ajuste le stock d'un équipement (utilisé après chaque mouvement).
//   static Future<int> ajusterStock(String equipementId, int delta) async {
//     final eq = await getEquipementById(equipementId);
//     if (eq == null) return 0;
//     final nouveauStock = (eq.stock + delta).clamp(0, 1 << 31);
//     await updateEquipement(eq.copyWith(stock: nouveauStock));
//     return nouveauStock;
//   }

//   // ===========================================================
//   // MOUVEMENTS DE STOCK — équivalent de equipementsService.js
//   // ===========================================================

//   static Future<List<Mouvement>> getMouvementsStock() async {
//     final tous = _mouvements.values
//         .map((m) => Mouvement.fromMap(Map<String, dynamic>.from(m as Map)))
//         .toList();
//     tous.sort((a, b) => b.dateMouvement.compareTo(a.dateMouvement));
//     return tous;
//   }

//   static Future<void> enregistrerEntree({
//     required String equipementId,
//     required String equipementNom,
//     required int quantite,
//     double prixUnitaire = 0,
//     String fournisseur = '',
//     String notes = '',
//     String auteur = '',
//   }) async {
//     final mvt = Mouvement(
//       id: _genId(),
//       equipementId: equipementId,
//       equipementNom: equipementNom,
//       typeMouvement: 'Entree',
//       quantite: quantite,
//       prixUnitaire: prixUnitaire,
//       fournisseur: fournisseur,
//       dateMouvement: formaterDate(),
//       notes: notes,
//       auteur: auteur,
//     );
//     await _mouvements.put(mvt.id, mvt.toMap());
//     await ajusterStock(equipementId, quantite);
//   }

//   static Future<void> enregistrerSortie({
//     required String equipementId,
//     required String equipementNom,
//     required int quantite,
//     double prixUnitaire = 0,
//     String clientId = '',
//     String clientNom = '',
//     String notes = '',
//     String auteur = '',
//   }) async {
//     final mvt = Mouvement(
//       id: _genId(),
//       equipementId: equipementId,
//       equipementNom: equipementNom,
//       typeMouvement: 'Sortie',
//       quantite: quantite,
//       prixUnitaire: prixUnitaire,
//       clientId: clientId,
//       clientNom: clientNom,
//       dateMouvement: formaterDate(),
//       notes: notes,
//       auteur: auteur,
//     );
//     await _mouvements.put(mvt.id, mvt.toMap());
//     await ajusterStock(equipementId, -quantite);
//   }

//   // ===========================================================
//   // IDENTIFIANTS CONFIGURÉS — équivalent de equipementsService.js
//   // ===========================================================

//   static Future<List<Identifiant>> getIdentifiants() async {
//     final tous = _identifiants.values
//         .map((m) => Identifiant.fromMap(Map<String, dynamic>.from(m as Map)))
//         .toList();
//     tous.sort((a, b) => b.dateConfig.compareTo(a.dateConfig));
//     return tous;
//   }

//   static Future<List<Identifiant>> getIdentifiantsParClient(
//     String clientId,
//   ) async {
//     final tous = await getIdentifiants();
//     return tous.where((i) => i.clientId == clientId).toList();
//   }

//   static Future<Identifiant?> getIdentifiantById(String id) async {
//     final m = _identifiants.get(id);
//     if (m == null) return null;
//     return Identifiant.fromMap(Map<String, dynamic>.from(m as Map));
//   }

//   /// Recherche par numéro de série, client ou statut (CDC 3.2.4).
//   static Future<List<Identifiant>> rechercherIdentifiants({
//     String terme = '',
//     String statut = '',
//   }) async {
//     final tous = await getIdentifiants();
//     final t = terme.toLowerCase();
//     return tous.where((i) {
//       final matchTerme =
//           t.isEmpty ||
//           i.numeroSerie.toLowerCase().contains(t) ||
//           i.clientNom.toLowerCase().contains(t) ||
//           i.equipementNom.toLowerCase().contains(t);
//       final matchStatut = statut.isEmpty || i.statut == statut;
//       return matchTerme && matchStatut;
//     }).toList();
//   }

//   static Future<Identifiant> ajouterIdentifiant({
//     required String clientId,
//     required String clientNom,
//     required String equipementId,
//     required String equipementNom,
//     required String numeroSerie,
//     String adresseIp = '',
//     String nomSsid = '',
//     String loginAdmin = '',
//     String membreLogin = '',
//     String codeMembre = '',
//     String statut = 'En service',
//     String notes = '',
//   }) async {
//     final identifiant = Identifiant(
//       id: _genId(),
//       clientId: clientId,
//       clientNom: clientNom,
//       equipementId: equipementId,
//       equipementNom: equipementNom,
//       numeroSerie: numeroSerie,
//       dateConfig: formaterDate(),
//       adresseIp: adresseIp,
//       nomSsid: nomSsid,
//       loginAdmin: loginAdmin,
//       membreLogin: membreLogin,
//       codeMembre: codeMembre,
//       statut: statut,
//       notes: notes,
//     );
//     await _identifiants.put(identifiant.id, identifiant.toMap());
//     return identifiant;
//   }

//   static Future<Identifiant> updateIdentifiant(Identifiant identifiant) async {
//     await _identifiants.put(identifiant.id, identifiant.toMap());
//     return identifiant;
//   }

//   // ===========================================================
//   // ABONNEMENTS — équivalent de abonnementService.js
//   // ===========================================================

//   static Future<List<Abonnement>> getAbonnements() async {
//     final tous = _abonnements.values
//         .map((m) => Abonnement.fromMap(Map<String, dynamic>.from(m as Map)))
//         .toList();
//     tous.sort((a, b) => a.dateFin.compareTo(b.dateFin));
//     return tous;
//   }

//   static Future<List<Abonnement>> getAbonnementsParClient(
//     String clientId,
//   ) async {
//     final tous = await getAbonnements();
//     return tous.where((a) => a.clientId == clientId).toList();
//   }

//   static Future<Abonnement?> getAbonnementById(String id) async {
//     final m = _abonnements.get(id);
//     if (m == null) return null;
//     return Abonnement.fromMap(Map<String, dynamic>.from(m as Map));
//   }

//   static Future<Abonnement> addAbonnement({
//     required String clientId,
//     required String clientNom,
//     required String kitId,
//     required String dateDebut,
//     required String duree,
//     required double montant,
//     String statutPaiement = 'Payé',
//   }) async {
//     final dateFin = calculerDateFin(dateDebut, duree);
//     final abonnement = Abonnement(
//       id: _genId(),
//       clientId: clientId,
//       clientNom: clientNom,
//       kitId: kitId,
//       dateDebut: dateDebut,
//       dateFin: dateFin,
//       duree: duree,
//       statutAbonnement: 'Actif',
//       statutPaiement: statutPaiement,
//       montant: montant,
//       historiquePaiements: [
//         Paiement(
//           date: formaterDate(),
//           montant: montant,
//           modePaiement: 'Non précisé',
//           duree: duree,
//         ),
//       ],
//     );
//     await _abonnements.put(abonnement.id, abonnement.toMap());
//     return abonnement;
//   }

//   static Future<Abonnement> updateAbonnement(Abonnement abonnement) async {
//     await _abonnements.put(abonnement.id, abonnement.toMap());
//     return abonnement;
//   }

//   /// Équivalent de renouvelerAbonnement() — nouvelle date de fin, montant,
//   /// mode de paiement (CDC 3.3.3), et ajout à l'historique des paiements.
//   static Future<Abonnement?> renouvelerAbonnement(
//     String id, {
//     required String duree,
//     required double montant,
//     required String modePaiement,
//     String statutPaiement = 'Payé',
//   }) async {
//     final abonnement = await getAbonnementById(id);
//     if (abonnement == null) return null;

//     final jours = joursRestants(abonnement.dateFin);
//     final dateDepart = (jours != null && jours > 0)
//         ? abonnement.dateFin
//         : formaterDate();
//     final nouvelleDateFin = calculerDateFin(dateDepart, duree);

//     final nouvelHistorique = [
//       ...abonnement.historiquePaiements,
//       Paiement(
//         date: formaterDate(),
//         montant: montant,
//         modePaiement: modePaiement,
//         duree: duree,
//       ),
//     ];

//     final maj = abonnement.copyWith(
//       dateFin: nouvelleDateFin,
//       duree: duree,
//       montant: montant,
//       statutPaiement: statutPaiement,
//       statutAbonnement: 'Actif',
//       historiquePaiements: nouvelHistorique,
//     );
//     await updateAbonnement(maj);
//     return maj;
//   }

//   // ===========================================================
//   // Aide au calcul de fidélité (CDC 3.1.3 / 3.4.3) — recalcule et
//   // persiste le champ `fidele` de chaque client à partir de ses
//   // équipements configurés et de ses abonnements.
//   // ===========================================================

//   static Future<void> recalculerClientsFideles() async {
//     final clients = await getClients();
//     final identifiants = await getIdentifiants();
//     final abonnements = await getAbonnements();

//     for (final client in clients) {
//       final eqClient = identifiants
//           .where((i) => i.clientId == client.id)
//           .length;
//       final abClient = abonnements
//           .where((a) => a.clientId == client.id)
//           .toList();

//       final abonnementLongueDuree = abClient.any((a) {
//         if (a.statutAbonnement != 'Actif') return false;
//         final debut = DateTime.tryParse(a.dateDebut);
//         if (debut == null) return false;
//         return DateTime.now().difference(debut).inDays / 30 >= 6;
//       });
//       final aucunImpaye = !abClient.any((a) => a.statutPaiement == 'Impayé');
//       final estFidele = (abonnementLongueDuree || eqClient >= 2) && aucunImpaye;

//       if (estFidele != client.fidele) {
//         await updateClient(client.id, client.copyWith(fidele: estFidele));
//       }
//     }
//   }
// }

import 'package:hive_flutter/hive_flutter.dart';
import 'package:ias/app/abonnement/required_abonnement.dart';
import 'package:ias/app/abonnement/utils_abonnement.dart';
import 'package:ias/app/client/required_client.dart';
import 'package:ias/app/equipement/required_equipement.dart';
import 'package:ias/app/identifiant/identifiant.dart';
import 'package:ias/app/mouvement_stock/required_mouvement.dart';
import 'package:ias/app/paiment/paimenent.dart';

/// Stockage LOCAL persistant (Hive — base NoSQL embarquée), en attendant que
/// ton backend soit prêt. Tant que tu n'as pas branché ta propre API, TOUTES
/// les pages lisent/écrivent ici — les données survivent donc aux hot
/// restarts et aux fermetures de l'app (contrairement aux TODO précédents
/// qui repartaient de zéro à chaque chargement).
///
/// Quand ton backend sera prêt : remplace les appels `LocalStore.xxx(...)`
/// dans chaque page par tes appels HTTP — la signature de chaque méthode a
/// été pensée pour correspondre à ce que faisaient les services React
/// (clientService.js, equipementsService.js, abonnementService.js) que tu
/// m'avais donnés, donc le remplacement doit rester direct.
class LocalStore {
  LocalStore._();

  static const _boxClients = 'clients';
  static const _boxEquipements = 'equipements';
  static const _boxMouvements = 'mouvements';
  static const _boxIdentifiants = 'identifiants';
  static const _boxAbonnements = 'abonnements';

  static bool _initialise = false;

  /// À appeler une seule fois, avant runApp().
  static Future<void> init() async {
    if (_initialise) return;
    await Hive.initFlutter();
    await Hive.openBox(_boxClients);
    await Hive.openBox(_boxEquipements);
    await Hive.openBox(_boxMouvements);
    await Hive.openBox(_boxIdentifiants);
    await Hive.openBox(_boxAbonnements);
    _initialise = true;
  }

  static Box get _clients => Hive.box(_boxClients);
  static Box get _equipements => Hive.box(_boxEquipements);
  static Box get _mouvements => Hive.box(_boxMouvements);
  static Box get _identifiants => Hive.box(_boxIdentifiants);
  static Box get _abonnements => Hive.box(_boxAbonnements);

  /// Génère un identifiant unique simple (suffisant en local ; ton backend
  /// utilisera probablement un UUID ou un id auto-incrémenté en base).
  static String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ===========================================================
  // CLIENTS — équivalent de clientService.js
  // ===========================================================

  static Future<List<Client>> getClients() async {
    return _clients.values
        .map((m) => Client.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList()
      ..sort((a, b) => b.dateEntree.compareTo(a.dateEntree));
  }

  static Future<Client?> getClientById(String id) async {
    final m = _clients.get(id);
    if (m == null) return null;
    return Client.fromMap(Map<String, dynamic>.from(m as Map));
  }

  static Future<List<Client>> searchClients(String terme) async {
    final t = terme.toLowerCase();
    final tous = await getClients();
    return tous
        .where(
          (c) =>
              c.nom.toLowerCase().contains(t) ||
              c.telephone.toLowerCase().contains(t) ||
              c.ville.toLowerCase().contains(t) ||
              c.pays.toLowerCase().contains(t),
        )
        .toList();
  }

  static Future<List<Client>> filterClients({
    String pays = '',
    String ville = '',
    String statut = '',
  }) async {
    final tous = await getClients();
    return tous.where((c) {
      final matchPays =
          pays.isEmpty || c.pays.toLowerCase() == pays.toLowerCase();
      final matchVille =
          ville.isEmpty || c.ville.toLowerCase() == ville.toLowerCase();
      final matchStatut = statut.isEmpty || c.statut == statut;
      return matchPays && matchVille && matchStatut;
    }).toList();
  }

  static Future<Client> addClient({
    required String nom,
    String typeClient = 'Particulier',
    String telephone = '',
    String email = '',
    String ville = '',
    String pays = '',
    String adresse = '',
    String notes = '',
    String statut = 'Actif',
  }) async {
    final client = Client(
      id: _genId(),
      nom: nom,
      typeClient: typeClient,
      telephone: telephone,
      email: email,
      ville: ville,
      pays: pays,
      adresse: adresse,
      notes: notes,
      statut: statut,
      dateEntree: formaterDate(),
      fidele: false,
    );
    await _clients.put(client.id, client.toMap());
    return client;
  }

  static Future<Client> updateClient(String id, Client client) async {
    await _clients.put(id, client.toMap());
    return client;
  }

  /// Équivalent de "Archiver ou désactiver un client" (CDC 3.1.2) —
  /// jamais de suppression définitive, juste un changement de statut.
  static Future<void> archiverClient(String id) async {
    final client = await getClientById(id);
    if (client == null) return;
    await updateClient(id, client.copyWith(statut: 'Inactif'));
  }

  static Future<void> deleteClient(String id) async {
    await _clients.delete(id);
  }

  // ===========================================================
  // ÉQUIPEMENTS (catalogue) — équivalent de equipementsService.js
  // ===========================================================

  static Future<List<Equipement>> getEquipements() async {
    return _equipements.values
        .map((m) => Equipement.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  static Future<Equipement?> getEquipementById(String id) async {
    final m = _equipements.get(id);
    if (m == null) return null;
    return Equipement.fromMap(Map<String, dynamic>.from(m as Map));
  }

  static Future<Equipement> addEquipement({
    required String nom,
    required String categorie,
    String marque = '',
    double prixAchat = 0,
    double prixVente = 0,
    int seuilAlerte = 0,
    String description = '',
  }) async {
    final eq = Equipement(
      id: _genId(),
      nom: nom,
      categorie: categorie,
      marque: marque,
      prixAchat: prixAchat,
      prixVente: prixVente,
      stock:
          0, // le stock démarre à 0, il se remplit via les entrées (comme dans equipementsService.js)
      seuilAlerte: seuilAlerte,
      description: description,
    );
    await _equipements.put(eq.id, eq.toMap());
    return eq;
  }

  static Future<Equipement> updateEquipement(Equipement equipement) async {
    await _equipements.put(equipement.id, equipement.toMap());
    return equipement;
  }

  /// Ajuste le stock d'un équipement (utilisé après chaque mouvement).
  static Future<int> ajusterStock(String equipementId, int delta) async {
    final eq = await getEquipementById(equipementId);
    if (eq == null) return 0;
    final nouveauStock = (eq.stock + delta).clamp(0, 1 << 31);
    await updateEquipement(eq.copyWith(stock: nouveauStock));
    return nouveauStock;
  }

  // ===========================================================
  // MOUVEMENTS DE STOCK — équivalent de equipementsService.js
  // ===========================================================

  static Future<List<Mouvement>> getMouvementsStock() async {
    final tous = _mouvements.values
        .map((m) => Mouvement.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    tous.sort((a, b) => b.dateMouvement.compareTo(a.dateMouvement));
    return tous;
  }

  /// Historique des mouvements pour UN équipement du catalogue (utilisé par
  /// la fiche détail équipement — CDC 3.2.2 "visualiser l'historique des entrées").
  static Future<List<Mouvement>> getMouvementsParEquipement(
    String equipementId,
  ) async {
    final tous = await getMouvementsStock();
    return tous.where((m) => m.equipementId == equipementId).toList();
  }

  static Future<void> enregistrerEntree({
    required String equipementId,
    required String equipementNom,
    required int quantite,
    double prixUnitaire = 0,
    String fournisseur = '',
    String notes = '',
    String auteur = '',
  }) async {
    final mvt = Mouvement(
      id: _genId(),
      equipementId: equipementId,
      equipementNom: equipementNom,
      typeMouvement: 'Entree',
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      fournisseur: fournisseur,
      dateMouvement: formaterDate(),
      notes: notes,
      auteur: auteur,
    );
    await _mouvements.put(mvt.id, mvt.toMap());
    await ajusterStock(equipementId, quantite);
  }

  static Future<void> enregistrerSortie({
    required String equipementId,
    required String equipementNom,
    required int quantite,
    double prixUnitaire = 0,
    String clientId = '',
    String clientNom = '',
    String notes = '',
    String auteur = '',
  }) async {
    final mvt = Mouvement(
      id: _genId(),
      equipementId: equipementId,
      equipementNom: equipementNom,
      typeMouvement: 'Sortie',
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      clientId: clientId,
      clientNom: clientNom,
      dateMouvement: formaterDate(),
      notes: notes,
      auteur: auteur,
    );
    await _mouvements.put(mvt.id, mvt.toMap());
    await ajusterStock(equipementId, -quantite);
  }

  // ===========================================================
  // IDENTIFIANTS CONFIGURÉS — équivalent de equipementsService.js
  // ===========================================================

  static Future<List<Identifiant>> getIdentifiants() async {
    final tous = _identifiants.values
        .map((m) => Identifiant.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    tous.sort((a, b) => b.dateConfig.compareTo(a.dateConfig));
    return tous;
  }

  static Future<List<Identifiant>> getIdentifiantsParClient(
    String clientId,
  ) async {
    final tous = await getIdentifiants();
    return tous.where((i) => i.clientId == clientId).toList();
  }

  static Future<Identifiant?> getIdentifiantById(String id) async {
    final m = _identifiants.get(id);
    if (m == null) return null;
    return Identifiant.fromMap(Map<String, dynamic>.from(m as Map));
  }

  /// Recherche par numéro de série, client ou statut (CDC 3.2.4).
  static Future<List<Identifiant>> rechercherIdentifiants({
    String terme = '',
    String statut = '',
  }) async {
    final tous = await getIdentifiants();
    final t = terme.toLowerCase();
    return tous.where((i) {
      final matchTerme =
          t.isEmpty ||
          i.numeroSerie.toLowerCase().contains(t) ||
          i.clientNom.toLowerCase().contains(t) ||
          i.equipementNom.toLowerCase().contains(t);
      final matchStatut = statut.isEmpty || i.statut == statut;
      return matchTerme && matchStatut;
    }).toList();
  }

  static Future<Identifiant> ajouterIdentifiant({
    required String clientId,
    required String clientNom,
    required String equipementId,
    required String equipementNom,
    required String numeroSerie,
    String adresseIp = '',
    String nomSsid = '',
    String loginAdmin = '',
    String membreLogin = '',
    String codeMembre = '',
    String statut = 'En service',
    String notes = '',
  }) async {
    final identifiant = Identifiant(
      id: _genId(),
      clientId: clientId,
      clientNom: clientNom,
      equipementId: equipementId,
      equipementNom: equipementNom,
      numeroSerie: numeroSerie,
      dateConfig: formaterDate(),
      adresseIp: adresseIp,
      nomSsid: nomSsid,
      loginAdmin: loginAdmin,
      membreLogin: membreLogin,
      codeMembre: codeMembre,
      statut: statut,
      notes: notes,
    );
    await _identifiants.put(identifiant.id, identifiant.toMap());
    return identifiant;
  }

  static Future<Identifiant> updateIdentifiant(Identifiant identifiant) async {
    await _identifiants.put(identifiant.id, identifiant.toMap());
    return identifiant;
  }

  // ===========================================================
  // ABONNEMENTS — équivalent de abonnementService.js
  // ===========================================================

  static Future<List<Abonnement>> getAbonnements() async {
    final tous = _abonnements.values
        .map((m) => Abonnement.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    tous.sort((a, b) => a.dateFin.compareTo(b.dateFin));
    return tous;
  }

  static Future<List<Abonnement>> getAbonnementsParClient(
    String clientId,
  ) async {
    final tous = await getAbonnements();
    return tous.where((a) => a.clientId == clientId).toList();
  }

  static Future<Abonnement?> getAbonnementById(String id) async {
    final m = _abonnements.get(id);
    if (m == null) return null;
    return Abonnement.fromMap(Map<String, dynamic>.from(m as Map));
  }

  static Future<Abonnement> addAbonnement({
    required String clientId,
    required String clientNom,
    required String kitId,
    required String dateDebut,
    required String duree,
    required double montant,
    String statutPaiement = 'Payé',
  }) async {
    final dateFin = calculerDateFin(dateDebut, duree);
    final abonnement = Abonnement(
      id: _genId(),
      clientId: clientId,
      clientNom: clientNom,
      kitId: kitId,
      dateDebut: dateDebut,
      dateFin: dateFin,
      duree: duree,
      statutAbonnement: 'Actif',
      statutPaiement: statutPaiement,
      montant: montant,
      historiquePaiements: [
        Paiement(
          date: formaterDate(),
          montant: montant,
          modePaiement: 'Non précisé',
          duree: duree,
        ),
      ],
    );
    await _abonnements.put(abonnement.id, abonnement.toMap());
    return abonnement;
  }

  static Future<Abonnement> updateAbonnement(Abonnement abonnement) async {
    await _abonnements.put(abonnement.id, abonnement.toMap());
    return abonnement;
  }

  /// Équivalent de renouvelerAbonnement() — nouvelle date de fin, montant,
  /// mode de paiement (CDC 3.3.3), et ajout à l'historique des paiements.
  static Future<Abonnement?> renouvelerAbonnement(
    String id, {
    required String duree,
    required double montant,
    required String modePaiement,
    String statutPaiement = 'Payé',
  }) async {
    final abonnement = await getAbonnementById(id);
    if (abonnement == null) return null;

    final jours = joursRestants(abonnement.dateFin);
    final dateDepart = (jours != null && jours > 0)
        ? abonnement.dateFin
        : formaterDate();
    final nouvelleDateFin = calculerDateFin(dateDepart, duree);

    final nouvelHistorique = [
      ...abonnement.historiquePaiements,
      Paiement(
        date: formaterDate(),
        montant: montant,
        modePaiement: modePaiement,
        duree: duree,
      ),
    ];

    final maj = abonnement.copyWith(
      dateFin: nouvelleDateFin,
      duree: duree,
      montant: montant,
      statutPaiement: statutPaiement,
      statutAbonnement: 'Actif',
      historiquePaiements: nouvelHistorique,
    );
    await updateAbonnement(maj);
    return maj;
  }

  // ===========================================================
  // Aide au calcul de fidélité (CDC 3.1.3 / 3.4.3) — recalcule et
  // persiste le champ `fidele` de chaque client à partir de ses
  // équipements configurés et de ses abonnements.
  // ===========================================================

  static Future<void> recalculerClientsFideles() async {
    final clients = await getClients();
    final identifiants = await getIdentifiants();
    final abonnements = await getAbonnements();

    for (final client in clients) {
      final eqClient = identifiants
          .where((i) => i.clientId == client.id)
          .length;
      final abClient = abonnements
          .where((a) => a.clientId == client.id)
          .toList();

      final abonnementLongueDuree = abClient.any((a) {
        if (a.statutAbonnement != 'Actif') return false;
        final debut = DateTime.tryParse(a.dateDebut);
        if (debut == null) return false;
        return DateTime.now().difference(debut).inDays / 30 >= 6;
      });
      final aucunImpaye = !abClient.any((a) => a.statutPaiement == 'Impayé');
      final estFidele = (abonnementLongueDuree || eqClient >= 2) && aucunImpaye;

      if (estFidele != client.fidele) {
        await updateClient(client.id, client.copyWith(fidele: estFidele));
      }
    }
  }
}
