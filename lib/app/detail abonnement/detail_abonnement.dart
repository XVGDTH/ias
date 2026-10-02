import 'package:flutter/material.dart';
import 'package:ias/app/abonnement/required_abonnement.dart';
import 'package:ias/app/abonnement/utils_abonnement.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/provider/role_provider.dart';
import 'package:ias/app/route_guard/route_guard.dart';

class DetailAbonnementPage extends StatelessWidget {
  final String abonnementId;
  const DetailAbonnementPage({super.key, required this.abonnementId});

  @override
  Widget build(BuildContext context) {
    return PrivateRoute(
      child: _DetailAbonnementPageBody(abonnementId: abonnementId),
    );
  }
}

class _DetailAbonnementPageBody extends StatefulWidget {
  final String abonnementId;
  const _DetailAbonnementPageBody({required this.abonnementId});

  @override
  State<_DetailAbonnementPageBody> createState() =>
      _DetailAbonnementPageBodyState();
}

class _DetailAbonnementPageBodyState extends State<_DetailAbonnementPageBody> {
  Abonnement? _abonnement;
  bool _chargement = true;
  bool _modeEdition = false;
  bool _sauvegarde = false;

  bool _afficherRenouvellement = false;
  bool _enregistrementRenouv = false;
  String _renouvDuree = 'Mensuel';
  final _renouvMontantController = TextEditingController();
  final String _renouvStatutPaiement = 'Payé';
  String _renouvModePaiement = 'Espèces';

  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();
  final _montantController = TextEditingController();
  final _notesController = TextEditingController();
  String _duree = 'Mensuel';
  String _statutAbonnement = 'Actif';
  String _statutPaiement = 'Payé';

