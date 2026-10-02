// import 'package:flutter/material.dart';
// import 'package:ias/app/abonnement/abonnment.dart';
// import 'package:ias/app/client/client.dart';
// import 'package:ias/app/client/detail_equipement_client.dart';
// import 'package:ias/app/configurer_equipement/configuere_equipement.dart';
// import 'package:ias/app/couleur/couleur.dart';
// import 'package:ias/app/dashbaord/dashboard.dart';
// import 'package:ias/app/detail%20abonnement/detail_abonnement.dart';
// import 'package:ias/app/equipement/equipement.dart';
// import 'package:ias/app/fiche%20client/fiche_client.dart';
// import 'package:ias/app/local_store/local_store.dart';
// import 'package:ias/app/login/login.dart';
// import 'package:ias/app/mouvement_stock/mouvement_stock.dart';
// import 'package:ias/app/nouveau_client/nouveau_client.dart';
// import 'package:ias/app/nouvel_abonnement/nouvel_abonnement.dart';
// import 'package:ias/app/nouvel_equipement/nouvel_equipement.dart';
// import 'package:ias/app/placeholder/placeholder.dart';
// import 'package:ias/app/rapport/rapport.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await LocalStore.init();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'IAS-TECHNOLOGIE',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         fontFamily: appFontFamily,
//         scaffoldBackgroundColor: AppColors.fondPage,
//         colorScheme: ColorScheme.fromSeed(seedColor: AppColors.ciel),
//       ),
//       // Route de démarrage — équivalent de <Navigate to="/login" />
//       initialRoute: '/login',
//       onGenerateRoute: (settings) {
//         final uri = Uri.parse(settings.name ?? '');
//         final segments = uri.pathSegments;

//         if (segments.isEmpty) {
//           return MaterialPageRoute(builder: (_) => const LoginPage());
//         }

//         switch (segments.first) {
//           case 'login':
//             return MaterialPageRoute(builder: (_) => const LoginPage());

//           case 'dashboard':
//             return MaterialPageRoute(builder: (_) => const DashboardPage());

//           case 'rapports':
//             return MaterialPageRoute(builder: (_) => const RapportsPage());

//           case 'clients':
//             if (segments.length == 1) {
//               return MaterialPageRoute(builder: (_) => const ClientsPage());
//             }
//             if (segments[1] == 'nouveau') {
//               return MaterialPageRoute(
//                 builder: (_) => const NouveauClientPage(),
//               );
//             }
//             return MaterialPageRoute(
//               builder: (_) => FicheClientPage(clientId: segments[1]),
//             );

//           case 'abonnements':
//             if (segments.length == 1) {
//               return MaterialPageRoute(builder: (_) => const AbonnementsPage());
//             }
//             if (segments[1] == 'nouveau') {
//               // Équivalent de useSearchParams().get("clientId")
//               final clientId = uri.queryParameters['clientId'];
//               return MaterialPageRoute(
//                 builder: (_) => NouvelAbonnementPage(clientIdPresent: clientId),
//               );
//             }
//             return MaterialPageRoute(
//               builder: (_) => DetailAbonnementPage(abonnementId: segments[1]),
//             );

//           case 'equipements':
//             if (segments.length == 1) {
//               return MaterialPageRoute(builder: (_) => const EquipementsPage());
//             }
//             if (segments[1] == 'nouveau') {
//               return MaterialPageRoute(
//                 builder: (_) => const NouvelEquipementPage(),
//               );
//             }
//             if (segments[1] == 'stock') {
//               return MaterialPageRoute(
//                 builder: (_) => const MouvementsStockPage(),
//               );
//             }
//             // TODO: page détail équipement du catalogue pas encore fournie
//             return MaterialPageRoute(
//               builder: (_) => const PlaceholderPage(
//                 titre: 'Détail équipement',
//                 messagePage:
//                     "La fiche détaillée d'un équipement du catalogue n'a pas encore été fournie. "
//                     "Envoie-moi le fichier React correspondant (probablement DetailEquipement.jsx) pour que je la convertisse.",
//               ),
//             );

//           case 'equipement-client':
//             if (segments.length >= 2) {
//               return MaterialPageRoute(
//                 builder: (_) => DetailEquipementClientPage(itemId: segments[1]),
//               );
//             }
//             break;
//         }

