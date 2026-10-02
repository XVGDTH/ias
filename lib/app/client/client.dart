import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/client/required_client.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/route_guard/route_guard.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrivateRoute(child: _ClientsPageBody());
  }
}

class _ClientsPageBody extends StatefulWidget {
  const _ClientsPageBody();

  @override
  State<_ClientsPageBody> createState() => _ClientsPageBodyState();
}

class _ClientsPageBodyState extends State<_ClientsPageBody> {
  List<Client> _clients = [];
  bool _chargement = true;
  String _recherche = '';
  String _filtrePays = '';
  String _filtreStatut = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _chargerClients();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _chargerClients() async {
    setState(() => _chargement = true);
    _clients = await LocalStore.getClients();
    setState(() => _chargement = false);
  }

  void _onRechercheChange(String value) {
    setState(() => _recherche = value);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().isEmpty) {
        _chargerClients();
        return;
      }
      final resultats = await LocalStore.searchClients(value.trim());
      if (mounted) setState(() => _clients = resultats);
    });
  }

  Future<void> _appliquerFiltres() async {
    setState(() => _chargement = true);
    _clients = await LocalStore.filterClients(
      pays: _filtrePays,
      statut: _filtreStatut,
    );
    setState(() => _chargement = false);
  }

  void _reinitialiserFiltres() {
    setState(() {
      _filtrePays = '';
      _filtreStatut = '';
    });
    _chargerClients();
  }

  List<Client> get _clientsAffiches => _clients;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      titre: 'Gestion des Clients',
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/clients/nouveau'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ciel,
            foregroundColor: Colors.white,
          ),
          child: const Text('+ Nouveau Client'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, téléphone, ville, pays...',
              filled: true,
              fillColor: AppColors.fondCarte,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onChanged: _onRechercheChange,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Filtrer par pays',
                    filled: true,
                    fillColor: AppColors.fondCarte,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onChanged: (v) => setState(() => _filtrePays = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filtreStatut.isEmpty ? null : _filtreStatut,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.fondCarte,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    hintText: 'Tous les statuts',
                  ),
                  items: const ['Actif', 'Inactif', 'Suspendu']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _filtreStatut = v ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _appliquerFiltres,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.marine,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Filtrer'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _reinitialiserFiltres,
                  child: const Text('Réinitialiser'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_clientsAffiches.length} client(s) trouvé(s)',
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
          else if (_clientsAffiches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Aucun client trouvé. Ajoutez votre premier client !',
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
                children: _clientsAffiches
                    .map((c) => _ligneClient(context, c))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ligneClient(BuildContext context, Client client) {
    final badge = badgeStyle(client.statut);
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/clients/${client.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.fondPage)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          client.nom,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.texte,
                          ),
                        ),
                      ),
                      if (client.fidele) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAEEDA),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Text(
                            '⭐ Fidèle',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF854F0B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    client.typeClient,
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
              child: Text(
                client.telephone,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.texteSecondaire,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${client.ville}, ${client.pays}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.texteSecondaire,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badge.background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  client.statut,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: badge.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
