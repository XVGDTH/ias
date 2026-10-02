/// Équivalent d'une ligne de "Historique des paiements" (CDC 3.3.1) —
/// générée automatiquement à chaque création/renouvellement d'abonnement.
class Paiement {
  final String date; // AAAA-MM-JJ
  final double montant;
  final String modePaiement; // Espèces / Mobile Money / Virement / Autre
  final String duree; // Mensuel / Trimestriel / Annuel

  Paiement({
    required this.date,
    required this.montant,
    required this.modePaiement,
    required this.duree,
  });

  Map<String, dynamic> toMap() => {
    'date': date,
    'montant': montant,
    'mode_paiement': modePaiement,
    'duree': duree,
  };

  factory Paiement.fromMap(Map map) => Paiement(
    date: map['date'] as String? ?? '',
    montant: (map['montant'] as num?)?.toDouble() ?? 0,
    modePaiement: map['mode_paiement'] as String? ?? '',
    duree: map['duree'] as String? ?? '',
  );
}
