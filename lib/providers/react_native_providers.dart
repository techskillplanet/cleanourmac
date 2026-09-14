import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/react_native_repository.dart';
import '../domain/models/react_native_project.dart';
import 'infra_providers.dart';

class ReactNativeWorkspaceState {
  final List<ReactNativeProject> projects;
  final List<ProjectOpenOption> openOptions;
  final String? selectedPath;
  final MetroStatus metro;
  final bool loading;
  final Object? error;

  const ReactNativeWorkspaceState({
    this.projects = const [],
    this.openOptions = const [],
    this.selectedPath,
    this.metro = const MetroStatus(running: false, port: 8081),
    this.loading = false,
    this.error,
  });

  ReactNativeProject? get selectedProject {
    for (final project in projects) {
      if (project.path == selectedPath) return project;
    }
    return projects.isEmpty ? null : projects.first;
  }

  ReactNativeWorkspaceState copyWith({
    List<ReactNativeProject>? projects,
    List<ProjectOpenOption>? openOptions,
    String? selectedPath,
    bool clearSelected = false,
    MetroStatus? metro,
    bool? loading,
    Object? error,
    bool clearError = false,
  }) {
    return ReactNativeWorkspaceState(
      projects: projects ?? this.projects,
      openOptions: openOptions ?? this.openOptions,
      selectedPath: clearSelected ? null : selectedPath ?? this.selectedPath,
      metro: metro ?? this.metro,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final reactNativeRepositoryProvider = Provider<ReactNativeRepository>((ref) {
  return ReactNativeRepository(
    ref.watch(homeProvider),
    ref.watch(shellRunnerProvider),
  );
});

final reactNativeWorkspaceProvider =
    StateNotifierProvider<
      ReactNativeWorkspaceNotifier,
      ReactNativeWorkspaceState
    >((ref) {
      final settings = ref.watch(settingsProvider);
      return ReactNativeWorkspaceNotifier(
        ref.watch(reactNativeRepositoryProvider),
        settings.reactNativeRoots,
        settings.metroPort,
      );
    });

class ReactNativeWorkspaceNotifier
    extends StateNotifier<ReactNativeWorkspaceState> {
  final ReactNativeRepository _repository;
  final List<String> _configuredRoots;
  final int _defaultPort;
  final Duration? _refreshInterval;
  Timer? _timer;
  bool _refreshing = false;
  bool _refreshAgain = false;
  bool _checkingMetro = false;
  bool _checkMetroAgain = false;
  bool _disposed = false;

  ReactNativeWorkspaceNotifier(
    this._repository,
    this._configuredRoots,
    this._defaultPort, {
    bool autoStart = true,
    this._refreshInterval = const Duration(seconds: 4),
  }) : super(
         ReactNativeWorkspaceState(
           loading: true,
           metro: MetroStatus(running: false, port: _defaultPort),
         ),
       ) {
    if (autoStart) refresh();
  }

  void setMonitoring(bool enabled) {
    _timer?.cancel();
    _timer = null;
    if (!enabled || _refreshInterval == null || _disposed) return;
    refreshMetro();
    _timer = Timer.periodic(_refreshInterval, (_) => refreshMetro());
  }

  Future<void> refresh() async {
    if (_disposed) return;
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        state = state.copyWith(loading: true, clearError: true);
        try {
          final projects = await _repository
              .discover(_configuredRoots, defaultMetroPort: _defaultPort)
              .timeout(const Duration(seconds: 12));
          if (_disposed) return;
          final selectedPath =
              projects.any((project) => project.path == state.selectedPath)
              ? state.selectedPath
              : projects.isEmpty
              ? null
              : projects.first.path;
          final selectedProject = projects
              .where((project) => project.path == selectedPath)
              .firstOrNull;
          final openOptions = selectedProject == null
              ? const <ProjectOpenOption>[]
              : await _repository
                    .availableOpenOptions(selectedProject)
                    .timeout(const Duration(seconds: 8));
          if (_disposed) return;
          state = state.copyWith(
            projects: projects,
            openOptions: openOptions,
            selectedPath: selectedPath,
            loading: false,
          );
          await refreshMetro();
        } catch (error) {
          if (_disposed) return;
          state = state.copyWith(loading: false, error: error);
        }
      } while (_refreshAgain);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> selectProject(String path) async {
    if (_disposed) return;
    final project = state.projects
        .where((item) => item.path == path)
        .firstOrNull;
    state = state.copyWith(
      selectedPath: path,
      openOptions: const [],
      clearError: true,
    );
    if (project != null) {
      try {
        final openOptions = await _repository
            .availableOpenOptions(project)
            .timeout(const Duration(seconds: 8));
        if (_disposed) return;
        state = state.copyWith(openOptions: openOptions);
      } catch (error) {
        if (_disposed) return;
        state = state.copyWith(error: error);
      }
    }
    refreshMetro();
  }

  Future<void> refreshMetro() async {
    if (_disposed) return;
    if (_checkingMetro) {
      _checkMetroAgain = true;
      return;
    }
    _checkingMetro = true;
    try {
      do {
        _checkMetroAgain = false;
        final project = state.selectedProject;
        final port = project?.metroPort ?? _defaultPort;
        try {
          final metro = await _repository
              .checkMetro(port)
              .timeout(const Duration(seconds: 3));
          if (_disposed) return;
          state = state.copyWith(metro: metro);
        } catch (_) {
          if (_disposed) return;
          state = state.copyWith(
            metro: MetroStatus(running: false, port: port),
          );
        }
      } while (_checkMetroAgain);
    } finally {
      _checkingMetro = false;
    }
  }

  Future<void> runScript(String script) async {
    final project = state.selectedProject;
    if (project == null) return;
    await _repository.runScript(project, script);
    if (script == 'start') {
      await Future<void>.delayed(const Duration(seconds: 1));
      await refreshMetro();
    }
  }

  Future<void> resetMetro() async {
    final project = state.selectedProject;
    if (project == null) return;
    await _repository.startMetroReset(project);
  }

  Future<void> openDevTools() async {
    final project = state.selectedProject;
    if (project == null) return;
    await _repository.openReactNativeDevTools(project);
  }

  Future<void> openProject(ProjectOpenTarget target) async {
    final project = state.selectedProject;
    if (project == null) return;
    await _repository.openProject(project, target);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
