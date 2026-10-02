import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/provider/role_provider.dart';
import 'package:ias/app/route_guard/route_guard.dart';

class NouvelEquipementPage extends StatelessWidget {
  const NouvelEquipementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // CDC section 2 : l'Agent a le droit de "lecture et création" — ajouter un
    // équipement au catalogue est une action de création, pas une suppression
    // ni un paramètre avancé. Cette page doit donc rester accessible à l'Agent
    // (PrivateRoute), pas réservée à l'Admin (AdminRoute redirigeait à tort
    // vers /dashboard pour tout utilisateur non-Admin, y compris par erreur
    // pour un Admin si le rôle n'était pas encore résolu).
    return const PrivateRoute(child: _NouvelEquipementPageBody());
  }
}

class _NouvelEquipementPageBody extends StatefulWidget {
  const _NouvelEquipementPageBody();

  @override
  State<_NouvelEquipementPageBody> createState() =>
      _NouvelEquipementPageBodyState();
}

class _NouvelEquipementPageBodyState extends State<_NouvelEquipementPageBody> {
  bool _chargement = false;
  String _erreur = '';

  final _nomController = TextEditingController();
  String _categorie = 'Routeur';
  final _marqueController = TextEditingController();
  final _prixAchatController = TextEditingController();
  final _prixVenteController = TextEditingController();
  final _seuilAlerteController = TextEditingController(text: '3');
  final _descriptionController = TextEditingController();

  bool get peutVoirFinances => RoleProvider.instance.peutVoirFinances;

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

  Future<void> _handleSubmit() async {
    setState(() => _erreur = '');
    if (_nomController.text.trim().isEmpty) {
      setState(() => _erreur = 'Le nom est obligatoire.');
      return;
    }
    // Les prix ne sont obligatoires que pour l'Admin (qui voit les finances)
    if (peutVoirFinances &&
        (_prixAchatController.text.isEmpty ||
            _prixVenteController.text.isEmpty)) {
      setState(
        () => _erreur = "Les prix d'achat et de vente sont obligatoires.",
      );
      return;
    }

    setState(() => _chargement = true);
    try {
      await LocalStore.addEquipement(
        nom: _nomController.text.trim(),
        categorie: _categorie,
        marque: _marqueController.text.trim(),
        prixAchat: double.tryParse(_prixAchatController.text) ?? 0,
        prixVente: double.tryParse(_prixVenteController.text) ?? 0,
        seuilAlerte: int.tryParse(_seuilAlerteController.text) ?? 0,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/equipements');
    } catch (e) {
      setState(() => _erreur = "Erreur lors de l'ajout.");
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      titre: 'Nouvel équipement',
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/equipements'),
          child: const Text('← Retour'),
        ),
      ],
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(28),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Nom de l'équipement *"),
                      TextField(
                        controller: _nomController,
                        decoration: _decoration(
                          hint: 'Ex : Kit Starlink Standard',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Catégorie *'),
                      DropdownButtonFormField<String>(
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
                        onChanged: (v) =>
                            setState(() => _categorie = v ?? _categorie),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _label('Marque / Modèle'),
            TextField(
              controller: _marqueController,
              decoration: _decoration(hint: 'Ex : MikroTik hAP ac2'),
            ),
            const SizedBox(height: 16),

            if (peutVoirFinances) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Prix d'achat (FCFA) *"),
                        TextField(
                          controller: _prixAchatController,
                          keyboardType: TextInputType.number,
                          decoration: _decoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Prix de vente (FCFA) *'),
                        TextField(
                          controller: _prixVenteController,
                          keyboardType: TextInputType.number,
                          decoration: _decoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            _label("Seuil d'alerte stock"),
            TextField(
              controller: _seuilAlerteController,
              keyboardType: TextInputType.number,
              decoration: _decoration(),
            ),
            const SizedBox(height: 16),

            _label('Description'),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _decoration(),
            ),

            if (_erreur.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _erreur,
                style: const TextStyle(
                  color: AppColors.rougeTexte,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _chargement ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ciel,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(
                  _chargement
                      ? 'Enregistrement...'
                      : "Enregistrer l'équipement",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String texte) => Padding(
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

  InputDecoration _decoration({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.fondPage,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  );
}
