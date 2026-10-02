import 'package:flutter/material.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/provider/auth_provider.dart';
import 'package:ias/app/role_user/role_user.dart';

/// Équivalent de PrivateRoute.js — enveloppe les pages qui nécessitent
/// d'être connecté. Redirige vers /login si non connecté.
class PrivateRoute extends StatelessWidget {
  final Widget child;
  const PrivateRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthProvider.instance,
      builder: (context, _) {
        if (AuthProvider.instance.chargementInitial) {
          return const Scaffold(
            backgroundColor: AppColors.fondPage,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!AuthProvider.instance.estConnecte) {
          // Redirection vers /login au prochain frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          });
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}

/// Équivalent de AdminRoute.js — enveloppe les pages réservées aux admins.
/// Redirige vers /dashboard si l'utilisateur n'est pas Admin.
class AdminRoute extends StatelessWidget {
  final Widget child;
  const AdminRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: RoleProvider.instance,
      builder: (context, _) {
        if (RoleProvider.instance.chargement) {
          return const Scaffold(
            backgroundColor: AppColors.fondPage,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!RoleProvider.instance.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
          });
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}
