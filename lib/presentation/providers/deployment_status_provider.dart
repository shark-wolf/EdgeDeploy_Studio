// ==============================================================================
// 所属模块: Presentation / Providers
// 文件路径: lib/presentation/providers/deployment_status_provider.dart
// 核心职责: 全局管理 Worker 与 Pages 的部署状态，供系统概览与发布页面实时联动
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeployStatus { idle, deploying, success, failed }

class DeploymentStatusModel {
  final DeployStatus workerStatus;
  final String workerMessage;
  final DeployStatus pagesStatus;
  final String pagesMessage;

  const DeploymentStatusModel({
    this.workerStatus = DeployStatus.idle,
    this.workerMessage = '尚未部署',
    this.pagesStatus = DeployStatus.idle,
    this.pagesMessage = '尚未部署',
  });

  DeploymentStatusModel copyWith({
    DeployStatus? workerStatus,
    String? workerMessage,
    DeployStatus? pagesStatus,
    String? pagesMessage,
  }) {
    return DeploymentStatusModel(
      workerStatus: workerStatus ?? this.workerStatus,
      workerMessage: workerMessage ?? this.workerMessage,
      pagesStatus: pagesStatus ?? this.pagesStatus,
      pagesMessage: pagesMessage ?? this.pagesMessage,
    );
  }
}

class DeploymentStatusNotifier extends StateNotifier<DeploymentStatusModel> {
  DeploymentStatusNotifier() : super(const DeploymentStatusModel());

  void setWorkerDeploying() => state = state.copyWith(
      workerStatus: DeployStatus.deploying, workerMessage: '正在发布 Worker...');
  void setWorkerSuccess(String msg) => state =
      state.copyWith(workerStatus: DeployStatus.success, workerMessage: msg);
  void setWorkerFailed(String msg) => state =
      state.copyWith(workerStatus: DeployStatus.failed, workerMessage: msg);

  void setPagesDeploying() => state = state.copyWith(
      pagesStatus: DeployStatus.deploying, pagesMessage: '正在部署 Pages...');
  void setPagesSuccess(String msg) => state =
      state.copyWith(pagesStatus: DeployStatus.success, workerMessage: msg);
  void setPagesFailed(String msg) => state =
      state.copyWith(pagesStatus: DeployStatus.failed, workerMessage: msg);
}

final deploymentStatusProvider =
    StateNotifierProvider<DeploymentStatusNotifier, DeploymentStatusModel>(
  (ref) => DeploymentStatusNotifier(),
);
