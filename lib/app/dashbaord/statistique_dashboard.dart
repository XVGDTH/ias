import 'package:ias/app/abonnement/required_abonnement.dart';
import 'package:ias/app/abonnement/utils_abonnement.dart';
import 'package:ias/app/client/required_client.dart';
import 'package:ias/app/equipement/required_equipement.dart';
import 'package:ias/app/mouvement_stock/required_mouvement.dart';

class StatsClients {
  final int total;
  final int actifs;
  final int inactifs;
  final int nouveauxCeMois;
  final Map<String, int> parPays;
  final List<Client> fideles;
  StatsClients({
    required this.total,
    required this.actifs,
    required this.inactifs,
    required this.nouveauxCeMois,
    required this.parPays,
    required this.fideles,
  });
}

class StatsEquipements {
  final int total;
  final List<Equipement> stockFaible;
  final Map<String, int> parCategorie;
  final int entreesCeMois;
  final int sortiesCeMois;
  StatsEquipements({
    required this.total,
    required this.stockFaible,
    required this.parCategorie,
    required this.entreesCeMois,
    required this.sortiesCeMois,
  });
}

class StatsAbonnements {
  final int total;
  final int actifs;
  final int expires;
  final List<Abonnement> alertesSemaine;
  StatsAbonnements({
    required this.total,
    required this.actifs,
    required this.expires,
    required this.alertesSemaine,
  });
}

class StatsRevenus {
  final double abonnementsMois;
  final double ventesMois;
  final double total;
  StatsRevenus({
    required this.abonnementsMois,
    required this.ventesMois,
    required this.total,
  });
}

class StatistiquesDashboard {
  final StatsClients clients;
  final StatsEquipements equipements;
  final StatsAbonnements abonnements;
  final StatsRevenus revenus;
  StatistiquesDashboard({
    required this.clients,
    required this.equipements,
    required this.abonnements,
    required this.revenus,
  });
}

/// Équivalent de estFidele(client, equipementsClient, abonnementsClient)
bool estFidele(
  List<Equipement> equipementsClient,
  List<Abonnement> abonnementsClient,
) {
  final abonnementLongueDuree = abonnementsClient.any((ab) {
    if (ab.statutAbonnement != 'Actif') return false;
    final debut = DateTime.tryParse(ab.dateDebut);
    if (debut == null) return false;
    final moisEcoules = DateTime.now().difference(debut).inDays / 30;
    return moisEcoules >= 6;
  });

  final deuxEquipements = equipementsClient.length >= 2;
  final aucunImpaye = !abonnementsClient.any(
    (ab) => ab.statutPaiement == 'Impayé',
  );

  return (abonnementLongueDuree || deuxEquipements) && aucunImpaye;
}

/// Équivalent de getStatistiquesDashboard().
/// Toutes les données (clients, equipements, mouvements, abonnements, et la
/// correspondance client -> équipements configurés) doivent être chargées au
/// préalable via TON API, puis passées ici — cette fonction ne fait AUCUN appel réseau.
StatistiquesDashboard calculerStatistiquesDashboard({
  required List<Client> clients,
  required List<Equipement> equipements,
  required List<Mouvement> mouvements,
  required List<Abonnement> abonnements,
  required Map<String, List<Equipement>>
  equipementsParClientId, // clientId -> équipements configurés
}) {
  final maintenant = DateTime.now();

  final clientsActifs = clients.where((c) => c.statut == 'Actif').length;
  final clientsInactifs = clients.where((c) => c.statut != 'Actif').length;

  final clientsFideles = clients.where((client) {
    final eqClient = equipementsParClientId[client.id] ?? [];
    final abClient = abonnements.where((a) => a.clientId == client.id).toList();
    return estFidele(eqClient, abClient);
  }).toList();

  final nouveauxCeMois = clients.where((c) {
    final d = DateTime.tryParse(c.dateEntree);
    if (d == null) return false;
    return d.month == maintenant.month && d.year == maintenant.year;
  }).length;

  final parPays = <String, int>{};
  for (final c in clients) {
    final pays = c.pays.isEmpty ? 'Non renseigné' : c.pays;
    parPays[pays] = (parPays[pays] ?? 0) + 1;
  }

  final stockFaible = equipements
      .where((eq) => eq.stock <= eq.seuilAlerte)
      .toList();
  final parCategorie = <String, int>{};
  for (final eq in equipements) {
    final cat = eq.categorie.isEmpty ? 'Autre' : eq.categorie;
    parCategorie[cat] = (parCategorie[cat] ?? 0) + eq.stock;
  }

  final entreesCeMois = mouvements.where((m) {
    if (m.typeMouvement != 'Entree') return false;
    final d = DateTime.tryParse(m.dateMouvement);
    if (d == null) return false;
    return d.month == maintenant.month && d.year == maintenant.year;
  }).toList();

  final sortiesCeMois = mouvements.where((m) {
    if (m.typeMouvement != 'Sortie') return false;
    final d = DateTime.tryParse(m.dateMouvement);
    if (d == null) return false;
    return d.month == maintenant.month && d.year == maintenant.year;
  }).toList();

  final abonnementsActifs = abonnements
      .where((a) => a.statutAbonnement == 'Actif')
      .toList();
  final abonnementsExpires = abonnements.where((a) {
    final jours = joursRestants(a.dateFin);
    return a.statutAbonnement == 'Actif' && jours != null && jours < 0;
  }).toList();

  final alertesSemaine =
      abonnements.where((a) {
        final niveau = niveauAlerte(a.dateFin, a.statutAbonnement);
        return niveau != null && niveau != 'expire';
      }).toList()..sort(
        (a, b) => (joursRestants(a.dateFin) ?? 0).compareTo(
          joursRestants(b.dateFin) ?? 0,
        ),
      );

  final revenusAbonnementsMois = abonnements
      .where((a) {
        final d = DateTime.tryParse(a.dateDebut);
        if (d == null) return false;
        return d.month == maintenant.month &&
            d.year == maintenant.year &&
            a.statutPaiement == 'Payé';
      })
      .fold<double>(0, (sum, a) => sum + a.montant);

  final revenusVentesMois = sortiesCeMois.fold<double>(
    0,
    (sum, m) => sum + (m.quantite * m.prixUnitaire),
  );

  return StatistiquesDashboard(
    clients: StatsClients(
      total: clients.length,
      actifs: clientsActifs,
      inactifs: clientsInactifs,
      nouveauxCeMois: nouveauxCeMois,
      parPays: parPays,
      fideles: clientsFideles,
    ),
    equipements: StatsEquipements(
      total: equipements.length,
      stockFaible: stockFaible,
      parCategorie: parCategorie,
      entreesCeMois: entreesCeMois.length,
      sortiesCeMois: sortiesCeMois.length,
    ),
    abonnements: StatsAbonnements(
      total: abonnements.length,
      actifs: abonnementsActifs.length,
      expires: abonnementsExpires.length,
      alertesSemaine: alertesSemaine,
    ),
    revenus: StatsRevenus(
      abonnementsMois: revenusAbonnementsMois,
      ventesMois: revenusVentesMois,
      total: revenusAbonnementsMois + revenusVentesMois,
    ),
  );
}
