import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/client/required_client.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/equipement/required_equipement.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/mouvement_stock/required_mouvement.dart';
import 'package:ias/app/provider/role_provider.dart';
import 'package:ias/app/route_guard/route_guard.dart';

class MouvementsStockPage extends StatelessWidget {
  const MouvementsStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    // CDC section 2 / 3.2.2 : enregistrer une entrée ou une sortie de stock
    // est une action de "création", explicitement autorisée pour l'Agent.
    // Cette page reste donc accessible à tout utilisateur connecté.
    return const PrivateRoute(child: _MouvementsStockPageBody());
  }
}

class _MouvementsStockPageBody extends StatefulWidget {
  const _MouvementsStockPageBody();

  @override
  State<_MouvementsStockPageBody> createState() =>
      _MouvementsStockPageBodyState();
}

class _MouvementsStockPageBodyState extends State<_MouvementsStockPageBody> {
  List<Mouvement> _mouvements = [];
  List<Equipement> _equipements = [];
  List<Client> _clients = [];
  bool _chargement = true;
  String _onglet = 'liste';
  bool _enregistrement = false;
  String _erreur = '';
  String _succes = '';

  bool get peutVoirFinances => RoleProvider.instance.peutVoirFinances;

  // Formulaire entrée
  String _entreeEquipementId = '';
  final _entreeQuantiteController = TextEditingController();
  final _entreePrixController = TextEditingController();
  final _entreeFournisseurController = TextEditingController();
  final _entreeNotesController = TextEditingController();

