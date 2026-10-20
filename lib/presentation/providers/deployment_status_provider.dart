// ==============================================================================
// 所属模块: Presentation / Providers
// 文件路径: lib/presentation/providers/deployment_status_provider.dart
// 核心职责: 本地磁盘仅持久化存储发布过的 Worker 与 Pages 名称和类型，支撑重启恢复与资产列表构建
// ==============================================================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeployType { worker, page }

enum DeployStatus { deploying, success, failed }

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
  // 核心约束：本地磁盘仅保存发布过的 worker 与 page 名称和类型
  static const String _storageKey = 'edge_deploy_published_names_v1';

  DeploymentStatusNotifier() : super(const DeploymentStatusModel()) {
    _loadNamesFromDisk();
  }

  /// 从本地磁盘加载历史发布过的名称和类型，重建资产列表
  Future<void> _loadNamesFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final items = decoded.map((e) {
          final name = e['name'] as String? ?? '';
          final typeIndex = e['type'] as int? ?? 0;
          final type = DeployType.values[typeIndex];
          return DeployedItem(
            id: '${type.name}-$name',
            name: name,
            type: type,
            status: DeployStatus.success,
            message: '本地已记录',
            timestamp: '历史',
          );
        }).toList();
        state = DeploymentStatusModel(items: items);
      }
    } catch (_) {}
  }

  /// 仅将发布过的 asset 名称和类型持久化到本地磁盘
  Future<void> _saveNamesToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uniqueMap = <String, DeployType>{};
      for (var item in state.items) {
        uniqueMap[item.name] = item.type;
      }
      final listToSave = uniqueMap.entries
          .map((entry) => {
                'name': entry.key,
                'type': entry.value.index,
              })
          .toList();
      await prefs.setString(_storageKey, jsonEncode(listToSave));
    } catch (_) {}
  }

  /// 记录一次新的发布动作开始（不管成功与否，名称均记录在本地）
  String recordStart({required String name, required DeployType type}) {
    final id = '${type.name}-$name';
    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final existingIndex =
        state.items.indexWhere((e) => e.name == name && e.type == type);
    List<DeployedItem> newList = List.from(state.items);

    final newItem = DeployedItem(
      id: id,
      name: name,
      type: type,
      status: DeployStatus.deploying,
      message: '正在发布...',
      timestamp: timestamp,
    );

    if (existingIndex >= 0) {
      newList.removeAt(existingIndex);
    }
    newList.insert(0, newItem);

    state = state.copyWith(items: newList);
    _saveNamesToDisk(); // 仅持久化名称到本地
    return id;
  }

  /// 更新指定发布流水的结果状态
  void recordResult({
    required String id,
    required DeployStatus status,
    required String message,
  }) {
    final updatedItems = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(status: status, message: message);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    _saveNamesToDisk(); // 确保名称已持久化
  }

  /// 批量更新状态（用于边缘同步匹配）
  void updateAll(List<DeployedItem> newItems) {
    state = state.copyWith(items: newItems);
    _saveNamesToDisk();
  }
}

final deploymentStatusProvider =
    StateNotifierProvider<DeploymentStatusNotifier, DeploymentStatusModel>(
  (ref) => DeploymentStatusNotifier(),
);
