/// Équivalent de joursRestants(dateFin) — retourne le nombre de jours restants
/// (peut être négatif si déjà expiré). Logique fidèle à abonnementService.js.
int? joursRestants(String? dateFin) {
  if (dateFin == null || dateFin.isEmpty) return null;
  final fin = DateTime.tryParse(dateFin);
  if (fin == null) return null;
  final aujourdHui = DateTime.now();
  final finSansHeure = DateTime(fin.year, fin.month, fin.day);
  final today = DateTime(aujourdHui.year, aujourdHui.month, aujourdHui.day);
  return finSansHeure.difference(today).inDays;
}

/// Équivalent de niveauAlerte(dateFin, statutAbonnement)
/// -> 'expire' | 'critique' | 'prioritaire' | 'attention' | null
String? niveauAlerte(String? dateFin, String? statutAbonnement) {
  if (statutAbonnement == 'Résilié') return null;
  final jours = joursRestants(dateFin);
  if (jours == null) return null;
  if (jours < 0) return 'expire';
  if (jours <= 1) return 'critique';
  if (jours <= 3) return 'prioritaire';
  if (jours <= 7) return 'attention';
  return null;
}

/// Équivalent de calculerDateFin(dateDebut, duree) — 'Mensuel' | 'Trimestriel' | 'Annuel'
String calculerDateFin(String dateDebut, String duree) {
  final debut = DateTime.tryParse(dateDebut) ?? DateTime.now();
  DateTime fin;
  switch (duree) {
    case 'Trimestriel':
      fin = DateTime(debut.year, debut.month + 3, debut.day);
      break;
    case 'Annuel':
      fin = DateTime(debut.year + 1, debut.month, debut.day);
      break;
    case 'Mensuel':
    default:
      fin = DateTime(debut.year, debut.month + 1, debut.day);
  }
  return '${fin.year.toString().padLeft(4, '0')}-${fin.month.toString().padLeft(2, '0')}-${fin.day.toString().padLeft(2, '0')}';
}

/// Équivalent de formaterDate() — date du jour au format AAAA-MM-JJ
String formaterDate([DateTime? date]) {
  final d = date ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
