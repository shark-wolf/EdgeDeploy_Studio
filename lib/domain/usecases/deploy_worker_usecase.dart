// ==============================================================================
// 所属模块: Domain / UseCases
// 文件路径: lib/domain/usecases/deploy_worker_usecase.dart
// 核心职责: Worker 部署业务逻辑，支持动态传递自定义 Worker 名称
// ==============================================================================

import '../../core/services/wrangler_service.dart';

class DeployWorkerUsecase {
  final WranglerService wranglerService;

  DeployWorkerUsecase({required this.wranglerService});

  Future<int> execute({
    required String projectDir,
    required String workerName,
    required void Function(String log) onLog,
  }) async {
    final List<String> args = ['deploy'];

    // 如果用户输入了自定义名称，则通过 --name 参数覆盖
    if (workerName.trim().isNotEmpty) {
      args.addAll(['--name', workerName.trim()]);
    }

    return await wranglerService.executeCommand(
      workingDirectory: projectDir.trim().isEmpty ? '.' : projectDir.trim(),
      arguments: args,
      onLog: onLog,
    );
  }
}
