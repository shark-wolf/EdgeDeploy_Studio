// ==============================================================================
// 所属模块: Domain / UseCases
// 文件路径: lib/domain/usecases/deploy_page_usecase.dart
// 核心职责: Pages 静态托管部署业务逻辑，支持动态传递自定义项目名称
// ==============================================================================

import '../../core/services/wrangler_service.dart';

class DeployPageUsecase {
  final WranglerService wranglerService;

  DeployPageUsecase({required this.wranglerService});

  Future<int> execute({
    required String projectDir,
    required String projectName,
    required String outputDir,
    required void Function(String log) onLog,
  }) async {
    final List<String> args = ['pages', 'deploy', outputDir.trim()];

    if (projectName.trim().isNotEmpty) {
      args.addAll(['--project-name', projectName.trim()]);
    }

    return await wranglerService.executeCommand(
      workingDirectory: projectDir.trim().isEmpty ? '.' : projectDir.trim(),
      arguments: args,
      onLog: onLog,
    );
  }
}
