import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/dashbaord/statistique_dashboard.dart';
import 'package:ias/app/equipement/required_equipement.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/route_guard/route_guard.dart';
import 'dart:math' as math;

const List<String> _mois = [
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

const List<Color> _pieColors = [
  AppColors.ciel,
  AppColors.marine,
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFF06B6D4),
  Color(0xFFEC4899),
];

class PointCAMensuel {
  final String mois;
  final double abonnements;
  final double ventes;
  double get total => abonnements + ventes;
  PointCAMensuel(this.mois, this.abonnements, this.ventes);
}

class RapportsPage extends StatelessWidget {
  const RapportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminRoute(child: _RapportsPageBody());
  }
}

class _RapportsPageBody extends StatefulWidget {
  const _RapportsPageBody();

  @override
  State<_RapportsPageBody> createState() => _RapportsPageBodyState();
}

class _RapportsPageBodyState extends State<_RapportsPageBody> {
  bool _chargement = true;
  StatistiquesDashboard? _stats;
  List<PointCAMensuel> _donneesCA = [];
  Map<String, int> _donneesGeo = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);

    // TODO: brancher tes propres appels API ici pour récupérer :
    // clients, equipements, mouvements, abonnements, equipementsParClientId
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

    final maintenant = DateTime.now();
    _donneesCA = List.generate(6, (i) {
      final d = DateTime(maintenant.year, maintenant.month - (5 - i), 1);
      final moisLabel = _mois[d.month - 1];

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

      return PointCAMensuel(moisLabel, revenus, ventes);
    });

    _donneesGeo = _stats!.clients.parPays;

    setState(() => _chargement = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement || _stats == null) {
      return const AppShell(
        titre: 'Rapports & Statistiques',
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final stats = _stats!;
    final totalCA = _donneesCA.fold<double>(0, (s, d) => s + d.total);
    final totalAbonnements = _donneesCA.fold<double>(
      0,
      (s, d) => s + d.abonnements,
    );
    final totalVentes = _donneesCA.fold<double>(0, (s, d) => s + d.ventes);

    return AppShell(
      titre: 'Rapports & Statistiques',
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          child: const Text('← Retour'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.2,
            children: [
              _kpiCarte(
                'CA Total (6 mois)',
                '${totalCA.toStringAsFixed(0)} F',
                AppColors.texte,
              ),
              _kpiCarte(
                'Revenus abonnements',
                '${totalAbonnements.toStringAsFixed(0)} F',
                AppColors.ciel,
              ),
              _kpiCarte(
                'Revenus ventes équipements',
                '${totalVentes.toStringAsFixed(0)} F',
                AppColors.marine,
              ),
              _kpiCarte(
                'Total clients',
                '${stats.clients.total}',
                AppColors.texte,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Graphique 1 — CA par mois (barres empilées)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.fondCarte,
              border: Border.all(color: AppColors.bordure),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Évolution du Chiffre d'Affaires (FCFA)",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texte,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _legendeDot(AppColors.ciel, 'Abonnements'),
                    const SizedBox(width: 14),
                    _legendeDot(AppColors.marine, 'Ventes équipements'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(height: 220, child: _barresEmpilees(_donneesCA)),
              ],
            ),
          ),

          // Graphique 2 + 3
          LayoutBuilder(
            builder: (context, constraints) {
              final large = constraints.maxWidth > 700;
              final graph2 = _panel(
                titre: 'Abonnements actifs vs expirés',
                child: SizedBox(
                  height: 180,
                  child: _barresSimples({
                    'Actifs': stats.abonnements.actifs.toDouble(),
                    'Expirés': stats.abonnements.expires.toDouble(),
                    'Total': stats.abonnements.total.toDouble(),
                  }),
                ),
              );
              final graph3 = _panel(
                titre: 'Répartition par pays',
                child: _donneesGeo.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Aucune donnée géographique.',
                            style: TextStyle(
                              color: AppColors.texteSecondaire,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(height: 220, child: _donutPays(_donneesGeo)),
              );

              if (large) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: graph2),
                    const SizedBox(width: 16),
                    Expanded(child: graph3),
                  ],
                );
              }
              return Column(
                children: [graph2, const SizedBox(height: 16), graph3],
              );
            },
          ),
          const SizedBox(height: 16),

          // Tableau stock par catégorie
          _panel(
            titre: "Stock par catégorie d'équipement",
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fondPage,
                    border: Border.all(color: AppColors.bordure),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'CATÉGORIE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.texteTertiaire,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'QUANTITÉ EN STOCK',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.texteTertiaire,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...stats.equipements.parCategorie.entries.map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.fondPage),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.texte,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${e.value}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.marine,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCarte(String label, String valeur, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.fondCarte,
        border: Border.all(color: AppColors.bordure),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.texteSecondaire,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required String titre, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fondCarte,
        border: Border.all(color: AppColors.bordure),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.texte,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _legendeDot(Color couleur, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.texteSecondaire,
          ),
        ),
      ],
    );
  }

  Widget _barresEmpilees(List<PointCAMensuel> donnees) {
    final maxVal = donnees
        .map((d) => d.total)
        .fold<double>(0, (a, b) => a > b ? a : b)
        .clamp(1, double.infinity)
        .toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: donnees.map((d) {
        final hAbo = (d.abonnements / maxVal) * 160;
        final hVente = (d.ventes / maxVal) * 160;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  height: hVente,
                  color: AppColors.marine,
                ),
                Container(
                  width: double.infinity,
                  height: hAbo,
                  decoration: const BoxDecoration(
                    color: AppColors.ciel,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  d.mois,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.texteSecondaire,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _barresSimples(Map<String, double> donnees) {
    final maxVal = donnees.values
        .fold<double>(0, (a, b) => a > b ? a : b)
        .clamp(1, double.infinity)
        .toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: donnees.entries.map((e) {
        final hauteur = (e.value / maxVal) * 130;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  e.value.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.texte,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: hauteur < 4 ? 4 : hauteur,
                  decoration: const BoxDecoration(
                    color: AppColors.ciel,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.texteSecondaire,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _donutPays(Map<String, int> donnees) {
    final entries = donnees.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Row(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: _DonutPainter(
              entries.map((e) => e.value.toDouble()).toList(),
              _pieColors,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: entries.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final pct = total == 0 ? 0 : (e.value / total * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _pieColors[i % _pieColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.texte,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.texteSecondaire,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final strokeWidth = size.width * 0.22;
    double startAngle = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values;
}

extension _FirstOrNullRapports<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
