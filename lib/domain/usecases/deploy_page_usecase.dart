// ==============================================================================
// 所属模块: Domain / UseCases
// 文件路径: lib/domain/usecases/deploy_page_usecase.dart
// 核心职责: Pages 智能部署业务逻辑（自动检测云端项目，不存在则自动创建并继续部署）
// ==============================================================================

import '../../core/services/wrangler_service.dart';

class DeployPageUsecase {
  final WranglerService wranglerService;

  DeployPageUsecase({required this.wranglerService});

  Future<int> execute({
    required String projectDir,
    required String projectName,
    required void Function(String log) onLog,
  }) async {
    final targetDir = projectDir.trim().isEmpty ? '.' : projectDir.trim();
    final name = projectName.trim();

    // 1. 尝试直接执行部署指令
    final List<String> deployArgs = ['pages', 'deploy', targetDir];
    if (name.isNotEmpty) {
      deployArgs.addAll(['--project-name', name]);
    }

    String capturedLogs = '';
    int exitCode = await wranglerService.executeCommand(
      workingDirectory: '.',
      arguments: deployArgs,
      onLog: (log) {
        capturedLogs += log;
        onLog(log);
      },
    );

    // 2. 如果部署失败，且日志包含项目不存在的提示，则自动在云端创建项目并重试
    if (exitCode != 0 &&
        (capturedLogs.contains('does not exist') ||
            capturedLogs.contains('does not exist.'))) {
      if (name.isNotEmpty) {
        onLog('\n[信息] 💡 检测到云端 Pages 项目 "$name" 尚不存在，正在自动为您初始化创建...\n');

        final List<String> createArgs = [
          'pages',
          'project',
          'create',
          name,
          '--production-branch',
          'main'
        ];
        int createExitCode = await wranglerService.executeCommand(
          workingDirectory: '.',
          arguments: createArgs,
          onLog: onLog,
        );

        if (createExitCode == 0) {
          onLog('\n[信息] ✨ 云端项目创建成功，正在重新执行部署...\n');
          // 创建成功后，自动重试部署
          exitCode = await wranglerService.executeCommand(
            workingDirectory: '.',
            arguments: deployArgs,
            onLog: onLog,
          );
        } else {
          onLog('\n[错误] ❌ 自动创建云端 Pages 项目失败，请检查账号权限。\n');
          return createExitCode;
        }
      }
    }

    return exitCode;
  }
}
