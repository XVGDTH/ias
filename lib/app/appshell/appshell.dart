import 'package:flutter/material.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/provider/auth_provider.dart';
import 'package:ias/app/provider/role_provider.dart';

class NavItem {
  final String route;
  final String label;
  final IconData icon;
  const NavItem(this.route, this.label, this.icon);
}

const List<NavItem> _navItemsBase = [
  NavItem('/dashboard', 'Tableau de bord', Icons.grid_view_rounded),
  NavItem('/clients', 'Clients', Icons.people_outline),
  NavItem('/equipements', 'Stock & Équipements', Icons.inventory_2_outlined),
  NavItem('/abonnements', 'Abonnements', Icons.wifi),
];
const NavItem _navItemRapports = NavItem(
  '/rapports',
  'Rapports',
  Icons.bar_chart_rounded,
);

/// Équivalent du composant Layout.jsx.
/// Utilisation : Scaffold géré en interne — appelle simplement
/// AppShell(titre: "...", actions: [...], child: ...) dans le build() de chaque page.
class AppShell extends StatelessWidget {
  final String? titre;
  final List<Widget>? actions;
  final Widget child;

  const AppShell({super.key, this.titre, this.actions, required this.child});

  List<NavItem> get _items {
    final isAdmin = RoleProvider.instance.isAdmin;
    return isAdmin ? [..._navItemsBase, _navItemRapports] : _navItemsBase;
  }

  Future<void> _handleLogout(BuildContext context) async {
    // TODO: brancher ton API de déconnexion ici si nécessaire
    AuthProvider.instance.setConnecte(false);
    RoleProvider.instance.clear();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;
    final estGrandEcran = largeurEcran > 900;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    final sidebar = _Sidebar(
      items: _items,
      currentRoute: currentRoute,
      onLogout: () => _handleLogout(context),
    );

    return Scaffold(
      backgroundColor: AppColors.fondPage,
      drawer: estGrandEcran ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (estGrandEcran) SizedBox(width: 240, child: sidebar),
          Expanded(
            child: Column(
              children: [
                // Barre supérieure
                Container(
                  color: AppColors.fondCarte,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      if (!estGrandEcran)
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Recherche globale...',
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 18,
                                color: AppColors.texteTertiaire,
                              ),
                              filled: true,
                              fillColor: AppColors.fondPage,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.cielClair,
                        child: Text(
                          RoleProvider.instance.isAdmin ? 'AD' : 'AG',
                          style: const TextStyle(
                            color: AppColors.marine,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu de la page
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (titre != null || actions != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 10,
                                children: [
                                  if (titre != null)
                                    Text(
                                      titre!,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.texte,
                                      ),
                                    ),
                                  if (actions != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: actions!,
                                    ),
                                ],
                              ),
                            ),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<NavItem> items;
  final String currentRoute;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.items,
    required this.currentRoute,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.marine,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo / titre
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
            child: Row(
              children: const [
                Icon(Icons.wifi, color: Colors.white, size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'IASTECH-WiFiZone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items de navigation
          ...items.map((item) {
            final actif = currentRoute.startsWith(item.route);
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Material(
                color: actif ? AppColors.ciel : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () {
                    if (!actif) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(item.route, (route) => false);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: actif ? Colors.white : const Color(0xFFB5D4F4),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: actif
                                ? Colors.white
                                : const Color(0xFFB5D4F4),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // Footer — utilisateur connecté + déconnexion
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF2A4A7A))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connecté en tant que',
                  style: TextStyle(color: Color(0xFFB5D4F4), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  RoleProvider.instance.isAdmin ? 'Administrateur' : 'Agent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB5D4F4),
                      side: const BorderSide(color: Color(0xFF2A4A7A)),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                    child: const Text(
                      'Déconnexion',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
