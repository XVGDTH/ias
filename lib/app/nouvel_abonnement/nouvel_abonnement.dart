import 'package:flutter/material.dart';
import 'package:ias/app/abonnement/utils_abonnement.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/client/required_client.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/route_guard/route_guard.dart';

class NouvelAbonnementPage extends StatelessWidget {
  /// Équivalent de useSearchParams().get("clientId") — passe l'id du client
  /// si on arrive depuis la fiche client (route /abonnements/nouveau?clientId=xxx)
  final String? clientIdPresent;
  const NouvelAbonnementPage({super.key, this.clientIdPresent});

  @override
  Widget build(BuildContext context) {
    return PrivateRoute(
      child: _NouvelAbonnementPageBody(clientIdPresent: clientIdPresent),
    );
  }
}

class _NouvelAbonnementPageBody extends StatefulWidget {
  final String? clientIdPresent;
  const _NouvelAbonnementPageBody({this.clientIdPresent});

  @override
  State<_NouvelAbonnementPageBody> createState() =>
      _NouvelAbonnementPageBodyState();
}

class _NouvelAbonnementPageBodyState extends State<_NouvelAbonnementPageBody> {
  List<Client> _clients = [];
  bool _chargement = false;
  String _erreur = '';

  String _clientId = '';
  final _kitIdController = TextEditingController();
  final _dateDebutController = TextEditingController(text: formaterDate());
  String _duree = 'Mensuel';
  final _montantController = TextEditingController();
  String _statutPaiement = 'Payé';

  @override
  void initState() {
    super.initState();
    _clientId = widget.clientIdPresent ?? '';
    _chargerClients();
  }

  @override
  void dispose() {
    _kitIdController.dispose();
    _dateDebutController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _chargerClients() async {
    _clients = await LocalStore.getClients();
    if (mounted) setState(() {});
  }

  Future<void> _handleSubmit() async {
    setState(() => _erreur = '');
    if (_clientId.isEmpty ||
        _kitIdController.text.trim().isEmpty ||
        _montantController.text.trim().isEmpty) {
      setState(() => _erreur = 'Tous les champs marqués * sont obligatoires.');
      return;
    }
    setState(() => _chargement = true);
    try {
      await LocalStore.addAbonnement(
        clientId: _clientId,
        clientNom:
            _clients.where((c) => c.id == _clientId).firstOrNull?.nom ?? '',
        kitId: _kitIdController.text.trim(),
        dateDebut: _dateDebutController.text,
        duree: _duree,
        montant: double.tryParse(_montantController.text) ?? 0,
        statutPaiement: _statutPaiement,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/abonnements');
    } catch (e) {
      setState(() => _erreur = "Erreur lors de l'enregistrement.");
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apercuDateFin = _dateDebutController.text.isNotEmpty
        ? calculerDateFin(_dateDebutController.text, _duree)
        : '';

    return AppShell(
      titre: 'Nouvel abonnement Starlink',
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/abonnements'),
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
            _label('Client *'),
            DropdownButtonFormField<String>(
              initialValue: _clientId.isEmpty ? null : _clientId,
              decoration: _decoration(hint: '-- Sélectionner un client --'),
              items: _clients
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.nom} (${c.ville}, ${c.pays})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _clientId = v ?? ''),
            ),
            const SizedBox(height: 16),

            _label('Numéro du kit Starlink *'),
            TextField(
              controller: _kitIdController,
              decoration: _decoration(hint: 'Numéro de série du kit'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Date de début *'),
                      TextField(
                        controller: _dateDebutController,
                        readOnly: true,
                        decoration: _decoration(),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.tryParse(_dateDebutController.text) ??
                                DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(
                              () => _dateDebutController.text = formaterDate(
                                date,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Durée *'),
                      DropdownButtonFormField<String>(
                        initialValue: _duree,
                        decoration: _decoration(),
                        items: const ['Mensuel', 'Trimestriel', 'Annuel']
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _duree = v ?? _duree),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cielClair,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text.rich(
                TextSpan(
                  text: 'Date de fin calculée automatiquement : ',
                  style: const TextStyle(color: AppColors.marine, fontSize: 13),
                  children: [
                    TextSpan(
                      text: apercuDateFin,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Montant (FCFA) *'),
                      TextField(
                        controller: _montantController,
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
                      _label('Statut du paiement'),
                      DropdownButtonFormField<String>(
                        initialValue: _statutPaiement,
                        decoration: _decoration(),
                        items: const ['Payé', 'En attente', 'Impayé']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) => setState(
                          () => _statutPaiement = v ?? _statutPaiement,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  _chargement ? 'Enregistrement...' : "Créer l'abonnement",
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

extension _FirstOrNullClient<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