//         return MaterialPageRoute(builder: (_) => const LoginPage());
//       },
//       routes: {
//         // Route nommée directe pour configurer un équipement pour un client
//         // Utilisation: Navigator.pushNamed(context, '/configurer-equipement', arguments: clientId)
//         '/configurer-equipement': (context) {
//           final clientId = ModalRoute.of(context)!.settings.arguments as String;
//           return ConfigurerEquipementPage(clientId: clientId);
//         },
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:ias/app/abonnement/abonnment.dart';
import 'package:ias/app/catalogue/detail-equipement-catalogue.dart';
import 'package:ias/app/client/client.dart';
import 'package:ias/app/client/detail_equipement_client.dart';
import 'package:ias/app/configurer_equipement/configuere_equipement.dart';
import 'package:ias/app/couleur/couleur.dart';
import 'package:ias/app/dashbaord/dashboard.dart';
import 'package:ias/app/detail%20abonnement/detail_abonnement.dart';
import 'package:ias/app/equipement/equipement.dart';
import 'package:ias/app/fiche%20client/fiche_client.dart';
import 'package:ias/app/graphiques/identifiant_globaux.dart';
import 'package:ias/app/local_store/local_store.dart';
import 'package:ias/app/login/login.dart';
import 'package:ias/app/mouvement_stock/mouvement_stock.dart';
import 'package:ias/app/nouveau_client/nouveau_client.dart';
import 'package:ias/app/nouvel_abonnement/nouvel_abonnement.dart';
import 'package:ias/app/nouvel_equipement/nouvel_equipement.dart';
import 'package:ias/app/rapport/rapport.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IAS-TECHNOLOGIE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: appFontFamily,
        scaffoldBackgroundColor: AppColors.fondPage,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.ciel),
      ),
      // Route de démarrage — équivalent de <Navigate to="/login" />
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        final segments = uri.pathSegments;

        if (segments.isEmpty) {
          return MaterialPageRoute(builder: (_) => const LoginPage());
        }

        switch (segments.first) {
          case 'login':
            return MaterialPageRoute(builder: (_) => const LoginPage());

          case 'dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardPage());

          case 'rapports':
            return MaterialPageRoute(builder: (_) => const RapportsPage());

          case 'clients':
            if (segments.length == 1) {
              return MaterialPageRoute(builder: (_) => const ClientsPage());
            }
            if (segments[1] == 'nouveau') {
              return MaterialPageRoute(
                builder: (_) => const NouveauClientPage(),
              );
            }
            return MaterialPageRoute(
              builder: (_) => FicheClientPage(clientId: segments[1]),
            );

          case 'abonnements':
            if (segments.length == 1) {
              return MaterialPageRoute(builder: (_) => const AbonnementsPage());
            }
            if (segments[1] == 'nouveau') {
              // Équivalent de useSearchParams().get("clientId")
              final clientId = uri.queryParameters['clientId'];
              return MaterialPageRoute(
                builder: (_) => NouvelAbonnementPage(clientIdPresent: clientId),
              );
            }
            return MaterialPageRoute(
              builder: (_) => DetailAbonnementPage(abonnementId: segments[1]),
            );

          case 'equipements':
            if (segments.length == 1) {
              return MaterialPageRoute(builder: (_) => const EquipementsPage());
            }
            if (segments[1] == 'nouveau') {
              return MaterialPageRoute(
                builder: (_) => const NouvelEquipementPage(),
              );
            }
            if (segments[1] == 'stock') {
              return MaterialPageRoute(
                builder: (_) => const MouvementsStockPage(),
              );
            }
            if (segments[1] == 'identifiants') {
              return MaterialPageRoute(
                builder: (_) => const IdentifiantsGlobauxPage(),
              );
            }
            return MaterialPageRoute(
              builder: (_) =>
                  DetailEquipementCataloguePage(equipementId: segments[1]),
            );

          case 'equipement-client':
            if (segments.length >= 2) {
              return MaterialPageRoute(
                builder: (_) => DetailEquipementClientPage(itemId: segments[1]),
              );
            }
            break;
        }

        return MaterialPageRoute(builder: (_) => const LoginPage());
      },
      routes: {
        // Route nommée directe pour configurer un équipement pour un client
        // Utilisation: Navigator.pushNamed(context, '/configurer-equipement', arguments: clientId)
        '/configurer-equipement': (context) {
          final clientId = ModalRoute.of(context)!.settings.arguments as String;
          return ConfigurerEquipementPage(clientId: clientId);
        },
      },
    );
  }
}
