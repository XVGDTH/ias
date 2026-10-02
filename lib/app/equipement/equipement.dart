import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/equipement/required_equipement.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/provider/role_provider.dart';
import 'package:ias/app/route_guard/route_guard.dart';

class EquipementsPage extends StatelessWidget {
  const EquipementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrivateRoute(child: _EquipementsPageBody());
  }
}

class _EquipementsPageBody extends StatefulWidget {
  const _EquipementsPageBody();

  @override
  State<_EquipementsPageBody> createState() => _EquipementsPageBodyState();
}

class _EquipementsPageBodyState extends State<_EquipementsPageBody> {
  List<Equipement> _equipements = [];
  bool _chargement = true;
  String _recherche = '';
  String _filtreCategorie = '';

  bool get peutVoirFinances => RoleProvider.instance.peutVoirFinances;
  bool get isAdmin => RoleProvider.instance.isAdmin;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    _equipements = await LocalStore.getEquipements();
    setState(() => _chargement = false);
  }

  List<Equipement> get _equipementsFiltres => _equipements.where((eq) {
    final matchRecherche =
        _recherche.isEmpty ||
        eq.nom.toLowerCase().contains(_recherche.toLowerCase()) ||
        eq.marque.toLowerCase().contains(_recherche.toLowerCase());
    final matchCategorie =
        _filtreCategorie.isEmpty || eq.categorie == _filtreCategorie;
    return matchRecherche && matchCategorie;
  }).toList();

  List<String> get _categories =>
      _equipements.map((e) => e.categorie).toSet().toList();

  @override
  Widget build(BuildContext context) {
    // Écoute RoleProvider explicitement pour garantir que les boutons et
    // colonnes réservés à l'Admin apparaissent dès que le rôle est disponible.
    return AnimatedBuilder(
      animation: RoleProvider.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final liste = _equipementsFiltres;

    return AppShell(
      titre: 'Stock & Équipements',
      actions: [
        // CDC section 2 : ces deux actions sont des "créations", autorisées à
        // l'Agent comme à l'Admin (seules la suppression et les paramètres
        // avancés sont réservés à l'Admin) — donc plus de garde `if (isAdmin)`.
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/equipements/stock'),
            child: const Text('↓ Entrée de stock'),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/equipements/nouveau'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ciel,
            foregroundColor: Colors.white,
          ),
          child: const Text('+ Nouveau'),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.ciel, width: 2),
                    ),
                  ),
                  child: const Text(
                    'Catalogue & Stock',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ciel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/equipements/stock'),
                  child: const Text(
                    'Mouvements de stock',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.texteSecondaire,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/equipements/identifiants'),
                  child: const Text(
                    'Identifiants configurés',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.texteSecondaire,
                    ),
                  ),
                ),
              ],
            ),
          ),

          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher dans le catalogue...',
              filled: true,
              fillColor: AppColors.fondCarte,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onChanged: (v) => setState(() => _recherche = v),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _filtreCategorie.isEmpty ? null : _filtreCategorie,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.fondCarte,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              hintText: 'Toutes catégories',
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _filtreCategorie = v ?? ''),
          ),
          const SizedBox(height: 12),
          Text(
            '${liste.length} équipement(s)',
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
          else if (liste.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Aucun équipement trouvé.',
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
                children: liste
                    .map((eq) => _ligneEquipement(context, eq))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ligneEquipement(BuildContext context, Equipement eq) {
    final stockFaible = eq.stock <= eq.seuilAlerte;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/equipements/${eq.id}'),
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
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eq.nom,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte,
                    ),
                  ),
                  Text(
                    eq.marque,
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fondPage,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  eq.categorie,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.texteSecondaire,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (peutVoirFinances)
              Expanded(
                child: Text(
                  eq.prixAchat.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.texteSecondaire,
                  ),
                ),
              ),
            if (peutVoirFinances)
              Expanded(
                child: Text(
                  eq.prixVente.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texte,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                '${eq.stock}${stockFaible ? ' ⚠️' : ''}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: stockFaible ? AppColors.rouge : AppColors.texte,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