  bool get peutVoirFinances => RoleProvider.instance.peutVoirFinances;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _renouvMontantController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    _montantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    _abonnement = await LocalStore.getAbonnementById(widget.abonnementId);
    if (_abonnement != null) {
      final ab = _abonnement!;
      _dateDebutController.text = ab.dateDebut;
      _dateFinController.text = ab.dateFin;
      _montantController.text = ab.montant.toString();
      _notesController.text = ab.notes;
      _duree = ab.duree;
      _statutAbonnement = ab.statutAbonnement;
      _statutPaiement = ab.statutPaiement;
      _renouvDuree = _duree;
      _renouvMontantController.text = ab.montant.toString();
    }
    setState(() => _chargement = false);
  }

  Future<void> _handleSave() async {
    setState(() => _sauvegarde = true);
    if (_abonnement != null) {
      final maj = _abonnement!.copyWith(
        dateDebut: _dateDebutController.text,
        dateFin: _dateFinController.text,
        duree: _duree,
        statutAbonnement: _statutAbonnement,
        montant:
            double.tryParse(_montantController.text) ?? _abonnement!.montant,
        statutPaiement: _statutPaiement,
        notes: _notesController.text,
      );
      await LocalStore.updateAbonnement(maj);
    }
    await _charger();
    setState(() {
      _modeEdition = false;
      _sauvegarde = false;
    });
  }

  Future<void> _confirmerRenouvellement() async {
    setState(() => _enregistrementRenouv = true);
    try {
      await LocalStore.renouvelerAbonnement(
        widget.abonnementId,
        duree: _renouvDuree,
        montant:
            double.tryParse(_renouvMontantController.text) ??
            (_abonnement?.montant ?? 0),
        modePaiement: _renouvModePaiement,
        statutPaiement: _renouvStatutPaiement,
      );
      await _charger();
      setState(() => _afficherRenouvellement = false);
    } finally {
      if (mounted) setState(() => _enregistrementRenouv = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoute RoleProvider explicitement pour garantir que les champs
    // financiers (Admin uniquement) apparaissent dès que le rôle est disponible.
    return AnimatedBuilder(
      animation: RoleProvider.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_chargement) {
      return const AppShell(
        titre: 'Abonnement',
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_abonnement == null) {
      return const AppShell(
        titre: 'Abonnement',
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              'Introuvable.',
              style: TextStyle(color: AppColors.texteSecondaire),
            ),
          ),
        ),
      );
    }

    final ab = _abonnement!;
    final jours = joursRestants(ab.dateFin);
    final niveau = niveauAlerte(ab.dateFin, ab.statutAbonnement);
    final expire = jours != null && jours < 0 && ab.statutAbonnement == 'Actif';
    final bs = badgeStyle(ab.statutAbonnement);
    final apercuNouvelleDate = calculerDateFin(
      (joursRestants(ab.dateFin) ?? -1) > 0
          ? ab.dateFin
          : DateTime.now().toIso8601String().split('T')[0],
      _renouvDuree,
    );

    return AppShell(
      titre: 'Abonnement — ${ab.clientNom}',
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/abonnements'),
          child: const Text('← Retour'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () =>
              Navigator.pushNamed(context, '/clients/${ab.clientId}'),
          child: const Text('Voir le client'),
        ),
        const SizedBox(width: 8),
        if (!_modeEdition)
          ElevatedButton(
            onPressed: () => setState(() => _modeEdition = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ciel,
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier'),
          )
        else ...[
          TextButton(
            onPressed: () => setState(() => _modeEdition = false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: _sauvegarde ? null : _handleSave,
            child: Text(_sauvegarde ? 'Sauvegarde...' : 'Sauvegarder'),
          ),
        ],
      ],
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (niveau != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: (expire || niveau == 'critique')
                        ? AppColors.dangerFond
                        : AppColors.attenteFond,
                    border: Border.all(
                      color: (expire || niveau == 'critique')
                          ? AppColors.rouge
                          : AppColors.attenteTexte,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      Text(
                        expire
                            ? '⛔ Expiré depuis ${jours.abs()} jour(s)'
                            : jours == 0
                            ? "⚠️ Expire aujourd'hui"
                            : jours == 1
                            ? '⚠️ Expire demain'
                            : '⚠️ Expire dans $jours jours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: (expire || niveau == 'critique')
                              ? AppColors.dangerTexte
                              : AppColors.attenteTexte,
                        ),
                      ),
                      if (ab.statutAbonnement != 'Résilié' && !_modeEdition)
                        ElevatedButton(
                          onPressed: () =>
                              setState(() => _afficherRenouvellement = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ciel,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Marquer comme renouvelé'),
                        ),
                    ],
                  ),
                ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.fondCarte,
                  border: Border.all(color: AppColors.bordure),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.texte,
                              ),
                            ),
                            Text(
                              'Kit : ${ab.kitId}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.texteSecondaire,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
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
                    const SizedBox(height: 22),

                    _champInfo(
                      'Date de début',
                      _dateDebutController,
                      _modeEdition,
                      ab.dateDebut,
                    ),
                    const SizedBox(height: 14),
                    _champInfo(
                      'Date de fin',
                      _dateFinController,
                      _modeEdition,
                      ab.dateFin,
                    ),
                    const SizedBox(height: 14),
                    _champInfoDropdown(
                      'Durée',
                      _duree,
                      ['Mensuel', 'Trimestriel', 'Annuel'],
                      _modeEdition,
                      (v) => setState(() => _duree = v ?? _duree),
                    ),
                    const SizedBox(height: 14),
                    _champInfoDropdown(
                      'Statut abonnement',
                      _statutAbonnement,
                      ['Actif', 'Expiré', 'Suspendu', 'Résilié'],
                      _modeEdition,
                      (v) => setState(
                        () => _statutAbonnement = v ?? _statutAbonnement,
                      ),
                    ),

                    if (peutVoirFinances) ...[
                      const SizedBox(height: 14),
                      _champInfo(
                        'Montant',
                        _montantController,
                        _modeEdition,
                        ab.montant.toString(),
                      ),
                      const SizedBox(height: 14),
                      _champInfoDropdown(
                        'Statut paiement',
                        _statutPaiement,
                        ['Payé', 'En attente', 'Impayé'],
                        _modeEdition,
                        (v) => setState(
                          () => _statutPaiement = v ?? _statutPaiement,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.texteTertiaire,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _modeEdition
                        ? TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.fondPage,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            ab.notes.isEmpty ? '—' : ab.notes,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.texte,
                            ),
                          ),

                    if (peutVoirFinances &&
                        ab.historiquePaiements.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'HISTORIQUE DES PAIEMENTS',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.texteTertiaire,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...ab.historiquePaiements.reversed.map(
                        (p) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fondPage,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p.date,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.texteSecondaire,
                                ),
                              ),
                              Text(
                                p.modePaiement,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.texteSecondaire,
                                ),
                              ),
                              Text(
                                '${p.montant.toStringAsFixed(0)} F',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.texte,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (!_modeEdition &&
                        ab.statutAbonnement != 'Résilié' &&
                        niveau == null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => _afficherRenouvellement = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cielClair,
                            foregroundColor: AppColors.marine,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text(
                            'Marquer comme renouvelé',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (_afficherRenouvellement)
            GestureDetector(
              onTap: () => setState(() => _afficherRenouvellement = false),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 420,
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.fondCarte,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.bordure),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Confirmer le renouvellement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.texte,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Le paiement a été effectué sur le site Starlink ? Indiquez la nouvelle durée.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.texteSecondaire,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Durée',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _renouvDuree,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.fondPage,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                            items: const ['Mensuel', 'Trimestriel', 'Annuel']
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => _renouvDuree = v ?? _renouvDuree,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (peutVoirFinances) ...[
                            const Text(
                              'Montant payé (FCFA)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _renouvMontantController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.fondPage,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          const Text(
                            'Mode de paiement',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _renouvModePaiement,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.fondPage,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                            items:
                                const [
                                      'Espèces',
                                      'Mobile Money',
                                      'Virement',
                                      'Autre',
                                    ]
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(
                              () => _renouvModePaiement =
                                  v ?? _renouvModePaiement,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.cielClair,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text.rich(
                              TextSpan(
                                text: 'Nouvelle date de fin : ',
                                style: const TextStyle(
                                  color: AppColors.marine,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: apercuNouvelleDate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => setState(
                                  () => _afficherRenouvellement = false,
                                ),
                                child: const Text('Annuler'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _enregistrementRenouv
                                    ? null
                                    : _confirmerRenouvellement,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.succesFond,
                                  foregroundColor: AppColors.succesTexte,
                                ),
                                child: Text(
                                  _enregistrementRenouv
                                      ? 'Enregistrement...'
                                      : 'Confirmer',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _champInfo(
    String label,
    TextEditingController controller,
    bool editable,
    String? valeur,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.texteTertiaire,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        editable
            ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.fondPage,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              )
            : Text(
                valeur ?? '—',
                style: const TextStyle(fontSize: 14, color: AppColors.texte),
              ),
      ],
    );
  }

  Widget _champInfoDropdown(
    String label,
    String valeur,
    List<String> options,
    bool editable,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.texteTertiaire,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        editable
            ? DropdownButtonFormField<String>(
                initialValue: valeur,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.fondPage,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: onChanged,
              )
            : Text(
                valeur,
                style: const TextStyle(fontSize: 14, color: AppColors.texte),
              ),
      ],
    );
  }
}
