// ==============================================================================
// 所属模块: Domain / UseCases
// 文件路径: lib/domain/usecases/fetch_logs_usecase.dart
// 核心职责: 获取远程日志或实时构建日志的业务用例（如启动 wrangler tail）
// ==============================================================================

import '../../core/services/wrangler_service.dart';

class FetchLogsUsecase {
  final WranglerService wranglerService;

  FetchLogsUsecase({required this.wranglerService});

  Future<int> executeTail({
    required String projectDir,
    required String scriptName,
    required void Function(String log) onLog,
  }) async {
    return await wranglerService.executeCommand(
      workingDirectory: projectDir,
      arguments: ['tail', scriptName],
      onLog: onLog,
    );
  }
}
