import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/models/piece_model.dart';
import '../../../../app/theme/blueprint_colors.dart';

/// A list tile for displaying a piece in a project
/// Features: thumbnail preview, status indicator, confidence badge
class PieceListTile extends StatelessWidget {
  final PieceModel piece;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PieceListTile({
    super.key,
    required this.piece,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  /// Get status icon and color
  (IconData, Color) _getStatusIndicator() {
    switch (piece.status) {
      case PieceStatus.pending:
        return (Icons.hourglass_empty, Colors.orange);
      case PieceStatus.processing:
        return (Icons.sync, Colors.yellow);
      case PieceStatus.complete:
        return (Icons.check_circle, BlueprintColors.successState);
      case PieceStatus.failed:
        return (Icons.error, BlueprintColors.errorState);
    }
  }

  /// Get confidence color
  Color _getConfidenceColor() {
    final confidence = piece.scaleConfidence;
    if (confidence >= 0.8) return BlueprintColors.successState;
    if (confidence >= 0.5) return Colors.orange;
    return BlueprintColors.errorState;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusIcon, statusColor) = _getStatusIndicator();
    final isProcessing = piece.isProcessing;

    return Dismissible(
      key: ValueKey(piece.pieceId),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Piece?'),
                content: Text(
                  'Are you sure you want to delete "${piece.name}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Semantics(
        label: '${piece.name}, ${piece.status.name} status, '
            '${(piece.scaleConfidence * 100).round()} percent confidence',
        button: true,
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isProcessing ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail or processing indicator
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: piece.sourceImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: piece.sourceImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const _LoadingPlaceholder(),
                                errorWidget: (_, __, ___) =>
                                    const _PiecePlaceholder(),
                              )
                            : const _PiecePlaceholder(),
                      ),
                      // Status badge
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: BlueprintColors.primaryBackground,
                            shape: BoxShape.circle,
                          ),
                          child: isProcessing
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: statusColor,
                                  ),
                                )
                              : Icon(
                                  statusIcon,
                                  size: 16,
                                  color: statusColor,
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Piece info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          piece.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Dimensions
                            if (piece.widthMm > 0 && piece.heightMm > 0) ...[
                              Text(
                                '${piece.widthMm.toStringAsFixed(0)} × ${piece.heightMm.toStringAsFixed(0)} mm',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            // Scale method badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                piece.scaleMethod.name.toUpperCase(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (piece.qa.warnings.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    piece.qa.warnings.first,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.orange,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Confidence badge
                  if (piece.isComplete) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(piece.scaleConfidence * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getConfidenceColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Chevron
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class _PiecePlaceholder extends StatelessWidget {
  const _PiecePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.content_cut,
        color: Colors.white54,
        size: 24,
      ),
    );
  }
}
