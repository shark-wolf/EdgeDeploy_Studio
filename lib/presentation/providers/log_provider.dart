// ==============================================================================
// 所属模块: Presentation / Providers
// 文件路径: lib/presentation/providers/log_provider.dart
// 核心职责: 管理桌面端实时构建与发布日志流的 Riverpod 状态提供者
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogNotifier extends StateNotifier<String> {
  LogNotifier() : super('=== EdgeDeploy-Studio 实时日志控制台已就绪 ===\n');

  void appendLog(String log) {
    state = state + log;
  }

  void clearLogs() {
    state = '=== 日志已清空 ===\n';
  }
}

final logProvider = StateNotifierProvider<LogNotifier, String>((ref) {
  return LogNotifier();
});
