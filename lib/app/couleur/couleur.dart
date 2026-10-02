import 'package:flutter/material.dart';

/// Équivalent de `colors` (theme.js) — à ajuster selon ta charte graphique.
/// Toutes les pages importent ce fichier pour rester cohérentes.
class AppColors {
  AppColors._();

  static const Color marine = Color(0xFF0F1B2D);
  static const Color ciel = Color(0xFF2E9BE6);
  static const Color cielClair = Color(0xFFE8F3FC);

  static const Color texte = Color(0xFF0F1B2D);
  static const Color texteSecondaire = Color(0xFF5A6B7D);
  static const Color texteTertiaire = Color(0xFF97A3B0);

  static const Color bordure = Color(0xFFE2E6EC);
  static const Color fondPage = Color(0xFFF5F7FA);
  static const Color fondCarte = Color(0xFFFFFFFF);

  static const Color dangerFond = Color(0xFFFCE9E9);
  static const Color dangerTexte = Color(0xFFC0392B);
  static const Color rouge = Color(0xFFE74C3C);
  static const Color rougeTexte = Color(0xFFB33A2E);

  static const Color attenteFond = Color(0xFFFAEEDA);
  static const Color attenteTexte = Color(0xFF854F0B);

  static const Color succesFond = Color(0xFFE0FBF4);
  static const Color succesTexte = Color(0xFF0EA5A0);
}

/// Équivalent de `radius` (theme.js)
class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double pill = 999;
}

/// Équivalent de `fontFamily` (theme.js)
/// Remplace 'Inter' par la police que tu utilises réellement dans pubspec.yaml
const String appFontFamily = 'Inter';

/// Helper équivalent à `badgeStyle(statut)` utilisé dans plusieurs pages React.
/// Retourne (fond, texte) selon le statut.
class BadgeStyle {
  final Color background;
  final Color color;
  const BadgeStyle(this.background, this.color);
}

BadgeStyle badgeStyle(String? statut) {
  switch (statut) {
    case 'Actif':
    case 'Payé':
    case 'En service':
      return const BadgeStyle(AppColors.succesFond, AppColors.succesTexte);
    case 'Suspendu':
    case 'En attente':
    case 'En panne':
      return const BadgeStyle(AppColors.attenteFond, AppColors.attenteTexte);
    case 'Expiré':
    case 'Résilié':
    case 'Inactif':
    case 'Impayé':
      return const BadgeStyle(AppColors.dangerFond, AppColors.dangerTexte);
    default:
      return BadgeStyle(AppColors.fondPage, AppColors.texteSecondaire);
  }
}