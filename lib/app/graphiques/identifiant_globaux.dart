import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/identifiant/identifiant.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/route_guard/route_guard.dart';

/// Équivalent de CDC 3.2.4 : "Liste globale des équipements [configurés]
/// triée par date de configuration" + "Recherche d'un équipement par numéro
/// de série, par client, par catégorie ou par statut". Contrairement à
/// FicheClientPage (identifiants d'UN client), cette page montre TOUS les
/// identifiants, tous clients confondus.
class IdentifiantsGlobauxPage extends StatelessWidget {
  const IdentifiantsGlobauxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrivateRoute(child: _IdentifiantsGlobauxPageBody());
  }
}

class _IdentifiantsGlobauxPageBody extends StatefulWidget {
  const _IdentifiantsGlobauxPageBody();

  @override
  State<_IdentifiantsGlobauxPageBody> createState() =>
      _IdentifiantsGlobauxPageBodyState();
}

class _IdentifiantsGlobauxPageBodyState
    extends State<_IdentifiantsGlobauxPageBody> {
  List<Identifiant> _identifiants = [];
  bool _chargement = true;
  String _recherche = '';
  String _filtreStatut = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    _identifiants = await LocalStore.rechercherIdentifiants(
      terme: _recherche,
      statut: _filtreStatut,
    );
    setState(() => _chargement = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      titre: 'Identifiants configurés',
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/equipements'),
          child: const Text('← Retour'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue transversale de tous les équipements configurés chez tes clients, tous confondus.',
            style: TextStyle(fontSize: 13, color: AppColors.texteSecondaire),
          ),
          const SizedBox(height: 16),

          TextField(
            decoration: InputDecoration(
              hintText:
                  'Rechercher par numéro de série, client ou équipement...',
              filled: true,
              fillColor: AppColors.fondCarte,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onChanged: (v) {
              _recherche = v;
              _charger();
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _filtreStatut.isEmpty ? null : _filtreStatut,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.fondCarte,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              hintText: 'Tous les statuts',
            ),
            items: const [
              'En service',
              'En panne',
              'Retourné',
              'Remplacement',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              _filtreStatut = v ?? '';
              _charger();
            },
          ),
          const SizedBox(height: 12),
          Text(
            '${_identifiants.length} identifiant(s)',
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
          else if (_identifiants.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Aucun identifiant configuré.',
                  style: TextStyle(color: AppColors.texteSecondaire),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.fondCarte,
                border: Border.all(color: AppColors.bordure),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                children: _identifiants.map((i) => _ligne(context, i)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ligne(BuildContext context, Identifiant i) {
    final bs = badgeStyle(i.statut);
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/equipement-client/${i.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.fondPage)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cielClair,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.marine,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.equipementNom,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte,
                    ),
                  ),
                  Text(
                    'S/N : ${i.numeroSerie}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.texteTertiaire,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/clients/${i.clientId}'),
                child: Text(
                  i.clientNom,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ciel,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                i.dateConfig,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.texteSecondaire,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: bs.background,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                i.statut,
                style: TextStyle(
                  color: bs.color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
