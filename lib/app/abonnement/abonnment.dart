import 'package:flutter/material.dart';
import 'package:ias/app/abonnement/required_abonnement.dart';
import 'package:ias/app/abonnement/utils_abonnement.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/route_guard/route_guard.dart';

class AbonnementsPage extends StatelessWidget {
  const AbonnementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrivateRoute(child: _AbonnementsPageBody());
  }
}

class _AbonnementsPageBody extends StatefulWidget {
  const _AbonnementsPageBody();

  @override
  State<_AbonnementsPageBody> createState() => _AbonnementsPageBodyState();
}

class _AbonnementsPageBodyState extends State<_AbonnementsPageBody> {
  List<Abonnement> _abonnements = [];
  bool _chargement = true;
  String _filtreStatut = '';
  bool _filtreAlerte = false;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    _abonnements = await LocalStore.getAbonnements();
    setState(() => _chargement = false);
  }

  List<Abonnement> get _alertesUrgentes => _abonnements.where((ab) {
    final niveau = niveauAlerte(ab.dateFin, ab.statutAbonnement);
    return niveau != null && niveau != 'expire';
  }).toList();

  List<Abonnement> get _abonnementsFiltres => _abonnements.where((ab) {
    final matchRecherche =
        _recherche.isEmpty ||
        ab.clientNom.toLowerCase().contains(_recherche.toLowerCase());
    final matchStatut =
        _filtreStatut.isEmpty || ab.statutAbonnement == _filtreStatut;
    final matchAlerte =
        !_filtreAlerte || niveauAlerte(ab.dateFin, ab.statutAbonnement) != null;
    return matchRecherche && matchStatut && matchAlerte;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final alertes = _alertesUrgentes;
    final liste = _abonnementsFiltres;

    return AppShell(
      titre: 'Gestion des Abonnements',
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/abonnements/nouveau'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ciel,
            foregroundColor: Colors.white,
          ),
          child: const Text('+ Nouvel Abonnement'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alertes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.attenteFond,
                border: Border.all(color: AppColors.attenteTexte),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${alertes.length} abonnement(s) à renouveler dans les 7 prochains jours',
                    style: const TextStyle(
                      color: AppColors.attenteTexte,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: alertes.take(3).map((ab) {
                      final j = joursRestants(ab.dateFin);
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/abonnements/${ab.id}',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fondCarte,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: AppColors.bordure),
                          ),
                          child: Text(
                            '${ab.clientNom} — J-$j',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher par client, ID, n° série...',
              filled: true,
              fillColor: AppColors.fondCarte,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onChanged: (v) => setState(() => _recherche = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filtreStatut.isEmpty ? null : _filtreStatut,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.fondCarte,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    hintText: 'Tous les statuts',
                  ),
                  items: const ['Actif', 'Expiré', 'Suspendu', 'Résilié']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _filtreStatut = v ?? ''),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('À renouveler (7j)'),
                selected: _filtreAlerte,
                onSelected: (v) => setState(() => _filtreAlerte = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${liste.length} abonnement(s)',
            style: const TextStyle(
              color: AppColors.texteSecondaire,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          if (_chargement)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (liste.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Aucun abonnement trouvé.',
                  style: TextStyle(color: AppColors.texteSecondaire),
                ),
              ),
            )
          else
            ...liste.map((ab) => _carteAbonnement(context, ab)),
        ],
      ),
    );
  }

  Widget _carteAbonnement(BuildContext context, Abonnement ab) {
    final jours = joursRestants(ab.dateFin);
    final niveau = niveauAlerte(ab.dateFin, ab.statutAbonnement);
    final expire = jours != null && jours < 0 && ab.statutAbonnement == 'Actif';
    final bs = badgeStyle(ab.statutAbonnement);

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/abonnements/${ab.id}'),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.fondCarte,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border(
            top: BorderSide(
              width: niveau != null ? 3 : 1,
              color: niveau != null
                  ? (niveau == 'critique' || niveau == 'prioritaire'
                        ? AppColors.rouge
                        : AppColors.attenteTexte)
                  : AppColors.bordure,
            ),
            left: const BorderSide(color: AppColors.bordure),
            right: const BorderSide(color: AppColors.bordure),
            bottom: const BorderSide(color: AppColors.bordure),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ab.clientNom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.texte,
                      ),
                    ),
                    Text(
                      ab.kitId,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.texteSecondaire,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bs.background,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    ab.statutAbonnement,
                    style: TextStyle(
                      color: bs.color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '💳 ${ab.montant.toStringAsFixed(0)} F / ${ab.duree}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.texteSecondaire,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.fondPage,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DÉBUT',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.texteTertiaire,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ab.dateDebut,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.texte,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'FIN',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.texteTertiaire,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ab.dateFin,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.texte,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (niveau != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (niveau == 'critique' || niveau == 'prioritaire')
                      ? AppColors.dangerFond
                      : AppColors.attenteFond,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  expire
                      ? '⏰ Expiré depuis ${jours.abs()} j'
                      : jours == 0
                      ? "⏰ Expire aujourd'hui"
                      : jours == 1
                      ? '⏰ Expire demain'
                      : '⏰ J-$jours',
                  style: TextStyle(
                    color: (niveau == 'critique' || niveau == 'prioritaire')
                        ? AppColors.dangerTexte
                        : AppColors.attenteTexte,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: ab.statutPaiement == 'Payé'
                            ? AppColors.succesTexte
                            : AppColors.attenteTexte,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ab.statutPaiement,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ab.statutPaiement == 'Payé'
                            ? AppColors.succesTexte
                            : AppColors.attenteTexte,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Renouveler →',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ciel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
