import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/progression_group.dart';

class ProgressionChart extends StatelessWidget {
  final List<ProgressionPoint> points;
  final double height;

  const ProgressionChart({
    super.key,
    required this.points,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Sin registros suficientes',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    if (points.length == 1) {
      final point = points.first;
      return Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.flag, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marca Inicial: ${point.weightDisplay}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Registrada el ${point.formattedDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Carga un nuevo PR con estas mismas repeticiones para ver la curva de progresión.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ProgressionChartPainter(points: points),
      ),
    );
  }
}

class _ProgressionChartPainter extends CustomPainter {
  final List<ProgressionPoint> points;

  _ProgressionChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 32.0;
    const double paddingRight = 28.0;
    const double paddingTop = 24.0;
    const double paddingBottom = 28.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final weights = points.map((p) => p.weightKg).toList();
    final double rawMinWeight = weights.reduce(math.min);
    final double rawMaxWeight = weights.reduce(math.max);

    // Añadir margen vertical para que las líneas y etiquetas no toquen los bordes
    double weightSpan = rawMaxWeight - rawMinWeight;
    if (weightSpan == 0) weightSpan = 10.0;
    final double minY = math.max(0.0, rawMinWeight - weightSpan * 0.2);
    final double maxY = rawMaxWeight + weightSpan * 0.2;
    final double yRange = maxY - minY;

    // Líneas guía horizontales de fondo
    final gridPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    const int gridDivisions = 3;
    for (int i = 0; i <= gridDivisions; i++) {
      final y = paddingTop + (chartHeight / gridDivisions) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
    }

    // Calcular coordenadas de cada punto
    final List<Offset> offsets = [];
    final int count = points.length;
    for (int i = 0; i < count; i++) {
      final x = paddingLeft + (chartWidth / (count - 1)) * i;
      final normalizedY = (points[i].weightKg - minY) / yRange;
      final y = paddingTop + chartHeight * (1.0 - normalizedY);
      offsets.add(Offset(x, y));
    }

    // Path del área sombreada con degradado
    final fillPath = Path();
    fillPath.moveTo(offsets.first.dx, size.height - paddingBottom);
    fillPath.lineTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      fillPath.lineTo(offsets[i].dx, offsets[i].dy);
    }
    fillPath.lineTo(offsets.last.dx, size.height - paddingBottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    // Path de la línea principal de progreso
    final linePath = Path();
    linePath.moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      linePath.lineTo(offsets[i].dx, offsets[i].dy);
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Dibujar puntos y etiquetas de valor/fecha
    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotInnerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final point = points[i];

      // Círculo blanco exterior y azul interior
      canvas.drawCircle(offset, 6.0, dotOuterPaint);
      canvas.drawCircle(offset, 4.0, dotInnerPaint);

      // Etiqueta de peso arriba del punto
      final isMax = point.weightKg == rawMaxWeight;
      textPainter.text = TextSpan(
        text: point.weightDisplay,
        style: TextStyle(
          color: isMax ? AppColors.primaryDark : AppColors.textPrimary,
          fontSize: isMax ? 11.5 : 10.5,
          fontWeight: isMax ? FontWeight.bold : FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          offset.dx - (textPainter.width / 2),
          offset.dy - textPainter.height - 4,
        ),
      );

      // Etiqueta de fecha abajo
      textPainter.text = TextSpan(
        text: point.formattedDate,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9.5,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          offset.dx - (textPainter.width / 2),
          size.height - paddingBottom + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressionChartPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if (oldDelegate.points[i].weightKg != points[i].weightKg ||
          oldDelegate.points[i].date != points[i].date) {
        return true;
      }
    }
    return false;
  }
}
