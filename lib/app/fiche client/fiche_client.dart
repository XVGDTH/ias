import 'package:flutter/material.dart';
import 'package:ias/app/abonnement/required_abonnement.dart';
import 'package:ias/app/abonnement/utils_abonnement.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/client/required_client.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/identifiant/identifiant.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/route_guard/route_guard.dart';

// Alias vers les modèles centralisés — la page utilisait auparavant des
// classes locales ad-hoc, remplacées par les modèles partagés (LocalStore).
typedef EquipementConfigure = Identifiant;
typedef AbonnementResume = Abonnement;

class FicheClientPage extends StatelessWidget {
  final String clientId;
  const FicheClientPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return PrivateRoute(child: _FicheClientPageBody(clientId: clientId));
  }
}

class _FicheClientPageBody extends StatefulWidget {
  final String clientId;
  const _FicheClientPageBody({required this.clientId});

  @override
  State<_FicheClientPageBody> createState() => _FicheClientPageBodyState();
}

class _FicheClientPageBodyState extends State<_FicheClientPageBody> {
  Client? _client;
  bool _chargement = true;
  bool _modeEdition = false;
  bool _sauvegarde = false;
  bool _archivage = false;

  List<EquipementConfigure> _equipementsClient = [];
  List<AbonnementResume> _abonnementsClient = [];

  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _paysController = TextEditingController();
  final _villeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerClient();
  }

  @override
  void dispose() {
    _telephoneController.dispose();
    _emailController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _chargerClient() async {
    setState(() => _chargement = true);
    _client = await LocalStore.getClientById(widget.clientId);
    _equipementsClient = await LocalStore.getIdentifiantsParClient(
      widget.clientId,
    );
    _abonnementsClient = await LocalStore.getAbonnementsParClient(
      widget.clientId,
    );

    if (_client != null) {
      _telephoneController.text = _client!.telephone;
      _emailController.text = _client!.email;
      _paysController.text = _client!.pays;
      _villeController.text = _client!.ville;
      _adresseController.text = _client!.adresse;
      _notesController.text = _client!.notes;
    }
    setState(() => _chargement = false);
  }

  Future<void> _handleSave() async {
    setState(() => _sauvegarde = true);
    if (_client != null) {
      final maj = _client!.copyWith(
        telephone: _telephoneController.text,
        email: _emailController.text,
        pays: _paysController.text,
        ville: _villeController.text,
        adresse: _adresseController.text,
        notes: _notesController.text,
      );
      await LocalStore.updateClient(widget.clientId, maj);
    }
    await _chargerClient();
    setState(() {
      _modeEdition = false;
      _sauvegarde = false;
    });
  }

  /// Équivalent de "Archiver ou désactiver un client (sans suppression
  /// définitive)" — CDC 3.1.2. Change simplement le statut à "Inactif".
  Future<void> _handleArchiver() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver ce client ?'),
        content: Text(
          "${_client?.nom ?? 'Ce client'} passera au statut \"Inactif\". "
          "Ses données, équipements et abonnements restent conservés — ce n'est pas une suppression.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.attenteTexte,
              foregroundColor: Colors.white,
            ),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _archivage = true);
    await LocalStore.archiverClient(widget.clientId);
    await _chargerClient();
    if (mounted) setState(() => _archivage = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const AppShell(
        titre: 'Fiche Client',
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_client == null) {
      return const AppShell(
        titre: 'Fiche Client',
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              'Client introuvable.',
              style: TextStyle(color: AppColors.texteSecondaire),
            ),
          ),
        ),
      );
    }

    final client = _client!;
    final badgeStatut = badgeStyle(client.statut);

    return AppShell(
      titre: client.nom,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/clients'),
          child: const Text('← Retour'),
        ),
        const SizedBox(width: 8),
        if (!_modeEdition && client.statut != 'Inactif')
          OutlinedButton(
            onPressed: _archivage ? null : _handleArchiver,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.attenteTexte,
              side: const BorderSide(color: AppColors.attenteTexte),
            ),
            child: Text(_archivage ? 'Archivage...' : 'Archiver'),
          ),
        const SizedBox(width: 8),
        if (!_modeEdition)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => setState(() => _modeEdition = true),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.fondCarte,
              border: Border.all(color: AppColors.bordure),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.marine, AppColors.ciel],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          client.nom.isNotEmpty
                              ? client.nom[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              Text(
                                client.nom,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.texte,
                                ),
                              ),
                              if (client.fidele)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAEEDA),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: const Text(
                                    '⭐ Fidèle',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF854F0B),
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeStatut.background,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  client.statut,
                                  style: TextStyle(
                                    color: badgeStatut.color,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            client.typeClient,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.texteSecondaire,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${client.ville}, ${client.pays}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.texteTertiaire,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40, color: AppColors.fondPage),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _infoCard(
                        'Téléphone',
                        _telephoneController,
                        _modeEdition,
                        client.telephone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoCard(
                        'Email',
                        _emailController,
                        _modeEdition,
                        client.email,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _infoCard(
                        'Pays',
                        _paysController,
                        _modeEdition,
                        client.pays,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoCard(
                        'Ville',
                        _villeController,
                        _modeEdition,
                        client.ville,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _infoCard(
                  'Adresse',
                  _adresseController,
                  _modeEdition,
                  client.adresse,
                ),
                const SizedBox(height: 10),
                _infoCard(
                  'Notes',
                  _notesController,
                  _modeEdition,
                  client.notes,
                  maxLines: 3,
                ),
              ],
            ),
          ),

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Équipements configurés',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.texte,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/configurer-equipement',
                        arguments: widget.clientId,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ciel,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        '+ Configurer',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_equipementsClient.isEmpty)
                  const Text(
                    'Aucun équipement configuré pour ce client.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.texteSecondaire,
                    ),
                  )
                else
                  ..._equipementsClient.map((eq) {
                    final bs = badgeStyle(eq.statut);
                    return InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/equipement-client/${eq.id}',
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.fondPage,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eq.equipementNom,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.texte,
                                    ),
                                  ),
                                  Text(
                                    'S/N : ${eq.numeroSerie}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.texteTertiaire,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                eq.dateConfig,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.texteSecondaire,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: bs.background,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                eq.statut,
                                style: TextStyle(
                                  color: bs.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Voir →',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ciel,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),

          Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Abonnements Starlink',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.texte,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/abonnements/nouveau?clientId=${widget.clientId}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ciel,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        '+ Nouvel abonnement',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_abonnementsClient.isEmpty)
                  const Text(
                    'Aucun abonnement pour ce client.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.texteSecondaire,
                    ),
                  )
                else
                  ..._abonnementsClient.map((ab) {
                    final jours = joursRestants(ab.dateFin);
                    final niveau = niveauAlerte(
                      ab.dateFin,
                      ab.statutAbonnement,
                    );
                    final bs = badgeStyle(ab.statutAbonnement);
                    return InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, '/abonnements/${ab.id}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.fondPage,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🛰️ ${ab.kitId}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.texte,
                                    ),
                                  ),
                                  Text(
                                    '${ab.duree} · Fin : ${ab.dateFin}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.texteTertiaire,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: bs.background,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                ab.statutAbonnement,
                                style: TextStyle(
                                  color: bs.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (niveau != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                jours == 0
                                    ? "Expire aujourd'hui"
                                    : (jours != null && jours < 0)
                                    ? 'Expiré (${jours.abs()}j)'
                                    : 'J-$jours',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.rougeTexte,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            const Text(
                              'Voir →',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ciel,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    String label,
    TextEditingController controller,
    bool editable,
    String? valeur, {
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondPage,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
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
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                )
              : Text(
                  valeur ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.texte,
                  ),
                ),
        ],
      ),
    );
  }
}
