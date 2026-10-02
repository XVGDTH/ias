import 'package:flutter/foundation.dart';

/// Équivalent du hook `useRole()` (React).
/// Toute la logique Firebase Auth / Airtable a été retirée.
/// Après TON appel d'authentification (API perso), appelle
/// RoleProvider.instance.setRole("Admin") ou autre pour mettre à jour le rôle.
class RoleProvider extends ChangeNotifier {
  RoleProvider._();
  static final RoleProvider instance = RoleProvider._();

  String? _role;
  bool chargement = false;

  String? get role => _role;

  bool get isAdmin => _role == 'Admin';
  bool get peutVoirFinances => isAdmin;
  bool get peutGererStock => isAdmin;

  /// À appeler depuis ta propre logique d'authentification / API
  void setRole(String? role) {
    _role = role;
    notifyListeners();
  }

  /// À appeler à la déconnexion (équivalent du cache vidé dans le useEffect React)
  void clear() {
    _role = null;
    notifyListeners();
  }
}