  // Formulaire sortie
  String _sortieEquipementId = '';
  final _sortieQuantiteController = TextEditingController();
  final _sortiePrixController = TextEditingController();
  String _sortieClientId = '';
  final _sortieNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerTout();
  }

  @override
  void dispose() {
    _entreeQuantiteController.dispose();
    _entreePrixController.dispose();
    _entreeFournisseurController.dispose();
    _entreeNotesController.dispose();
    _sortieQuantiteController.dispose();
    _sortiePrixController.dispose();
    _sortieNotesController.dispose();
    super.dispose();
  }

  Future<void> _chargerTout() async {
    setState(() => _chargement = true);
    _mouvements = await LocalStore.getMouvementsStock();
    _equipements = await LocalStore.getEquipements();
    _clients = await LocalStore.getClients();
    setState(() => _chargement = false);
  }

  Future<void> _handleSubmitEntree() async {
    setState(() {
      _erreur = '';
      _succes = '';
    });
    if (_entreeEquipementId.isEmpty || _entreeQuantiteController.text.isEmpty) {
      setState(() => _erreur = 'Équipement et quantité obligatoires.');
      return;
    }
    setState(() => _enregistrement = true);
    try {
      final eq = _equipements
          .where((e) => e.id == _entreeEquipementId)
          .firstOrNull;
      await LocalStore.enregistrerEntree(
        equipementId: _entreeEquipementId,
        equipementNom: eq?.nom ?? '',
        quantite: int.tryParse(_entreeQuantiteController.text) ?? 0,
        prixUnitaire: double.tryParse(_entreePrixController.text) ?? 0,
        fournisseur: _entreeFournisseurController.text.trim(),
        notes: _entreeNotesController.text.trim(),
        auteur: RoleProvider.instance.isAdmin ? 'Administrateur' : 'Agent',
      );
      setState(() => _succes = 'Entrée enregistrée !');
      _entreeQuantiteController.clear();
      _entreePrixController.clear();
      _entreeFournisseurController.clear();
      _entreeNotesController.clear();
      setState(() => _entreeEquipementId = '');
      await _chargerTout();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _succes = '');
      });
    } catch (e) {
      setState(() => _erreur = "Erreur lors de l'enregistrement.");
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  Future<void> _handleSubmitSortie() async {
    setState(() {
      _erreur = '';
      _succes = '';
    });
    if (_sortieEquipementId.isEmpty || _sortieQuantiteController.text.isEmpty) {
      setState(() => _erreur = 'Équipement et quantité obligatoires.');
      return;
    }
    final eq = _equipements
        .where((e) => e.id == _sortieEquipementId)
        .firstOrNull;
    final quantiteDemandee = int.tryParse(_sortieQuantiteController.text) ?? 0;
    if (eq != null && quantiteDemandee > eq.stock) {
      setState(() => _erreur = 'Stock insuffisant ! Disponible : ${eq.stock}');
      return;
    }
    setState(() => _enregistrement = true);
    try {
      final eqSortie = _equipements
          .where((e) => e.id == _sortieEquipementId)
          .firstOrNull;
      final clientSortie = _clients
          .where((c) => c.id == _sortieClientId)
          .firstOrNull;
      await LocalStore.enregistrerSortie(
        equipementId: _sortieEquipementId,
        equipementNom: eqSortie?.nom ?? '',
        quantite: int.tryParse(_sortieQuantiteController.text) ?? 0,
        prixUnitaire:
            double.tryParse(_sortiePrixController.text) ??
            (eqSortie?.prixVente ?? 0),
        clientId: _sortieClientId,
        clientNom: clientSortie?.nom ?? '',
        notes: _sortieNotesController.text.trim(),
        auteur: RoleProvider.instance.isAdmin ? 'Administrateur' : 'Agent',
      );
      setState(() => _succes = 'Sortie enregistrée !');
      _sortieQuantiteController.clear();
      _sortiePrixController.clear();
      _sortieNotesController.clear();
      setState(() {
        _sortieEquipementId = '';
        _sortieClientId = '';
      });
      await _chargerTout();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _succes = '');
      });
    } catch (e) {
      setState(() => _erreur = "Erreur lors de l'enregistrement.");
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      titre: 'Mouvements de stock',
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/equipements'),
          child: const Text('← Retour'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Onglets
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.bordure)),
            ),
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                _ongletBtn('liste', 'Historique'),
                _ongletBtn('entree', 'Nouvelle entrée'),
                _ongletBtn('sortie', 'Nouvelle sortie'),
              ],
            ),
          ),

          if (_succes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.succesFond,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                _succes,
                style: const TextStyle(
                  color: AppColors.succesTexte,
                  fontSize: 13,
                ),
              ),
            ),
          if (_erreur.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
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

          if (_onglet == 'entree') _formEntree(),
          if (_onglet == 'sortie') _formSortie(),
          if (_onglet == 'liste') _listeHistorique(),
        ],
      ),
    );
  }

  Widget _ongletBtn(String key, String label) {
    final actif = _onglet == key;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton(
        onPressed: () => setState(() => _onglet = key),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(
              color: actif ? AppColors.ciel : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: actif ? AppColors.ciel : AppColors.texteSecondaire,
            fontWeight: actif ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _formEntree() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.fondCarte,
        border: Border.all(color: AppColors.bordure),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enregistrer une entrée de stock',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.texte,
            ),
          ),
          const SizedBox(height: 18),
          if (_equipements.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.attenteFond,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                "Ton catalogue d'équipements est vide — va d'abord dans Stock & Équipements > + Nouveau pour créer au moins un type d'équipement.",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.attenteTexte,
                ),
              ),
            ),
          _champLabel('Équipement *'),
          DropdownButtonFormField<String>(
            initialValue: _entreeEquipementId.isEmpty
                ? null
                : _entreeEquipementId,
            decoration: _inputDecoration(
              hint: _equipements.isEmpty ? 'Aucun équipement disponible' : null,
            ),
            items: _equipements
                .map(
                  (eq) => DropdownMenuItem(
                    value: eq.id,
                    child: Text('${eq.nom} (stock : ${eq.stock})'),
                  ),
                )
                .toList(),
            onChanged: _equipements.isEmpty
                ? null
                : (v) => setState(() => _entreeEquipementId = v ?? ''),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _champLabel('Quantité *'),
                    TextField(
                      controller: _entreeQuantiteController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(),
                    ),
                  ],
                ),
              ),
              if (peutVoirFinances) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _champLabel("Prix d'achat unitaire"),
                      TextField(
                        controller: _entreePrixController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _champLabel('Fournisseur'),
          TextField(
            controller: _entreeFournisseurController,
            decoration: _inputDecoration(hint: 'Ex : Grossiste...'),
          ),
          const SizedBox(height: 14),
          _champLabel('Notes'),
          TextField(
            controller: _entreeNotesController,
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enregistrement ? null : _handleSubmitEntree,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.succesTexte,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                _enregistrement ? 'Enregistrement...' : "Enregistrer l'entrée",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formSortie() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.fondCarte,
        border: Border.all(color: AppColors.bordure),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enregistrer une sortie de stock',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.texte,
            ),
          ),
          const SizedBox(height: 18),
          if (_equipements.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.attenteFond,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                "Ton catalogue d'équipements est vide — va d'abord dans Stock & Équipements > + Nouveau pour créer au moins un type d'équipement.",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.attenteTexte,
                ),
              ),
            ),
          _champLabel('Équipement *'),
          DropdownButtonFormField<String>(
            initialValue: _sortieEquipementId.isEmpty
                ? null
                : _sortieEquipementId,
            decoration: _inputDecoration(),
            items: _equipements
                .map(
                  (eq) => DropdownMenuItem(
                    value: eq.id,
                    child: Text('${eq.nom} (stock : ${eq.stock})'),
                  ),
                )
                .toList(),
            onChanged: _equipements.isEmpty
                ? null
                : (v) => setState(() => _sortieEquipementId = v ?? ''),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _champLabel('Quantité *'),
                    TextField(
                      controller: _sortieQuantiteController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (peutVoirFinances) _champLabel('Prix de vente unitaire'),
                    TextField(
                      controller: _sortiePrixController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _champLabel('Client (optionnel)'),
          DropdownButtonFormField<String>(
            initialValue: _sortieClientId.isEmpty ? null : _sortieClientId,
            decoration: _inputDecoration(hint: '-- Aucun client --'),
            items: _clients
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom)))
                .toList(),
            onChanged: (v) => setState(() => _sortieClientId = v ?? ''),
          ),
          const SizedBox(height: 14),
          _champLabel('Notes'),
          TextField(
            controller: _sortieNotesController,
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enregistrement ? null : _handleSubmitSortie,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rouge,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                _enregistrement ? 'Enregistrement...' : 'Enregistrer la sortie',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listeHistorique() {
    if (_chargement) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_mouvements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Aucun mouvement enregistré.',
            style: TextStyle(color: AppColors.texteSecondaire),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.fondCarte,
        border: Border.all(color: AppColors.bordure),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: _mouvements.map((m) {
          final estEntree = m.typeMouvement == 'Entree';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.fondPage)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: estEntree
                        ? AppColors.succesFond
                        : AppColors.dangerFond,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    estEntree ? 'Entrée' : 'Sortie',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: estEntree
                          ? AppColors.succesTexte
                          : AppColors.dangerTexte,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    m.equipementNom,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${m.quantite} × ${m.prixUnitaire.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.texteSecondaire,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    m.fournisseur.isNotEmpty
                        ? m.fournisseur
                        : (m.clientNom.isNotEmpty ? m.clientNom : '—'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.texteSecondaire,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      m.dateMouvement,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.texteTertiaire,
                      ),
                    ),
                    if (m.auteur.isNotEmpty)
                      Text(
                        m.auteur,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.texteTertiaire,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _champLabel(String texte) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texte,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.texte,
      ),
    ),
  );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.fondPage,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
