import 'package:flutter/material.dart';
import 'package:ias/app/abonnement/required_abonnement.dart';
import 'package:ias/app/graphiques/mini-chartx.dart';
import 'package:ias/app/mouvement_stock/required_mouvement.dart';

const List<String> moisAbreges = [
  'Jan',
  'Fév',
  'Mar',
  'Avr',
  'Mai',
  'Juin',
  'Juil',
  'Août',
  'Sep',
  'Oct',
  'Nov',
  'Déc',
];
const List<String> joursAbreges = [
  'Lun',
  'Mar',
  'Mer',
  'Jeu',
  'Ven',
  'Sam',
  'Dim',
];

/// Chiffre d'affaires réalisé un jour donné (abonnements payés ce jour-là
/// + ventes d'équipements ce jour-là), en FCFA.
double _caDuJour(
  DateTime jour,
  List<Abonnement> abonnements,
  List<Mouvement> mouvements,
) {
  final revenusAbo = abonnements
      .where((a) {
        final d = DateTime.tryParse(a.dateDebut);
        return d != null &&
            a.statutPaiement == 'Payé' &&
            d.year == jour.year &&
            d.month == jour.month &&
            d.day == jour.day;
      })
      .fold<double>(0, (s, a) => s + a.montant);

  final ventes = mouvements
      .where((m) {
        final d = DateTime.tryParse(m.dateMouvement);
        return m.typeMouvement == 'Sortie' &&
            d != null &&
            d.year == jour.year &&
            d.month == jour.month &&
            d.day == jour.day;
      })
      .fold<double>(0, (s, m) => s + (m.quantite * m.prixUnitaire));

  return revenusAbo + ventes;
}

/// CA des 7 derniers jours (CDC 3.4.2 — "histogramme par jour").
List<PointGraphique> caParJour(
  List<Abonnement> abonnements,
  List<Mouvement> mouvements, {
  int nbJours = 7,
}) {
  final aujourdHui = DateTime.now();
  return List.generate(nbJours, (i) {
    final jour = DateTime(
      aujourdHui.year,
      aujourdHui.month,
      aujourdHui.day,
    ).subtract(Duration(days: nbJours - 1 - i));
    final label = joursAbreges[(jour.weekday - 1) % 7];
    return PointGraphique(label, _caDuJour(jour, abonnements, mouvements));
  });
}

/// CA des N dernières semaines (regroupement par semaines calendaires glissantes de 7 jours).
List<PointGraphique> caParSemaine(
  List<Abonnement> abonnements,
  List<Mouvement> mouvements, {
  int nbSemaines = 6,
}) {
  final aujourdHui = DateTime.now();
  return List.generate(nbSemaines, (i) {
    final finSemaine = DateTime(
      aujourdHui.year,
      aujourdHui.month,
      aujourdHui.day,
    ).subtract(Duration(days: (nbSemaines - 1 - i) * 7));
    double total = 0;
    for (var j = 0; j < 7; j++) {
      total += _caDuJour(
        finSemaine.subtract(Duration(days: j)),
        abonnements,
        mouvements,
      );
    }
    final semainesAvant = nbSemaines - 1 - i;
    final label = semainesAvant == 0 ? 'Cette sem.' : 'S-$semainesAvant';
    return PointGraphique(label, total);
  });
}

/// CA des N derniers mois (CDC 3.4.1 / 3.4.2).
List<PointGraphique> caParMois(
  List<Abonnement> abonnements,
  List<Mouvement> mouvements, {
  int nbMois = 6,
}) {
  final maintenant = DateTime.now();
  return List.generate(nbMois, (i) {
    final d = DateTime(maintenant.year, maintenant.month - (nbMois - 1 - i), 1);
    final revenus = abonnements
        .where((a) {
          final dd = DateTime.tryParse(a.dateDebut);
          return dd != null &&
              a.statutPaiement == 'Payé' &&
              dd.month == d.month &&
              dd.year == d.year;
        })
        .fold<double>(0, (s, a) => s + a.montant);

    final ventes = mouvements
        .where((m) {
          final dm = DateTime.tryParse(m.dateMouvement);
          return m.typeMouvement == 'Sortie' &&
              dm != null &&
              dm.month == d.month &&
              dm.year == d.year;
        })
        .fold<double>(0, (s, m) => s + (m.quantite * m.prixUnitaire));

    return PointGraphique(moisAbreges[d.month - 1], revenus + ventes);
  });
}

/// Évolution du stock — entrées vs sorties par jour, sur les N derniers jours
/// (CDC 3.4.2 — "Évolution du stock (entrées / sorties par période)").
({List<String> labels, List<SerieGraphique> series}) evolutionStock(
  List<Mouvement> mouvements, {
  int nbJours = 14,
}) {
  final aujourdHui = DateTime.now();
  final jours = List.generate(
    nbJours,
    (i) => DateTime(
      aujourdHui.year,
      aujourdHui.month,
      aujourdHui.day,
    ).subtract(Duration(days: nbJours - 1 - i)),
  );

  final labels = jours.map((j) => '${j.day}/${j.month}').toList();

  final entrees = jours.map((jour) {
    return mouvements
        .where((m) {
          final d = DateTime.tryParse(m.dateMouvement);
          return m.typeMouvement == 'Entree' &&
              d != null &&
              d.year == jour.year &&
              d.month == jour.month &&
              d.day == jour.day;
        })
        .fold<double>(0, (s, m) => s + m.quantite);
  }).toList();

  final sorties = jours.map((jour) {
    return mouvements
        .where((m) {
          final d = DateTime.tryParse(m.dateMouvement);
          return m.typeMouvement == 'Sortie' &&
              d != null &&
              d.year == jour.year &&
              d.month == jour.month &&
              d.day == jour.day;
        })
        .fold<double>(0, (s, m) => s + m.quantite);
  }).toList();

  return (
    labels: labels,
    series: [
      SerieGraphique(
        nom: 'Entrées',
        couleur: const Color(0xFF10B981),
        valeurs: entrees,
      ),
      SerieGraphique(
        nom: 'Sorties',
        couleur: const Color(0xFFEF4444),
        valeurs: sorties,
      ),
    ],
  );
}
