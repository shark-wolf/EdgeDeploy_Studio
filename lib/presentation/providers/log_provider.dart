// ==============================================================================
// 所属模块: Presentation / Providers
// 文件路径: lib/presentation/providers/log_provider.dart
// 核心职责: 全局日志状态管理（支持日志启用/关闭开关、追加日志与清空）
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogState {
  final List<String> logs;
  final bool isEnabled;

  const LogState({
    this.logs = const [],
    this.isEnabled = true, // 默认开启
  });

  LogState copyWith({
    List<String>? logs,
    bool? isEnabled,
  }) {
    return LogState(
      logs: logs ?? this.logs,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class LogNotifier extends StateNotifier<LogState> {
  LogNotifier() : super(const LogState());

  /// 追加日志（若日志开关关闭则忽略）
  void appendLog(String log) {
    if (!state.isEnabled) return;
    state = state.copyWith(logs: [...state.logs, log]);
  }

  /// 清空所有日志
  void clear() {
    state = state.copyWith(logs: []);
  }

  /// 切换日志开关状态
  void toggle(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }
}

final logProvider = StateNotifierProvider<LogNotifier, LogState>(
  (ref) => LogNotifier(),
);
