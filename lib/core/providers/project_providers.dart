import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project_model.dart';
import '../models/piece_model.dart';
import '../services/project_service.dart';
import 'auth_provider.dart';

// Re-export models for convenience
export '../models/project_model.dart';
export '../models/piece_model.dart';

/// Projects state for UI consumption
class ProjectsState {
  final List<ProjectModel> projects;
  final bool isLoading;
  final String? error;
  final ProjectModel? selectedProject;
  final double overallScaleConfidence;

  const ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
    this.selectedProject,
    this.overallScaleConfidence = 0.0,
  });

  ProjectsState copyWith({
    List<ProjectModel>? projects,
    bool? isLoading,
    String? error,
    ProjectModel? selectedProject,
    double? overallScaleConfidence,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedProject: selectedProject ?? this.selectedProject,
      overallScaleConfidence:
          overallScaleConfidence ?? this.overallScaleConfidence,
    );
  }
}

/// Projects notifier - manages project list state with Firestore integration
class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final ProjectService _projectService;
  final String? _userId;
  StreamSubscription<List<ProjectModel>>? _projectsSubscription;

  ProjectsNotifier(this._projectService, this._userId)
      : super(const ProjectsState()) {
    if (_userId != null) {
      _subscribeToProjects();
    }
  }

  /// Subscribe to real-time project updates from Firestore
  void _subscribeToProjects() {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    _projectsSubscription?.cancel();
    _projectsSubscription = _projectService.watchProjects(_userId).listen(
      (projects) {
        state = state.copyWith(
          projects: projects,
          isLoading: false,
        );
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.toString(),
        );
      },
    );
  }

  /// Create a new project
  Future<ProjectModel?> createProject({
    required String name,
    required PatternMode mode,
    List<String> tags = const [],
  }) async {
    if (_userId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }

    try {
      final project = await _projectService.createProject(
        userId: _userId,
        name: name,
        mode: mode,
        tags: tags,
      );
      return project;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update a project
  Future<void> updateProject({
    required String projectId,
    String? name,
    PatternMode? mode,
    String? thumbnailUrl,
    List<String>? tags,
  }) async {
    if (_userId == null) return;

    try {
      await _projectService.updateProject(
        userId: _userId,
        projectId: projectId,
        name: name,
        mode: mode,
        thumbnailUrl: thumbnailUrl,
        tags: tags,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    if (_userId == null) return;

    try {
      await _projectService.deleteProject(_userId, projectId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Duplicate a project
  Future<ProjectModel?> duplicateProject(String projectId) async {
    if (_userId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }

    try {
      return await _projectService.duplicateProject(_userId, projectId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Select a project for viewing/editing
  void selectProject(ProjectModel? project) {
    state = state.copyWith(selectedProject: project);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }
}

/// Projects state provider with Firestore real-time sync
final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  final projectService = ref.watch(projectServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  return ProjectsNotifier(projectService, userId);
});

/// Selected project provider (convenience accessor)
final selectedProjectProvider = Provider<ProjectModel?>((ref) {
  return ref.watch(projectsProvider).selectedProject;
});

/// Recent projects provider (last 5)
final recentProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final projects = ref.watch(projectsProvider).projects;
  final sorted = [...projects]
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return sorted.take(5).toList();
});

/// Overall scale confidence provider
/// Calculates the average scale confidence across all complete pieces
/// This uses the aggregated confidence from pieces via FutureProvider
final overallScaleConfidenceProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final projectService = ref.watch(projectServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;
  final projects = ref.watch(projectsProvider).projects;

  if (userId == null || projects.isEmpty) {
    return 0.0;
  }

  // Aggregate confidence from all projects
  double totalConfidence = 0.0;
  int projectsWithPieces = 0;

  for (final project in projects) {
    if (project.pieceCount > 0) {
      try {
        final confidence = await projectService.getProjectScaleConfidence(
          userId,
          project.projectId,
        );
        if (confidence > 0) {
          totalConfidence += confidence;
          projectsWithPieces++;
        }
      } catch (_) {
        // Skip projects that error
      }
    }
  }

  if (projectsWithPieces == 0) {
    return 0.0;
  }

  return totalConfidence / projectsWithPieces;
});

/// Projects stream provider (direct Firestore stream)
/// Use this for StreamBuilder patterns or when you need the raw stream
final projectsStreamProvider =
    StreamProvider.autoDispose<List<ProjectModel>>((ref) {
  final projectService = ref.watch(projectServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) {
    return Stream.value([]);
  }

  return projectService.watchProjects(userId);
});

/// Single project provider for detail screens
/// Usage: ref.watch(projectProvider(projectId))
final projectProvider =
    FutureProvider.autoDispose.family<ProjectModel?, String>((ref, projectId) {
  final projectService = ref.watch(projectServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) {
    return Future.value(null);
  }

  return projectService.getProject(userId, projectId);
});

/// Pieces stream for a project
/// Usage: ref.watch(piecesStreamProvider(projectId))
final piecesStreamProvider = StreamProvider.autoDispose
    .family<List<PieceModel>, String>((ref, projectId) {
  final projectService = ref.watch(projectServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) {
    return Stream.value([]);
  }

  return projectService.watchPieces(userId, projectId);
});

/// Single piece provider for editor/detail screens
/// Usage: ref.watch(pieceProvider((projectId: 'abc', pieceId: 'def')))
final pieceProvider = FutureProvider.autoDispose
    .family<PieceModel?, ({String projectId, String pieceId})>((ref, ids) {
  final projectService = ref.watch(projectServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) {
    return Future.value(null);
  }

  return projectService.getPiece(userId, ids.projectId, ids.pieceId);
});

/// Projects filtered by mode
/// Usage: ref.watch(projectsByModeProvider(PatternMode.sewing))
final projectsByModeProvider = StreamProvider.autoDispose
    .family<List<ProjectModel>, PatternMode>((ref, mode) {
  final projectService = ref.watch(projectServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) {
    return Stream.value([]);
  }

  return projectService.watchProjectsByMode(userId, mode);
});
