import 'package:flutter/material.dart';
import 'package:vistor_ai_mobile/app/theme.dart';
import 'package:vistor_ai_mobile/shared/models/inspection.dart';

class SeverityBadge extends StatelessWidget {
  final InspectionSeverity? severity;

  const SeverityBadge({
    super.key,
    this.severity,
  });

  @override
  Widget build(BuildContext context) {
    if (severity == null) {
      return const SizedBox.shrink();
    }

    final Color bgColor;
    final Color textColor;
    final String label;

    switch (severity!) {
      case InspectionSeverity.critical:
        bgColor = AppColors.criticalBg;
        textColor = Colors.white;
        label = 'Crítica';
        break;
      case InspectionSeverity.moderate:
        bgColor = AppColors.moderateBg;
        textColor = Colors.white;
        label = 'Moderada';
        break;
      case InspectionSeverity.low:
        bgColor = AppColors.lowBg;
        textColor = Colors.white;
        label = 'Baixa';
        break;
      case InspectionSeverity.pendingReview:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        label = 'Pendente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
