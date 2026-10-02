import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ias/app/couleur/couleur.dart';

/// Un point nommé pour les histogrammes / lignes (label affiché sur l'axe X).
class PointGraphique {
  final String label;
  final double valeur;
  const PointGraphique(this.label, this.valeur);
}

/// Une série nommée pour les graphiques à plusieurs courbes (ex: Entrées vs Sorties).
class SerieGraphique {
  final String nom;
  final Color couleur;
  final List<double> valeurs;
  const SerieGraphique({
    required this.nom,
    required this.couleur,
    required this.valeurs,
  });
}

const List<Color> paletteCirculaire = [
  AppColors.ciel,
  AppColors.marine,
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFF06B6D4),
  Color(0xFFEC4899),
];

/// Histogramme simple (barres verticales), utilisé pour le chiffre d'affaires
/// par jour / semaine / mois (CDC 3.4.2).
class BarChartWidget extends StatelessWidget {
  final List<PointGraphique> donnees;
  final Color couleur;
  final double hauteur;
  final String Function(double)? formatValeur;

  const BarChartWidget({
    super.key,
    required this.donnees,
    this.couleur = AppColors.ciel,
    this.hauteur = 200,
    this.formatValeur,
  });

  @override
  Widget build(BuildContext context) {
    if (donnees.isEmpty) {
      return SizedBox(
        height: hauteur,
        child: const Center(
          child: Text(
            'Aucune donnée',
            style: TextStyle(color: AppColors.texteTertiaire),
          ),
        ),
      );
    }
    final maxVal = donnees
        .map((d) => d.valeur)
        .fold<double>(0, (a, b) => a > b ? a : b)
        .clamp(1, double.infinity)
        .toDouble();

    return SizedBox(
      height: hauteur,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: donnees.map((d) {
          final hBarre = (d.valeur / maxVal) * (hauteur - 40);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formatValeur != null
                        ? formatValeur!(d.valeur)
                        : d.valeur.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.texteSecondaire,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: hBarre < 4 ? 4 : hBarre,
                    decoration: BoxDecoration(
                      color: couleur,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.texteSecondaire,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Diagramme circulaire (donut), utilisé pour les répartitions
/// (clients par statut, par pays...) — CDC 3.4.2.
class DonutChartWidget extends StatelessWidget {
  final Map<String, int> donnees;
  final double taille;

  const DonutChartWidget({super.key, required this.donnees, this.taille = 140});

  @override
  Widget build(BuildContext context) {
    final entries = donnees.entries.where((e) => e.value > 0).toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    if (entries.isEmpty || total == 0) {
      return SizedBox(
        height: taille,
        child: const Center(
          child: Text(
            'Aucune donnée',
            style: TextStyle(color: AppColors.texteTertiaire, fontSize: 12),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: taille,
          height: taille,
          child: CustomPaint(
            painter: _DonutPainter(
              entries.map((e) => e.value.toDouble()).toList(),
              paletteCirculaire,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: entries.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final pct = (e.value / total * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: paletteCirculaire[i % paletteCirculaire.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.texte,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${e.value} (${pct.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.texteSecondaire,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final strokeWidth = size.width * 0.24;
    double startAngle = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values;
}

/// Graphique en courbes (axes X/Y), utilisé pour l'évolution du stock
/// (entrées vs sorties dans le temps) — CDC 3.4.2.
class LineChartWidget extends StatelessWidget {
  final List<String> labelsX;
  final List<SerieGraphique> series;
  final double hauteur;

  const LineChartWidget({
    super.key,
    required this.labelsX,
    required this.series,
    this.hauteur = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (labelsX.isEmpty || series.isEmpty) {
      return SizedBox(
        height: hauteur,
        child: const Center(
          child: Text(
            'Aucune donnée',
            style: TextStyle(color: AppColors.texteTertiaire),
          ),
        ),
      );
    }

    final toutesValeurs = series.expand((s) => s.valeurs);
    final maxVal = toutesValeurs
        .fold<double>(0, (a, b) => a > b ? a : b)
        .clamp(1, double.infinity)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: series
              .map(
                (s) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.couleur,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.nom,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.texteSecondaire,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: hauteur,
          child: CustomPaint(
            size: Size.infinite,
            painter: _LineChartPainter(
              series: series,
              maxVal: maxVal,
              nbPoints: labelsX.length,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Labels de l'axe X — on n'affiche qu'un sous-ensemble si trop nombreux
        Row(
          children: _labelsAffiches()
              .map(
                (l) => Expanded(
                  child: Text(
                    l,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.texteTertiaire,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  List<String> _labelsAffiches() {
    if (labelsX.length <= 8) return labelsX;
    // Affiche au maximum ~8 labels pour éviter le chevauchement
    final pas = (labelsX.length / 8).ceil();
    return [for (var i = 0; i < labelsX.length; i += pas) labelsX[i]];
  }
}

class _LineChartPainter extends CustomPainter {
  final List<SerieGraphique> series;
  final double maxVal;
  final int nbPoints;

  _LineChartPainter({
    required this.series,
    required this.maxVal,
    required this.nbPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nbPoints < 2) return;

    // Grille horizontale légère (axe Y)
    final gridPaint = Paint()
      ..color = AppColors.bordure
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dx = size.width / (nbPoints - 1);

    for (final serie in series) {
      final path = Path();
      for (var i = 0; i < serie.valeurs.length && i < nbPoints; i++) {
        final x = dx * i;
        final y = size.height - (serie.valeurs[i] / maxVal) * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final linePaint = Paint()
        ..color = serie.couleur
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      // Points
      final pointPaint = Paint()..color = serie.couleur;
      for (var i = 0; i < serie.valeurs.length && i < nbPoints; i++) {
        final x = dx * i;
        final y = size.height - (serie.valeurs[i] / maxVal) * size.height;
        canvas.drawCircle(Offset(x, y), 3, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}
