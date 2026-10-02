import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/equipement/required_equipement.dart';
import 'package:ias/app/identifiant/identifiant.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/mouvement_stock/required_mouvement.dart';
import 'package:ias/app/provider/role_provider.dart';
import 'package:ias/app/route_guard/route_guard.dart';

/// Fiche détail d'un type d'équipement du catalogue (CDC 3.2.1).
/// Distincte de DetailEquipementClientPage, qui concerne un exemplaire
/// (identifiant) configuré chez UN client précis.
class DetailEquipementCataloguePage extends StatelessWidget {
  final String equipementId;
  const DetailEquipementCataloguePage({super.key, required this.equipementId});

  @override
  Widget build(BuildContext context) {
    return PrivateRoute(
      child: _DetailEquipementCataloguePageBody(equipementId: equipementId),
    );
  }
}

class _DetailEquipementCataloguePageBody extends StatefulWidget {
  final String equipementId;
  const _DetailEquipementCataloguePageBody({required this.equipementId});

  @override
  State<_DetailEquipementCataloguePageBody> createState() =>
      _DetailEquipementCataloguePageBodyState();
}

class _DetailEquipementCataloguePageBodyState
    extends State<_DetailEquipementCataloguePageBody> {
  Equipement? _equipement;
  List<Identifiant> _identifiantsLies = [];
  List<Mouvement> _mouvementsLies = [];
  bool _chargement = true;
  bool _modeEdition = false;
  bool _sauvegarde = false;

  final _nomController = TextEditingController();
  final _marqueController = TextEditingController();
  String _categorie = 'Autre';
  final _prixAchatController = TextEditingController();
  final _prixVenteController = TextEditingController();
  final _seuilAlerteController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get peutVoirFinances => RoleProvider.instance.peutVoirFinances;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _marqueController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _seuilAlerteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    _equipement = await LocalStore.getEquipementById(widget.equipementId);
    final tousIdentifiants = await LocalStore.getIdentifiants();
    _identifiantsLies = tousIdentifiants
        .where((i) => i.equipementId == widget.equipementId)
        .toList();
    _mouvementsLies = await LocalStore.getMouvementsParEquipement(
      widget.equipementId,
    );

    if (_equipement != null) {
      final eq = _equipement!;
      _nomController.text = eq.nom;
      _marqueController.text = eq.marque;
      _categorie = eq.categorie;
      _prixAchatController.text = eq.prixAchat.toStringAsFixed(0);
      _prixVenteController.text = eq.prixVente.toStringAsFixed(0);
      _seuilAlerteController.text = eq.seuilAlerte.toString();
      _descriptionController.text = eq.description;
    }
    setState(() => _chargement = false);
  }

  Future<void> _handleSave() async {
    if (_equipement == null) return;
    setState(() => _sauvegarde = true);
    final maj = Equipement(
      id: _equipement!.id,
      nom: _nomController.text.trim(),
      marque: _marqueController.text.trim(),
      categorie: _categorie,
      prixAchat:
          double.tryParse(_prixAchatController.text) ?? _equipement!.prixAchat,
      prixVente:
          double.tryParse(_prixVenteController.text) ?? _equipement!.prixVente,
      stock:
          _equipement!.stock, // le stock ne se modifie que via les mouvements
      seuilAlerte:
          int.tryParse(_seuilAlerteController.text) ?? _equipement!.seuilAlerte,
      description: _descriptionController.text.trim(),
    );
    await LocalStore.updateEquipement(maj);
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
        titre: 'Équipement',
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_equipement == null) {
      return const AppShell(
        titre: 'Équipement',
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

    final eq = _equipement!;
    final stockFaible = eq.stock <= eq.seuilAlerte;

    return AppShell(
      titre: eq.nom,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/equipements'),
          child: const Text('← Retour au catalogue'),
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
          // FICHE PRINCIPALE
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
                          _modeEdition
                              ? TextField(
                                  controller: _nomController,
                                  decoration: _decoration(),
                                )
                              : Text(
                                  eq.nom,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.texte,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          _modeEdition
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: TextField(
                                    controller: _marqueController,
                                    decoration: _decoration(
                                      hint: 'Marque / Modèle',
                                    ),
                                  ),
                                )
                              : Text(
                                  eq.marque,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.texteSecondaire,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${eq.stock}${stockFaible ? ' ⚠️' : ''}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: stockFaible
                                ? AppColors.rouge
                                : AppColors.texte,
                          ),
                        ),
                        const Text(
                          'en stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.texteTertiaire,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 36, color: AppColors.fondPage),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _champInfo(
                        'Catégorie',
                        _modeEdition
                            ? DropdownButtonFormField<String>(
                                initialValue: _categorie,
                                decoration: _decoration(),
                                items:
                                    const [
                                          'Starlink',
                                          'Routeur',
                                          'Antenne',
                                          'Switch',
                                          'Accessoire',
                                          'Autre',
                                        ]
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) => setState(
                                  () => _categorie = v ?? _categorie,
                                ),
                              )
                            : Text(
                                eq.categorie,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.texte,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _champInfo(
                        "Seuil d'alerte stock",
                        _modeEdition
                            ? TextField(
                                controller: _seuilAlerteController,
                                keyboardType: TextInputType.number,
                                decoration: _decoration(),
                              )
                            : Text(
                                '${eq.seuilAlerte}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.texte,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                if (peutVoirFinances) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _champInfo(
                          "Prix d'achat (FCFA)",
                          _modeEdition
                              ? TextField(
                                  controller: _prixAchatController,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration(),
                                )
                              : Text(
                                  eq.prixAchat.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.texte,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _champInfo(
                          'Prix de vente (FCFA)',
                          _modeEdition
                              ? TextField(
                                  controller: _prixVenteController,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration(),
                                )
                              : Text(
                                  eq.prixVente.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.texte,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                _champInfo(
                  'Description',
                  _modeEdition
                      ? TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: _decoration(),
                        )
                      : Text(
                          eq.description.isEmpty ? '—' : eq.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.texte,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // IDENTIFIANTS CONFIGURÉS AVEC CET ÉQUIPEMENT
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
                Text(
                  'Exemplaires configurés (${_identifiantsLies.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texte,
                  ),
                ),
                const SizedBox(height: 14),
                if (_identifiantsLies.isEmpty)
                  const Text(
                    'Aucun exemplaire configuré chez un client pour le moment.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.texteSecondaire,
                    ),
                  )
                else
                  ..._identifiantsLies.map((i) {
                    final bs = badgeStyle(i.statut);
                    return InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/equipement-client/${i.id}',
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
                                    i.clientNom,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.texte,
                                    ),
                                  ),
                                  Text(
                                    'S/N : ${i.numeroSerie}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.texteTertiaire,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              i.dateConfig,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.texteSecondaire,
                              ),
                            ),
                            const SizedBox(width: 10),
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
                                i.statut,
                                style: TextStyle(
                                  color: bs.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
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

          // HISTORIQUE DES MOUVEMENTS DE STOCK
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
                Text(
                  'Historique des mouvements (${_mouvementsLies.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texte,
                  ),
                ),
                const SizedBox(height: 14),
                if (_mouvementsLies.isEmpty)
                  const Text(
                    'Aucun mouvement enregistré pour cet équipement.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.texteSecondaire,
                    ),
                  )
                else
                  ..._mouvementsLies.map((m) {
                    final estEntree = m.typeMouvement == 'Entree';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.fondPage,
                        borderRadius: BorderRadius.circular(AppRadius.md),
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
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${m.quantite} unité(s)',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.texte,
                              ),
                            ),
                          ),
                          Text(
                            m.dateMouvement,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.texteTertiaire,
                            ),
                          ),
                        ],
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

  Widget _champInfo(String label, Widget contenu) {
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
        contenu,
      ],
    );
  }

  InputDecoration _decoration({String? hint}) => InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: AppColors.fondPage,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
  );
}
