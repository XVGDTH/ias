import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/client/required_client.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/equipement/required_equipement.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/route_guard/route_guard.dart';

class ConfigurerEquipementPage extends StatelessWidget {
  final String clientId;
  const ConfigurerEquipementPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return PrivateRoute(
      child: _ConfigurerEquipementPageBody(clientId: clientId),
    );
  }
}

class _ConfigurerEquipementPageBody extends StatefulWidget {
  final String clientId;
  const _ConfigurerEquipementPageBody({required this.clientId});

  @override
  State<_ConfigurerEquipementPageBody> createState() =>
      _ConfigurerEquipementPageBodyState();
}

class _ConfigurerEquipementPageBodyState
    extends State<_ConfigurerEquipementPageBody> {
  Client? _client;
  List<Equipement> _equipements = [];
  bool _chargement = true;
  bool _enregistrement = false;
  String _erreur = '';

  final _numeroSerieController = TextEditingController();
  final _ipController = TextEditingController();
  final _ssidController = TextEditingController();
  final _loginAdminController = TextEditingController();
  final _membreLoginController = TextEditingController();
  final _codeMembreController = TextEditingController();
  final _notesController = TextEditingController();

  String _equipementId = '';
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
    _client = await LocalStore.getClientById(widget.clientId);
    _equipements = await LocalStore.getEquipements();
    setState(() => _chargement = false);
  }

  Future<void> _handleSubmit() async {
    setState(() => _erreur = '');
    if (_numeroSerieController.text.trim().isEmpty) {
      setState(() => _erreur = 'Le numéro de série est obligatoire.');
      return;
    }
    if (_equipementId.isEmpty) {
      setState(() => _erreur = "Sélectionnez le type d'équipement.");
      return;
    }
    setState(() => _enregistrement = true);
    try {
      final eq = _equipements.where((e) => e.id == _equipementId).firstOrNull;
      await LocalStore.ajouterIdentifiant(
        clientId: widget.clientId,
        clientNom: _client?.nom ?? '',
        equipementId: _equipementId,
        equipementNom: eq?.nom ?? '',
        numeroSerie: _numeroSerieController.text.trim(),
        adresseIp: _ipController.text.trim(),
        nomSsid: _ssidController.text.trim(),
        loginAdmin: _loginAdminController.text.trim(),
        membreLogin: _membreLoginController.text.trim(),
        codeMembre: _codeMembreController.text.trim(),
        statut: _statut,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/clients/${widget.clientId}');
    } catch (e) {
      setState(() => _erreur = "Erreur lors de l'enregistrement.");
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const AppShell(
        titre: 'Configurer un équipement',
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppShell(
      titre: 'Configurer un équipement',
      actions: [
        OutlinedButton(
          onPressed: () =>
              Navigator.pushNamed(context, '/clients/${widget.clientId}'),
          child: const Text('← Retour'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.cielClair,
              border: Border.all(color: AppColors.ciel.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.marine, AppColors.ciel],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (_client?.nom ?? '').isNotEmpty
                          ? _client!.nom[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONFIGURATION POUR LE CLIENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.texteSecondaire,
                        ),
                      ),
                      Text(
                        _client?.nom ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.marine,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_client?.ville ?? ''}, ${_client?.pays ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.texteSecondaire,
                  ),
                ),
              ],
            ),
          ),

          _sectionCard(
            numero: '1',
            titre: 'Équipement',
            enfants: [
              Row(
                children: [
                  Expanded(
                    child: _champDropdown(
                      label: "Type d'équipement *",
                      value: _equipementId.isEmpty ? null : _equipementId,
                      items: _equipements
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text('${e.nom} (${e.categorie})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _equipementId = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _champTexte(
                      label: 'Numéro de série / ID unique *',
                      controller: _numeroSerieController,
                      hint: 'S/N, MAC, ID Starlink...',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 260,
                child: _champDropdown(
                  label: 'Statut',
                  value: _statut,
                  items:
                      const [
                            'En service',
                            'En panne',
                            'Retourné',
                            'Remplacement',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _statut = v ?? 'En service'),
                ),
              ),
            ],
          ),

          _sectionCard(
            numero: '2',
            titre: 'Identifiants réseau',
            enfants: [
              Row(
                children: [
                  Expanded(
                    child: _champTexte(
                      label: 'Adresse IP',
                      controller: _ipController,
                      hint: 'Ex : 192.168.1.1',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _champTexte(
                      label: 'SSID (nom du réseau WiFi)',
                      controller: _ssidController,
                      hint: 'Ex : WiFiZone-Client01',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _champTexte(
                label: 'Login / Mot de passe admin',
                controller: _loginAdminController,
                hint: 'Ex : admin / motdepasse123',
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "Ces informations seront visibles en clair par toute l'équipe.",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.texteTertiaire,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),

          _sectionCard(
            numero: '3',
            titre: 'Portail captif (connexion membre)',
            enfants: [
              Row(
                children: [
                  Expanded(
                    child: _champTexte(
                      label: 'Login portail captif',
                      controller: _membreLoginController,
                      hint: 'Ex : membre01',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _champTexte(
                      label: 'Mot de passe portail captif',
                      controller: _codeMembreController,
                      hint: 'Ex : pass1234',
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "Les identifiants du portail sont affichés en clair sur la fiche de l'équipement.",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.texteTertiaire,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),

          _sectionCard(
            numero: '4',
            titre: 'Notes techniques',
            enfants: [
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      "Remarques d'installation, configuration spéciale...",
                  filled: true,
                  fillColor: AppColors.fondPage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ],
          ),

          if (_erreur.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.dangerFond,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                _erreur,
                style: const TextStyle(
                  color: AppColors.dangerTexte,
                  fontSize: 13,
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enregistrement ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ciel,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                _enregistrement
                    ? 'Enregistrement...'
                    : 'Configurer cet équipement pour ce client',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String numero,
    required String titre,
    required List<Widget> enfants,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.fondCarte,
        border: Border.all(color: AppColors.bordure),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.marine,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    numero,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.texte,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...enfants,
        ],
      ),
    );
  }

  Widget _champTexte({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.texte,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.fondPage,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ],
    );
  }

  Widget _champDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.texte,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: '-- Sélectionner --',
            filled: true,
            fillColor: AppColors.fondPage,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

extension _FirstOrNullEquip<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
