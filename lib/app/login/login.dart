import 'package:flutter/material.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/provider/auth_provider.dart';
import 'package:ias/app/provider/role_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _afficherMdp = false;
  String _erreur = '';
  bool _chargement = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _erreur = '';
      _chargement = true;
    });

    try {
      // ============================================================
      // ZONE DE TEST TEMPORAIRE — à supprimer une fois ton API branchée.
      // Comptes de test :
      //   admin / admin  -> connecté avec le rôle "Admin"
      //   agent / agent  -> connecté avec le rôle "Agent"
      // ============================================================
      final saisieEmail = _emailController.text.trim().toLowerCase();
      final saisieMdp = _passwordController.text.trim();

      String? roleDetecte;
      if (saisieEmail == 'admin' && saisieMdp == 'admin') {
        roleDetecte = 'Admin';
      } else if (saisieEmail == 'agent' && saisieMdp == 'agent') {
        roleDetecte = 'Agent';
      }

      if (roleDetecte == null) {
        throw Exception('Identifiants invalides');
      }

      // TODO: une fois ton API branchée, remplace tout le bloc ci-dessus par :
      // final reponse = await tonApi.login(_emailController.text, _passwordController.text);
      // final roleDetecte = reponse.role; // "Admin" ou "Agent" renvoyé par ton API
      // ============================================================

      RoleProvider.instance.setRole(roleDetecte);
      AuthProvider.instance.setConnecte(true);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() => _erreur = 'Email ou mot de passe incorrect.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;
    final estGrandEcran = largeurEcran > 900;

    return Scaffold(
      body: Row(
        children: [
          // GAUCHE — Formulaire
          Expanded(
            flex: estGrandEcran ? 45 : 100,
            child: Container(
              color: AppColors.fondCarte,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'IAS-TECHNOLOGIE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.marine,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),

                      const Text(
                        'Connectez-vous',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.texte,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accédez à votre espace de gestion IAS TECH',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.texteSecondaire,
                        ),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.texte,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration('votre@email.com'),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Champ requis'
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            const Text(
                              'Mot de passe *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.texte,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_afficherMdp,
                              decoration: _inputDecoration('••••••••').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _afficherMdp
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _afficherMdp = !_afficherMdp,
                                  ),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Champ requis'
                                  : null,
                            ),

                            if (_erreur.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerFond,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                                child: Text(
                                  _erreur,
                                  style: const TextStyle(
                                    color: AppColors.dangerTexte,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _chargement ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.ciel,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _chargement
                                      ? 'Connexion en cours...'
                                      : 'Se connecter',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                      const Text(
                        "WiFiZone — Plateforme de gestion IAS-TECHnologie. Tous droits réservés © 2026.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.texteTertiaire,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // DROITE — Branding (visible seulement sur grand écran)
          if (estGrandEcran)
            Expanded(
              flex: 55,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.marine,
                      Color(0xFF0D4A8A),
                      Color(0xFF1565C0),
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.wifi,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Gestion intelligente\nde votre réseau',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Gérez vos clients, équipements et abonnements Starlink depuis une seule plateforme.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.75),
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Stats
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Row(
                              children: [
                                _statItem('360°', 'Vue complète'),
                                _statDivider(),
                                _statItem('Multi', "Pays d'Afrique"),
                                _statDivider(),
                                _statItem('24/7', 'Alertes temps réel'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Features
                          ...[
                            "Alertes d'expiration Starlink",
                            "Gestion multi-pays",
                            "Stock & équipements",
                            "Tableau de bord analytique",
                          ].map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.ciel.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(String valeur, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valeur,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
    width: 1,
    height: 30,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white.withOpacity(0.15),
  );

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.bordure, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.bordure, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.ciel, width: 1.5),
      ),
    );
  }
}
