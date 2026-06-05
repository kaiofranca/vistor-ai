import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vistor_ai_mobile/app/theme.dart';
import 'package:vistor_ai_mobile/features/inspection/domain/inspection_detail_cubit.dart';
import 'package:vistor_ai_mobile/features/inspection/domain/inspection_detail_state.dart';
import 'package:vistor_ai_mobile/features/inspection/presentation/widgets/severity_badge.dart';
import 'package:vistor_ai_mobile/features/inspection/presentation/widgets/status_timeline.dart';
import 'package:vistor_ai_mobile/shared/models/inspection.dart';
import 'package:vistor_ai_mobile/shared/widgets/error_state.dart';
import 'package:vistor_ai_mobile/shared/widgets/loading_state.dart';
import 'package:vistor_ai_mobile/shared/widgets/glass_card.dart';
import 'package:vistor_ai_mobile/shared/widgets/error_snackbar.dart';

class InspectionDetailScreen extends StatefulWidget {
  const InspectionDetailScreen({super.key});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InspectionDetailCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InspectionDetailCubit, InspectionDetailState>(
      listener: (context, state) {
        state.maybeWhen(
          loaded: (insp, history, updating, generating, error) {
            if (error != null) {
              showErrorSnackbar(context, error);
            }
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        return Scaffold(
          body: state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const AppLoadingState(message: 'Carregando detalhes...'),
            error: (msg) => AppErrorState(
              message: msg,
              onRetry: () => context.read<InspectionDetailCubit>().load(),
            ),
            loaded: (inspection, history, isUpdating, isGenerating, error) => 
                _buildContent(context, inspection, history, isUpdating, isGenerating),
          ),
          bottomNavigationBar: state.maybeMap(
            loaded: (s) => _buildBottomBar(context, s.inspection, s.isGeneratingReport),
            orElse: () => null,
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, 
    Inspection inspection, 
    List<dynamic> history,
    bool isUpdating,
    bool isGenerating,
  ) {
    final heroImageUrl = inspection.media.isNotEmpty 
        ? inspection.media.first.thumbnailUrl ?? '' 
        : '';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            centerTitle: false,
            titlePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SeverityBadge(
                  severity: inspection.severity ?? InspectionSeverity.pendingReview,
                  isLarge: true,
                ),
                const SizedBox(height: 8),
                Text(
                  inspection.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'inspection-${inspection.id}',
                  child: heroImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: heroImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[300]),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(LucideIcons.imageOff, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(LucideIcons.image, size: 64, color: AppColors.primary),
                        ),
                ),
                // Gradient Overlay
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.3, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoGrid(context, inspection),
                const SizedBox(height: AppSpacing.xl),
                if (inspection.aiLabel != null) ...[
                  _buildAiAnalysisSection(context, inspection, isUpdating),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (inspection.media.isNotEmpty) ...[
                  _buildMediaSection(context, inspection),
                  const SizedBox(height: AppSpacing.xl),
                ],
                const Text(
                  'Linha do Tempo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.md),
                StatusTimeline(
                  history: history.cast(),
                  currentStatus: inspection.status,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context, Inspection inspection) {
    final hasAddress = inspection.address != null && inspection.address!.trim().isNotEmpty;
    final displayAddress = hasAddress ? inspection.address! : 'Endereço não disponível';
    
    final locationStr = '$displayAddress\n(${inspection.lat.toStringAsFixed(4)}, ${inspection.lon.toStringAsFixed(4)})';

    return Column(
      children: [
        Row(
          children: [
            _buildInfoItem(
              context, 
              LucideIcons.mapPin, 
              'Localização', 
              locationStr,
            ),
            _buildInfoItem(
              context, 
              _getCategoryIcon(inspection.category), 
              'Categoria', 
              inspection.category,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _buildInfoItem(
              context, 
              LucideIcons.calendar, 
              'Data', 
              DateFormat('dd/MM/yyyy').format(inspection.createdAt),
            ),
            _buildInfoItem(
              context, 
              LucideIcons.user, 
              'Inspetor', 
              inspection.inspector?.name ?? '---',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.subtextLight, fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAnalysisSection(BuildContext context, Inspection inspection, bool isUpdating) {
    final score = inspection.aiScore ?? 0.0;
    final isConfirmed = inspection.humanLabel != null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.bot, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'ANÁLISE DE IA',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            inspection.aiLabel ?? 'Analizando...',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: score,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  color: _getScoreColor(score),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(score * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
            ],
          ),
          if (!isConfirmed) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : () => context.read<InspectionDetailCubit>().confirmAiLabel(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Confirmar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isUpdating ? null : () => _showCorrectionDialog(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Corrigir'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            const Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'Classificação confirmada',
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context, Inspection inspection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mídia',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: inspection.media.length,
          itemBuilder: (context, index) {
            final media = inspection.media[index];
            return GestureDetector(
              onTap: () {
                // TODO: Abrir viewer de imagem/vídeo
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: media.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(LucideIcons.imageOff, color: Colors.grey),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Inspection inspection, bool isGenerating) {
    final canGenerate = inspection.status == InspectionStatus.inProgress || 
                       inspection.status == InspectionStatus.resolved;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: (canGenerate && !isGenerating) 
                    ? () => context.read<InspectionDetailCubit>().generateReport() 
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isGenerating
                    ? const SizedBox(
                        height: 20, width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Gerar Laudo Técnico'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.chevronRight, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.55) return AppColors.offline;
    return AppColors.error;
  }

  void _showCorrectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Corrigir Severidade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSeverityOption(dialogContext, context, 'CRÍTICA', InspectionSeverity.critical, AppColors.error),
            const SizedBox(height: 8),
            _buildSeverityOption(dialogContext, context, 'MODERADA', InspectionSeverity.moderate, AppColors.offline),
            const SizedBox(height: 8),
            _buildSeverityOption(dialogContext, context, 'BAIXA', InspectionSeverity.low),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityOption(
    BuildContext dialogContext, 
    BuildContext screenContext, 
    String label, 
    InspectionSeverity severity, 
    [Color? color]
  ) {
    final effectiveColor = color ?? AppColors.success;
    return ListTile(
      title: Text(label, style: TextStyle(color: effectiveColor, fontWeight: FontWeight.bold)),
      onTap: () {
        screenContext.read<InspectionDetailCubit>().correctAiLabel(severity);
        Navigator.pop(dialogContext);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: effectiveColor.withValues(alpha: 0.1),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'elétrica':
        return LucideIcons.zap;
      case 'civil':
        return LucideIcons.building;
      case 'hidráulica':
        return LucideIcons.droplets;
      case 'estrutural':
        return LucideIcons.construction;
      case 'incêndio':
        return LucideIcons.flame;
      default:
        return LucideIcons.clipboardList;
    }
  }
}
