import 'package:flutter/material.dart';
import 'package:ias/app/appshell/appshell.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/route_guard/route_guard.dart';

/// Page temporaire affichée pour les routes dont le code React ne m'a pas
/// encore été fourni (ex: NouveauClient.jsx). Remplacée dès que tu envoies
/// le fichier correspondant.
class PlaceholderPage extends StatelessWidget {
  final String titre;
  final String messagePage;

  const PlaceholderPage({
    super.key,
    required this.titre,
    required this.messagePage,
  });

  @override
  Widget build(BuildContext context) {
    return PrivateRoute(
      child: AppShell(
        titre: titre,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('← Retour'),
          ),
        ],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.fondCarte,
            border: Border.all(color: AppColors.bordure),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_outlined,
                color: AppColors.attenteTexte,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Page pas encore convertie',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.texte,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                messagePage,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.texteSecondaire,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
