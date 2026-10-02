import 'package:flutter/foundation.dart';

/// Équivalent de l'état d'authentification (Firebase Auth) utilisé par PrivateRoute.js.
/// Toute la logique Firebase a été retirée : branche ta propre logique d'auth
/// (API perso) et appelle AuthProvider.instance.setConnecte(true/false) en conséquence.
class AuthProvider extends ChangeNotifier {
  AuthProvider._();
  static final AuthProvider instance = AuthProvider._();

  bool _estConnecte = false;
  bool chargementInitial = false; // équivalent du "loading" de useAuthState

  bool get estConnecte => _estConnecte;

  /// À appeler depuis ta propre logique de connexion / API
  void setConnecte(bool connecte) {
    _estConnecte = connecte;
    notifyListeners();
  }
}
