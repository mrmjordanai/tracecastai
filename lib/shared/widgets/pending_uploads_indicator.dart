import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/blueprint_colors.dart';
import '../../core/providers/pending_uploads_provider.dart';
import '../../core/providers/connectivity_provider.dart';

/// Badge widget to show pending upload count
///
/// Displays an orange badge with the number of pending/failed uploads.
/// Tapping shows the PendingUploadsBottomSheet.
class PendingUploadsBadge extends ConsumerWidget {
  const PendingUploadsBadge({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingUploadCountProvider);

    return GestureDetector(
      onTap: pendingCount > 0
          ? () => PendingUploadsBottomSheet.show(context)
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (pendingCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: BlueprintColors.accentAction,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: BlueprintColors.shadowColor,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  pendingCount > 99 ? '99+' : pendingCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet showing pending upload queue status
class PendingUploadsBottomSheet extends ConsumerWidget {
  const PendingUploadsBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BlueprintColors.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => const PendingUploadsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingUploadsProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BlueprintColors.tertiaryForeground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Uploads',
                        style: TextStyle(
                          color: BlueprintColors.primaryForeground,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isOnline ? Icons.cloud_done : Icons.cloud_off,
                            size: 14,
                            color: isOnline
                                ? BlueprintColors.successState
                                : BlueprintColors.errorState,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: BlueprintColors.secondaryForeground,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (state.failedCount > 0 && isOnline)
                    TextButton(
                      onPressed: () {
                        ref.read(pendingUploadsProvider.notifier).retryFailed(
                              isOnline: isOnline,
                            );
                      },
                      child: const Text(
                        'Retry All',
                        style: TextStyle(
                          color: BlueprintColors.accentAction,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Processing indicator
            if (state.isProcessing)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BlueprintColors.primaryBackground.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: BlueprintColors.primaryForeground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Processing uploads...',
                      style: TextStyle(
                        color: BlueprintColors.primaryForeground,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Upload list
            Expanded(
              child: state.uploads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_done,
                            size: 48,
                            color: BlueprintColors.tertiaryForeground,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No pending uploads',
                            style: TextStyle(
                              color: BlueprintColors.secondaryForeground,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: state.uploads.length,
                      itemBuilder: (context, index) {
                        final upload = state.uploads[index];
                        return _UploadTile(upload: upload);
                      },
                    ),
            ),

            // Clear completed button
            if (state.uploads.any(
                (u) => u.status == PendingUploadStatus.completed))
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextButton(
                  onPressed: () {
                    ref.read(pendingUploadsProvider.notifier).clearCompleted();
                  },
                  child: const Text(
                    'Clear Completed',
                    style: TextStyle(
                      color: BlueprintColors.secondaryForeground,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UploadTile extends ConsumerWidget {
  const _UploadTile({required this.upload});

  final PendingUpload upload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BlueprintColors.primaryBackground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _buildStatusIcon(),
            ),
          ),

          const SizedBox(width: 12),

          // Upload info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getModeLabel(upload.mode),
                  style: const TextStyle(
                    color: BlueprintColors.primaryForeground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: BlueprintColors.secondaryForeground,
                    fontSize: 12,
                  ),
                ),
                if (upload.error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    upload.error!,
                    style: TextStyle(
                      color: BlueprintColors.errorState,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Actions
          if (upload.status == PendingUploadStatus.failed && isOnline)
            IconButton(
              onPressed: () {
                ref.read(pendingUploadsProvider.notifier).retryUpload(
                      upload.id,
                      isOnline: isOnline,
                    );
              },
              icon: const Icon(
                Icons.refresh,
                color: BlueprintColors.accentAction,
              ),
            ),
          if (upload.status == PendingUploadStatus.queued ||
              upload.status == PendingUploadStatus.failed)
            IconButton(
              onPressed: () {
                ref.read(pendingUploadsProvider.notifier).removeUpload(upload.id);
              },
              icon: const Icon(
                Icons.close,
                color: BlueprintColors.tertiaryForeground,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (upload.status) {
      case PendingUploadStatus.queued:
        return const Icon(
          Icons.schedule,
          color: BlueprintColors.secondaryForeground,
          size: 20,
        );
      case PendingUploadStatus.uploading:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: BlueprintColors.accentAction,
          ),
        );
      case PendingUploadStatus.processing:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: BlueprintColors.primaryForeground,
          ),
        );
      case PendingUploadStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: BlueprintColors.successState,
          size: 20,
        );
      case PendingUploadStatus.failed:
        return const Icon(
          Icons.error,
          color: BlueprintColors.errorState,
          size: 20,
        );
    }
  }

  Color _getStatusColor() {
    switch (upload.status) {
      case PendingUploadStatus.queued:
        return BlueprintColors.secondaryForeground;
      case PendingUploadStatus.uploading:
      case PendingUploadStatus.processing:
        return BlueprintColors.accentAction;
      case PendingUploadStatus.completed:
        return BlueprintColors.successState;
      case PendingUploadStatus.failed:
        return BlueprintColors.errorState;
    }
  }

  Color _getBorderColor() {
    switch (upload.status) {
      case PendingUploadStatus.failed:
        return BlueprintColors.errorState.withValues(alpha: 0.5);
      case PendingUploadStatus.completed:
        return BlueprintColors.successState.withValues(alpha: 0.5);
      default:
        return Colors.transparent;
    }
  }

  String _getStatusText() {
    switch (upload.status) {
      case PendingUploadStatus.queued:
        return 'Waiting to upload...';
      case PendingUploadStatus.uploading:
        return 'Uploading...';
      case PendingUploadStatus.processing:
        return 'Processing with AI...';
      case PendingUploadStatus.completed:
        return 'Completed';
      case PendingUploadStatus.failed:
        return 'Failed${upload.retryCount > 0 ? ' (${upload.retryCount} retries)' : ''}';
    }
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'sewing':
        return 'Sewing Pattern';
      case 'quilting':
        return 'Quilting Template';
      case 'stencil':
        return 'Art Stencil';
      default:
        return 'Pattern Scan';
    }
  }
}
