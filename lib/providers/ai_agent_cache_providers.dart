import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/ai_agent_cache_repository.dart';
import '../domain/models/ai_agent_cache.dart';
import 'infra_providers.dart';

class AiAgentCacheState {
  final List<AiAgentCacheItem> items;
  final bool scanning;
  final bool cleaning;
  final AiAgentCleanupResult? lastResult;
  final Object? error;

  const AiAgentCacheState({
    this.items = const [],
    this.scanning = false,
    this.cleaning = false,
    this.lastResult,
    this.error,
  });

  int get totalBytes => items.fold(0, (total, item) => total + item.sizeBytes);
  int get selectedBytes => items
      .where((item) => item.selected)
      .fold(0, (total, item) => total + item.sizeBytes);
  int get selectedCount => items.where((item) => item.selected).length;
  int get agentCount => items.map((item) => item.target.agent).toSet().length;

  AiAgentCacheState copyWith({
    List<AiAgentCacheItem>? items,
    bool? scanning,
    bool? cleaning,
    AiAgentCleanupResult? lastResult,
    bool clearLastResult = false,
    Object? error,
    bool clearError = false,
  }) {
    return AiAgentCacheState(
      items: items ?? this.items,
      scanning: scanning ?? this.scanning,
      cleaning: cleaning ?? this.cleaning,
      lastResult: clearLastResult ? null : lastResult ?? this.lastResult,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final aiAgentCacheRepositoryProvider = Provider<AiAgentCacheRepository>((ref) {
  return AiAgentCacheRepository(
    ref.watch(homeProvider),
    ref.watch(duScannerProvider),
    ref.watch(pathGuardProvider),
  );
});

final aiAgentCacheProvider =
    StateNotifierProvider<AiAgentCacheNotifier, AiAgentCacheState>((ref) {
      return AiAgentCacheNotifier(ref.watch(aiAgentCacheRepositoryProvider));
    });

class AiAgentCacheNotifier extends StateNotifier<AiAgentCacheState> {
  final AiAgentCacheRepository _repository;

  AiAgentCacheNotifier(
    this._repository, {
    AiAgentCacheState? initialState,
    bool autoScan = true,
  }) : super(initialState ?? const AiAgentCacheState(scanning: true)) {
    if (autoScan) scan();
  }

  Future<void> scan() async {
    state = state.copyWith(
      scanning: true,
      clearError: true,
      clearLastResult: true,
    );
    try {
      final items = await _repository.scan();
      state = state.copyWith(items: items, scanning: false);
    } catch (error) {
      state = state.copyWith(scanning: false, error: error);
    }
  }

  void toggle(String id, bool selected) {
    state = state.copyWith(
      items: state.items
          .map(
            (item) =>
                item.target.id == id ? item.copyWith(selected: selected) : item,
          )
          .toList(),
      clearLastResult: true,
    );
  }

  void toggleAgent(AiAgentKind agent, bool selected) {
    state = state.copyWith(
      items: state.items
          .map(
            (item) => item.target.agent == agent
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
      final items = await _repository.scan();
      state = state.copyWith(items: items, cleaning: false, lastResult: result);
    } catch (error) {
      state = state.copyWith(cleaning: false, error: error);
    }
  }
}
