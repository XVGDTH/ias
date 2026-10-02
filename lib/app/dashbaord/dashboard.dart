import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ias/app/abonnement/required_abonnement.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/client/required_client.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/dashbaord/statistique_dashboard.dart';
import 'package:ias/app/equipement/required_equipement.dart';
import 'package:ias/app/graphiques/charts-data.dart' as charts;
import 'package:ias/app/graphiques/mini-chartx.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/mouvement_stock/required_mouvement.dart';
import 'package:ias/app/provider/role_provider.dart';
import 'package:ias/app/route_guard/route_guard.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrivateRoute(child: _DashboardPageBody());
  }
}

class _DashboardPageBody extends StatefulWidget {
  const _DashboardPageBody();

  @override
  State<_DashboardPageBody> createState() => _DashboardPageBodyState();
}

class _DashboardPageBodyState extends State<_DashboardPageBody> {
  bool _chargement = true;
  String _heure = '';
  Timer? _timer;

  StatistiquesDashboard? _stats;
  List<Client> _clients = [];
  List<Abonnement> _abonnements = [];
  List<Mouvement> _mouvements = [];

  /// Granularité choisie pour l'histogramme du chiffre d'affaires : jour / semaine / mois.
  String _graniteCA = 'mois';

  bool get peutVoirFinances => RoleProvider.instance.peutVoirFinances;

