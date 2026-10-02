import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/route_guard/route_guard.dart';

/// Équivalent Flutter de NouveauClient.jsx (non fourni), construit directement
/// à partir du cahier des charges — section 3.1.1 "Fiche client".
///
/// Champs repris du CDC :
/// - Numéro client (auto)      -> généré côté backend, pas dans le formulaire
/// - Nom complet *             -> obligatoire
/// - Téléphone *                -> obligatoire, format international
/// - Email                     -> optionnel
/// - Pays *                     -> obligatoire, liste déroulante
/// - Ville *                    -> obligatoire
/// - Adresse                   -> optionnelle
/// - Type de client *           -> Particulier / Entreprise / Revendeur
/// - Date d'entrée (auto)       -> générée côté backend
/// - Statut *                   -> Actif / Inactif / Suspendu (défaut : Actif)
/// - Notes                     -> optionnelles

const List<String> _paysAfrique = [
  'Burkina Faso',
  'Côte d\'Ivoire',
  'Mali',
  'Sénégal',
  'Niger',
  'Togo',
  'Bénin',
  'Ghana',
  'Guinée',
  'Cameroun',
  'RD Congo',
  'Autre',
];

class NouveauClientPage extends StatelessWidget {
  const NouveauClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrivateRoute(child: _NouveauClientPageBody());
  }
}

class _NouveauClientPageBody extends StatefulWidget {
  const _NouveauClientPageBody();

  @override
  State<_NouveauClientPageBody> createState() => _NouveauClientPageBodyState();
}

class _NouveauClientPageBodyState extends State<_NouveauClientPageBody> {
  final _formKey = GlobalKey<FormState>();
  bool _enregistrement = false;
  String _erreur = '';

  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _pays = '';
  final _villeController = TextEditingController();
  final _adresseController = TextEditingController();
  String _typeClient = 'Particulier';
  String _statut = 'Actif';
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _erreur = '');

    if (_nomController.text.trim().isEmpty ||
        _telephoneController.text.trim().isEmpty ||
        _pays.isEmpty ||
        _villeController.text.trim().isEmpty) {
      setState(() => _erreur = 'Tous les champs marqués * sont obligatoires.');
      return;
    }

    setState(() => _enregistrement = true);
    try {
      await LocalStore.addClient(
        nom: _nomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        email: _emailController.text.trim(),
        pays: _pays,
        ville: _villeController.text.trim(),
        adresse: _adresseController.text.trim(),
        typeClient: _typeClient,
        statut: _statut,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/clients');
    } catch (e) {
      setState(() => _erreur = "Erreur lors de l'ajout du client.");
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      titre: 'Nouveau Client',
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/clients'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nom complet *'),
              TextField(
                controller: _nomController,
                decoration: _decoration(hint: 'Nom et prénom du client'),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Téléphone *'),
                        TextField(
                          controller: _telephoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _decoration(
                            hint: 'Ex : +226 70 00 00 00',
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
                        _label('Email'),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _decoration(hint: 'client@email.com'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Pays *'),
                        DropdownButtonFormField<String>(
                          initialValue: _pays.isEmpty ? null : _pays,
                          decoration: _decoration(hint: '-- Sélectionner --'),
                          items: _paysAfrique
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _pays = v ?? ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Ville *'),
                        TextField(
                          controller: _villeController,
                          decoration: _decoration(hint: 'Ville / localité'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _label('Adresse'),
              TextField(
                controller: _adresseController,
                decoration: _decoration(hint: 'Adresse physique détaillée'),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Type de client *'),
                        DropdownButtonFormField<String>(
                          initialValue: _typeClient,
                          decoration: _decoration(),
                          items:
                              const ['Particulier', 'Entreprise', 'Revendeur']
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              setState(() => _typeClient = v ?? _typeClient),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Statut *'),
                        DropdownButtonFormField<String>(
                          initialValue: _statut,
                          decoration: _decoration(),
                          items: const ['Actif', 'Inactif', 'Suspendu']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _statut = v ?? _statut),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _label('Notes'),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: _decoration(hint: 'Remarques libres sur le client'),
              ),

              if (_erreur.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
              ],

              const SizedBox(height: 20),
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
                    _enregistrement ? 'Enregistrement...' : 'Créer le client',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
