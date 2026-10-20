// ==============================================================================
// 所属模块: Presentation / Providers
// 文件路径: lib/presentation/providers/deployment_status_provider.dart
// 核心职责: 全局管理本系统发布的 Worker 与 Pages 列表及各自的发布状态
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeployType { worker, page }

enum DeployStatus { idle, deploying, success, failed }

class DeployedItem {
  final String id;
  final String name;
  final DeployType type;
  final DeployStatus status;
  final String message;
  final String timestamp;

  const DeployedItem({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.message,
    required this.timestamp,
  });

  DeployedItem copyWith({
    DeployStatus? status,
    String? message,
    String? timestamp,
  }) {
    return DeployedItem(
      id: id,
      name: name,
      type: type,
      status: status ?? this.status,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class DeploymentStatusModel {
  final List<DeployedItem> items;

  const DeploymentStatusModel({this.items = const []});

  DeploymentStatusModel copyWith({List<DeployedItem>? items}) {
    return DeploymentStatusModel(items: items ?? this.items);
  }
}

class DeploymentStatusNotifier extends StateNotifier<DeploymentStatusModel> {
  DeploymentStatusNotifier() : super(const DeploymentStatusModel());

  void upsertItem({
    required String name,
    required DeployType type,
    required DeployStatus status,
    required String message,
  }) {
    final list = List<DeployedItem>.from(state.items);
    final id = '${type.name}-$name';
    final index = list.indexWhere((e) => e.id == id);

    final nowStr =
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';

    if (index >= 0) {
      list[index] = list[index].copyWith(
        status: status,
        message: message,
        timestamp: nowStr,
      );
    } else {
      list.insert(
        0,
        DeployedItem(
          id: id,
          name: name,
          type: type,
          status: status,
          message: message,
          timestamp: nowStr,
        ),
      );
    }
    state = state.copyWith(items: list);
  }
}

final deploymentStatusProvider =
    StateNotifierProvider<DeploymentStatusNotifier, DeploymentStatusModel>(
  (ref) => DeploymentStatusNotifier(),
);
