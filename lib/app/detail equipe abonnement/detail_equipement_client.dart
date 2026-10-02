import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/identifiant/identifiant.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/route_guard/route_guard.dart';

// Alias vers le modèle centralisé Identifiant (LocalStore).
typedef ItemEquipementConfigure = Identifiant;

class DetailEquipementClientPage extends StatelessWidget {
  final String itemId;
  const DetailEquipementClientPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return PrivateRoute(child: _DetailEquipementClientPageBody(itemId: itemId));
  }
}

class _DetailEquipementClientPageBody extends StatefulWidget {
  final String itemId;
  const _DetailEquipementClientPageBody({required this.itemId});

  @override
  State<_DetailEquipementClientPageBody> createState() =>
      _DetailEquipementClientPageBodyState();
}

class _DetailEquipementClientPageBodyState
    extends State<_DetailEquipementClientPageBody> {
  ItemEquipementConfigure? _item;
  bool _chargement = true;
  bool _modeEdition = false;
  bool _sauvegarde = false;

  final _numeroSerieController = TextEditingController();
  final _ipController = TextEditingController();
  final _ssidController = TextEditingController();
  final _loginAdminController = TextEditingController();
  final _membreLoginController = TextEditingController();
  final _codeMembreController = TextEditingController();
  final _notesController = TextEditingController();
  String _statut = 'En service';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _numeroSerieController.dispose();
    _ipController.dispose();
    _ssidController.dispose();
    _loginAdminController.dispose();
    _membreLoginController.dispose();
    _codeMembreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    _item = await LocalStore.getIdentifiantById(widget.itemId);
    if (_item != null) {
      final it = _item!;
      _numeroSerieController.text = it.numeroSerie;
      _ipController.text = it.adresseIp;
      _ssidController.text = it.nomSsid;
      _loginAdminController.text = it.loginAdmin;
      _membreLoginController.text = it.membreLogin;
      _codeMembreController.text = it.codeMembre;
      _notesController.text = it.notes;
      _statut = it.statut;
    }
    setState(() => _chargement = false);
  }

  Future<void> _handleSave() async {
    setState(() => _sauvegarde = true);
    if (_item != null) {
      final maj = _item!.copyWith(
        numeroSerie: _numeroSerieController.text,
        adresseIp: _ipController.text,
        nomSsid: _ssidController.text,
        loginAdmin: _loginAdminController.text,
        membreLogin: _membreLoginController.text,
        codeMembre: _codeMembreController.text,
        statut: _statut,
        notes: _notesController.text,
      );
      await LocalStore.updateIdentifiant(maj);
    }
    await _charger();
    setState(() {
      _modeEdition = false;
      _sauvegarde = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const AppShell(
        titre: 'Équipement configuré',
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_item == null) {
      return const AppShell(
        titre: 'Équipement configuré',
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

    final item = _item!;
    final bs = badgeStyle(item.statut);

    return AppShell(
      titre: item.equipementNom,
      actions: [
        OutlinedButton(
          onPressed: () =>
              Navigator.pushNamed(context, '/clients/${item.clientId}'),
          child: const Text('← Retour client'),
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
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.cielClair,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 28,
                    color: AppColors.marine,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.equipementNom,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.texte,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/clients/${item.clientId}',
                        ),
                        child: Text(
                          item.clientNom,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.ciel,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _modeEdition
                    ? DropdownButton<String>(
                        value: _statut,
                        items:
                            const [
                                  'En service',
                                  'En panne',
                                  'Retourné',
                                  'Remplacement',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) =>
                            setState(() => _statut = v ?? _statut),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: bs.background,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          item.statut,
                          style: TextStyle(
                            color: bs.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ],
            ),
            const Divider(height: 40, color: AppColors.fondPage),

            _sectionTitre('Identification'),
            _identGrid([
              _identItem(
                'Numéro de série / ID',
                _numeroSerieController,
                _modeEdition,
                item.numeroSerie,
              ),
              _identItemStatique('Date de configuration', item.dateConfig),
            ]),

            _sectionTitre('Identifiants réseau'),
            _identGrid([
              _identItem(
                'Adresse IP',
                _ipController,
                _modeEdition,
                item.adresseIp,
                hint: '192.168.1.1',
              ),
              _identItem(
                'SSID (nom du réseau)',
                _ssidController,
                _modeEdition,
                item.nomSsid,
              ),
            ]),
            const SizedBox(height: 12),
            _identItemPleineLargeur(
              'Login / Mot de passe admin',
              _loginAdminController,
              _modeEdition,
              item.loginAdmin,
            ),

            _sectionTitre('Portail captif (connexion membre)'),
            _identGrid([
              _identItem(
                'Login portail',
                _membreLoginController,
                _modeEdition,
                item.membreLogin,
              ),
              _identItem(
                'Mot de passe portail',
                _codeMembreController,
                _modeEdition,
                item.codeMembre,
              ),
            ]),

            _sectionTitre('Notes techniques'),
            _modeEdition
                ? TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.fondCarte,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  )
                : Text(
                    item.notes.isEmpty ? 'Aucune note.' : item.notes,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.texte,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitre(String texte) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: Text(
        texte,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.texteSecondaire,
        ),
      ),
    );
  }

  Widget _identGrid(List<Widget> enfants) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          enfants
              .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
              .toList()
            ..removeLast(),
    );
  }

  Widget _identItem(
    String label,
    TextEditingController controller,
    bool editable,
    String? valeur, {
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 6),
          editable
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hint,
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

  Widget _identItemStatique(String label, String? valeur) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 6),
          Text(
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

  Widget _identItemPleineLargeur(
    String label,
    TextEditingController controller,
    bool editable,
    String? valeur,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 6),
          editable
              ? TextField(
                  controller: controller,
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
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cielClair,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    valeur ?? '—',
                    style: const TextStyle(
                      color: AppColors.marine,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
