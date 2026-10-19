// ==============================================================================
// 所属模块: Presentation / Providers
// 文件路径: lib/presentation/providers/worker_provider.dart
// 核心职责: 管理 Worker 列表与发布状态的 Riverpod 提供者
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/worker_model.dart';

class WorkerStateNotifier extends StateNotifier<List<WorkerModel>> {
  WorkerStateNotifier() : super([]);

  void setWorkers(List<WorkerModel> workers) {
    state = workers;
  }

  void addWorker(WorkerModel worker) {
    state = [...state, worker];
  }
}

final workerProvider =
    StateNotifierProvider<WorkerStateNotifier, List<WorkerModel>>((ref) {
  return WorkerStateNotifier();
});
