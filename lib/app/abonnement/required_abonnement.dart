import 'package:ias/app/paiment/paimenent.dart';

class Abonnement {
  final String id;
  final String clientId;
  final String clientNom;
  final String kitId;
  final String dateDebut;
  final String dateFin;
  final String duree;
  final String statutAbonnement;
  final String statutPaiement;
  final double montant;
  final String notes;
  final List<Paiement> historiquePaiements;

  Abonnement({
    required this.id,
    required this.clientId,
    required this.clientNom,
    required this.kitId,
    required this.dateDebut,
    required this.dateFin,
    required this.duree,
    required this.statutAbonnement,
    required this.statutPaiement,
    required this.montant,
    this.notes = '',
    this.historiquePaiements = const [],
  });

  Abonnement copyWith({
    String? dateDebut,
    String? dateFin,
    String? duree,
    String? statutAbonnement,
    String? statutPaiement,
    double? montant,
    String? notes,
    List<Paiement>? historiquePaiements,
  }) {
    return Abonnement(
      id: id,
      clientId: clientId,
      clientNom: clientNom,
      kitId: kitId,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      duree: duree ?? this.duree,
      statutAbonnement: statutAbonnement ?? this.statutAbonnement,
      statutPaiement: statutPaiement ?? this.statutPaiement,
      montant: montant ?? this.montant,
      notes: notes ?? this.notes,
      historiquePaiements: historiquePaiements ?? this.historiquePaiements,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'client_id': clientId,
    'client_nom': clientNom,
    'kit_id': kitId,
    'date_debut': dateDebut,
    'date_fin': dateFin,
    'duree': duree,
    'statut_abonnement': statutAbonnement,
    'statut_paiement': statutPaiement,
    'montant': montant,
    'notes': notes,
    'historique_paiements': historiquePaiements.map((p) => p.toMap()).toList(),
  };

  factory Abonnement.fromMap(Map map) => Abonnement(
    id: map['id'] as String,
    clientId: map['client_id'] as String? ?? '',
    clientNom: map['client_nom'] as String? ?? '',
    kitId: map['kit_id'] as String? ?? '',
    dateDebut: map['date_debut'] as String? ?? '',
    dateFin: map['date_fin'] as String? ?? '',
    duree: map['duree'] as String? ?? 'Mensuel',
    statutAbonnement: map['statut_abonnement'] as String? ?? 'Actif',
    statutPaiement: map['statut_paiement'] as String? ?? 'Payé',
    montant: (map['montant'] as num?)?.toDouble() ?? 0,
    notes: map['notes'] as String? ?? '',
    historiquePaiements: ((map['historique_paiements'] as List?) ?? [])
        .map((p) => Paiement.fromMap(Map<String, dynamic>.from(p as Map)))
        .toList(),
  );
}