  @override
  void initState() {
    super.initState();
    _charger();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _mettreAJourHeure(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _mettreAJourHeure() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _heure =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    _mettreAJourHeure();

    final clients = await LocalStore.getClients();
    final equipements = await LocalStore.getEquipements();
    final mouvements = await LocalStore.getMouvementsStock();
    final abonnements = await LocalStore.getAbonnements();
    final identifiants = await LocalStore.getIdentifiants();

    // Regroupe les équipements configurés par client (pour le calcul de fidélité)
    final Map<String, List<Equipement>> equipementsParClientId = {};
    for (final ident in identifiants) {
      final eq = equipements
          .where((e) => e.id == ident.equipementId)
          .firstOrNull;
      if (eq == null) continue;
      equipementsParClientId.putIfAbsent(ident.clientId, () => []).add(eq);
    }

    await LocalStore.recalculerClientsFideles();

    _stats = calculerStatistiquesDashboard(
      clients: clients,
      equipements: equipements,
      mouvements: mouvements,
      abonnements: abonnements,
      equipementsParClientId: equipementsParClientId,
    );

    _clients = clients;
    _abonnements = abonnements;
    _mouvements = mouvements;

    setState(() => _chargement = false);
  }

  /// Données de l'histogramme de CA selon la granularité choisie (jour/semaine/mois).
  List<PointGraphique> get _donneesCA {
    switch (_graniteCA) {
      case 'jour':
        return charts.caParJour(_abonnements, _mouvements);
      case 'semaine':
        return charts.caParSemaine(_abonnements, _mouvements);
      case 'mois':
      default:
        return charts.caParMois(_abonnements, _mouvements);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoute RoleProvider explicitement pour garantir que la carte "Revenus
    // du mois" (Admin uniquement) apparaît dès que le rôle est disponible.
    return AnimatedBuilder(
      animation: RoleProvider.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_chargement || _stats == null) {
      return const AppShell(
        titre: 'Tableau de bord',
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final stats = _stats!;
    final alertesSemaine = stats.abonnements.alertesSemaine;
    final stockFaible = stats.equipements.stockFaible;
    final clientsFideles = stats.clients.fideles;

    return AppShell(
      titre: 'Tableau de bord',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Dernière mise à jour : $_heure',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.texteTertiaire,
              ),
            ),
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.4,
            children: [
              _kpiCarte(
                label: 'Clients Actifs',
                valeur: '${stats.clients.actifs}',
                delta: '+${stats.clients.nouveauxCeMois} ce mois',
                iconBg: const Color(0xFFE8F0FE),
                icon: Icons.people_outline,
                iconColor: const Color(0xFF4A6CF7),
              ),
              _kpiCarte(
                label: 'Abonnements Actifs',
                valeur: '${stats.abonnements.actifs}',
                delta: '${stats.abonnements.expires} expiré(s)',
                iconBg: const Color(0xFFE0FBF4),
                icon: Icons.wifi,
                iconColor: const Color(0xFF0EA5A0),
              ),
              if (peutVoirFinances)
                _kpiCarte(
                  label: 'Revenus du mois (FCFA)',
                  valeur: stats.revenus.total.toStringAsFixed(0),
                  delta: 'Abonnements + ventes',
                  iconBg: const Color(0xFFE0FBF4),
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFF0EA5A0),
                ),
              _kpiCarte(
                label: 'Équipements en Stock',
                valeur: '${stats.equipements.total}',
                delta: '${stockFaible.length} en stock faible',
                deltaColor: stockFaible.isNotEmpty
                    ? AppColors.attenteTexte
                    : AppColors.succesTexte,
                iconBg: const Color(0xFFF0EEFF),
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (peutVoirFinances) _panelHistogrammeCA(),
          if (peutVoirFinances) const SizedBox(height: 14),

          // Deux diagrammes circulaires côte à côte : nombre de clients par
          // statut, et répartition géographique (par pays) — CDC 3.4.2.
          LayoutBuilder(
            builder: (context, constraints) {
              final large = constraints.maxWidth > 700;
              final donutStatut = _panel(
                titre: 'Clients par statut',
                child: DonutChartWidget(donnees: _clientsParStatut()),
              );
              final donutPays = _panel(
                titre: 'Répartition géographique',
                child: DonutChartWidget(donnees: stats.clients.parPays),
              );
              if (large) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: donutStatut),
                    const SizedBox(width: 14),
                    Expanded(child: donutPays),
                  ],
                );
              }
              return Column(
                children: [donutStatut, const SizedBox(height: 14), donutPays],
              );
            },
          ),
          const SizedBox(height: 14),

          // Courbe entrées/sorties de stock — CDC 3.4.2 "Évolution du stock"
          _panelEvolutionStock(),
          const SizedBox(height: 14),

          _panelLateral(
            titre: 'Expirations proches (7j)',
            compteur: alertesSemaine.length,
            vide: 'Aucune expiration cette semaine.',
            enfants: alertesSemaine.take(5).map((ab) {
              final jours = ab.dateFin.isEmpty
                  ? 0
                  : (DateTime.tryParse(
                          ab.dateFin,
                        )?.difference(DateTime.now()).inDays ??
                        0);
              final urgent = jours <= 3;
              return _alerteItem(
                icone: Icons.access_time,
                iconBg: urgent ? AppColors.dangerFond : AppColors.attenteFond,
                iconColor: urgent ? AppColors.rouge : AppColors.attenteTexte,
                titre: ab.clientNom,
                sousTitre: ab.kitId,
                droite: 'J-$jours',
                droiteColor: urgent ? AppColors.rouge : AppColors.attenteTexte,
                onTap: () =>
                    Navigator.pushNamed(context, '/abonnements/${ab.id}'),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          _panelLateral(
            titre: 'Stock faible',
            compteur: stockFaible.length,
            compteurBg: AppColors.dangerFond,
            compteurColor: AppColors.dangerTexte,
            vide: 'Tout le stock est suffisant.',
            enfants: stockFaible.map((eq) {
              return _alerteItem(
                icone: Icons.warning_amber_rounded,
                iconBg: AppColors.dangerFond,
                iconColor: AppColors.rouge,
                titre: eq.nom,
                sousTitre: eq.categorie,
                droite: '${eq.stock} restant(s)',
                droiteColor: AppColors.rouge,
                onTap: () =>
                    Navigator.pushNamed(context, '/equipements/${eq.id}'),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          _panelLateral(
            titre: 'Clients fidèles',
            compteur: clientsFideles.length,
            compteurBg: const Color(0xFFFAEEDA),
            compteurColor: const Color(0xFF854F0B),
            vide: "Aucun client fidèle pour l'instant.",
            enfants: clientsFideles.take(4).map((c) {
              return _alerteItem(
                icone: Icons.star,
                iconBg: const Color(0xFFFAEEDA),
                iconColor: const Color(0xFF854F0B),
                titre: c.nom,
                sousTitre: '${c.ville}, ${c.pays}',
                droite: '',
                droiteColor: AppColors.texte,
                onTap: () => Navigator.pushNamed(context, '/clients/${c.id}'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _kpiCarte({
    required String label,
    required String valeur,
    required String delta,
    Color deltaColor = AppColors.succesTexte,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.fondCarte,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.texteSecondaire,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  valeur,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.texte,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  delta,
                  style: TextStyle(
                    fontSize: 11,
                    color: deltaColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ],
      ),
    );
  }

  /// Panel générique (titre + contenu), réutilisé par les 3 nouvelles figures.
  Widget _panel({
    required String titre,
    required Widget child,
    Widget? actions,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fondCarte,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.texte,
                ),
              ),
              ?actions,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Répartition du nombre de clients par statut (Actif / Inactif / Suspendu).
  Map<String, int> _clientsParStatut() {
    final result = <String, int>{};
    for (final c in _clients) {
      result[c.statut] = (result[c.statut] ?? 0) + 1;
    }
    return result;
  }

  /// Histogramme n°1 : chiffre d'affaires par jour / semaine / mois (CDC 3.4.2),
  /// avec un sélecteur de granularité.
  Widget _panelHistogrammeCA() {
    return _panel(
      titre: "Chiffre d'affaires",
      actions: ToggleButtons(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        constraints: const BoxConstraints(minHeight: 30, minWidth: 56),
        isSelected: [
          _graniteCA == 'jour',
          _graniteCA == 'semaine',
          _graniteCA == 'mois',
        ],
        onPressed: (index) =>
            setState(() => _graniteCA = ['jour', 'semaine', 'mois'][index]),
        selectedColor: Colors.white,
        fillColor: AppColors.ciel,
        color: AppColors.texteSecondaire,
        textStyle: const TextStyle(fontSize: 12),
        children: const [Text('Jour'), Text('Semaine'), Text('Mois')],
      ),
      child: BarChartWidget(
        donnees: _donneesCA,
        couleur: AppColors.succesTexte,
        formatValeur: (v) => v >= 1000
            ? '${(v / 1000).toStringAsFixed(0)}k'
            : v.toStringAsFixed(0),
      ),
    );
  }

  /// Courbe n°3 : évolution du stock — entrées vs sorties sur 14 jours (CDC 3.4.2).
  Widget _panelEvolutionStock() {
    final donnees = charts.evolutionStock(_mouvements);
    return _panel(
      titre: 'Évolution du stock (14 derniers jours)',
      child: LineChartWidget(labelsX: donnees.labels, series: donnees.series),
    );
  }

  Widget _panelLateral({
    required String titre,
    required int compteur,
    Color compteurBg = AppColors.attenteFond,
    Color compteurColor = AppColors.attenteTexte,
    required String vide,
    required List<Widget> enfants,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.fondCarte,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.texte,
                ),
              ),
              if (compteur > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: compteurBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$compteur',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: compteurColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (enfants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                vide,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.texteTertiaire,
                ),
              ),
            )
          else
            Column(children: enfants),
        ],
      ),
    );
  }

  Widget _alerteItem({
    required IconData icone,
    required Color iconBg,
    required Color iconColor,
    required String titre,
    required String sousTitre,
    required String droite,
    required Color droiteColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.fondPage,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icone, size: 14, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte,
                    ),
                  ),
                  Text(
                    sousTitre,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.texteTertiaire,
                    ),
                  ),
                ],
              ),
            ),
            if (droite.isNotEmpty)
              Text(
                droite,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: droiteColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullDash<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
