import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/project_cache_repository.dart';
import '../domain/models/project_cache.dart';
import 'infra_providers.dart';

class ProjectCacheState {
  final List<ProjectCacheItem> items;
  final bool scanning;
  final bool cleaning;
  final ProjectCacheCleanupResult? lastResult;
  final Object? error;

  const ProjectCacheState({
    this.items = const [],
    this.scanning = false,
    this.cleaning = false,
    this.lastResult,
    this.error,
  });

  int get totalBytes => items.fold(0, (sum, item) => sum + item.sizeBytes);
  int get selectedBytes => items
      .where((item) => item.selected)
      .fold(0, (sum, item) => sum + item.sizeBytes);
  int get selectedCount => items.where((item) => item.selected).length;
  int get projectCount => items.map((item) => item.projectRoot).toSet().length;

  ProjectCacheState copyWith({
    List<ProjectCacheItem>? items,
    bool? scanning,
    bool? cleaning,
    ProjectCacheCleanupResult? lastResult,
    bool clearLastResult = false,
    Object? error,
    bool clearError = false,
  }) {
    return ProjectCacheState(
      items: items ?? this.items,
      scanning: scanning ?? this.scanning,
      cleaning: cleaning ?? this.cleaning,
      lastResult: clearLastResult ? null : lastResult ?? this.lastResult,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final projectCacheRepositoryProvider = Provider<ProjectCacheRepository>((ref) {
  final settings = ref.watch(settingsProvider);
  return ProjectCacheRepository(
    ref.watch(homeProvider),
    ref.watch(duScannerProvider),
    ref.watch(shellRunnerProvider),
    excludedPaths: settings.excludedPaths,
  );
});

final projectCacheProvider =
    StateNotifierProvider<ProjectCacheNotifier, ProjectCacheState>((ref) {
      final settings = ref.watch(settingsProvider);
      return ProjectCacheNotifier(ref.watch(projectCacheRepositoryProvider), [
        ...settings.developmentRoots,
        ...settings.reactNativeRoots,
        ...settings.nodeModulesRoots,
      ]);
    });

class ProjectCacheNotifier extends StateNotifier<ProjectCacheState> {
  final ProjectCacheRepository _repository;
  final List<String> _roots;

  ProjectCacheNotifier(this._repository, this._roots)
    : super(const ProjectCacheState(scanning: true)) {
    scan();
  }

  Future<void> scan() async {
    state = state.copyWith(
      scanning: true,
      clearError: true,
      clearLastResult: true,
    );
    try {
      state = state.copyWith(
        items: await _repository.scan(_roots),
        scanning: false,
      );
    } catch (error) {
      state = state.copyWith(scanning: false, error: error);
    }
  }

  void toggle(String id, bool selected) {
    state = state.copyWith(
      items: state.items
          .map(
            (item) => item.id == id ? item.copyWith(selected: selected) : item,
          )
          .toList(),
      clearLastResult: true,
    );
  }

  void toggleProject(String root, bool selected) {
    state = state.copyWith(
      items: state.items
          .map(
            (item) => item.projectRoot == root
                ? item.copyWith(selected: selected)
                : item,
          )
          .toList(),
      clearLastResult: true,
    );
  }

  void toggleAll(bool selected) {
    state = state.copyWith(
      items: state.items
          .map((item) => item.copyWith(selected: selected))
          .toList(),
      clearLastResult: true,
    );
  }

  Future<void> cleanSelected() async {
    if (state.cleaning || state.selectedCount == 0) return;
    state = state.copyWith(cleaning: true, clearError: true);
    try {
      final result = await _repository.clean(state.items);
      state = state.copyWith(
        items: await _repository.scan(_roots),
        cleaning: false,
        lastResult: result,
      );
    } catch (error) {
      state = state.copyWith(cleaning: false, error: error);
    }
  }
}
