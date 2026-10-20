// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/worker_screen.dart
// 核心职责: Worker 管理与一键发布视图（每次发布自动写入历史流水）
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/wrangler_service.dart';
import '../../domain/usecases/deploy_worker_usecase.dart';
import '../providers/log_provider.dart';
import '../providers/deployment_status_provider.dart';
import '../widgets/log_console_widget.dart';
import '../widgets/custom_button.dart';

class WorkerScreen extends ConsumerStatefulWidget {
  const WorkerScreen({super.key});

  @override
  ConsumerState<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends ConsumerState<WorkerScreen> {
  final TextEditingController _pathController =
      TextEditingController(text: 'test-worker');
  final TextEditingController _nameController =
      TextEditingController(text: 'test-edge-worker');

  final FocusNode _pathFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isDeploying = false;

  @override
  void dispose() {
    _pathFocusNode.dispose();
    _nameFocusNode.dispose();
    _pathController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _pathController.text = selectedDirectory;
      });
    }
  }

  Future<void> _startDeploy() async {
    if (_isDeploying) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final workerName = _nameController.text.trim();
    setState(() => _isDeploying = true);

    // 写入一条新的发布历史记录（状态：正在发布）
    final deployId = ref.read(deploymentStatusProvider.notifier).recordStart(
          name: workerName,
          type: DeployType.worker,
        );

    ref
        .read(logProvider.notifier)
        .appendLog('\n[开始] 准备触发 Worker 部署（目标名称: $workerName）...\n');

    final usecase = DeployWorkerUsecase(wranglerService: WranglerService());
    final exitCode = await usecase.execute(
      projectDir: _pathController.text.trim(),
      workerName: workerName,
      onLog: (log) {
        ref.read(logProvider.notifier).appendLog(log);
      },
    );

    if (mounted) {
      setState(() => _isDeploying = false);
      if (exitCode == 0) {
        ref.read(deploymentStatusProvider.notifier).recordResult(
              id: deployId,
              status: DeployStatus.success,
              message: '发布成功',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🎉 Worker 发布成功！'), backgroundColor: Colors.green),
        );
      } else {
        ref.read(deploymentStatusProvider.notifier).recordResult(
              id: deployId,
              status: DeployStatus.failed,
              message: '发布失败 (状态码: $exitCode)',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Worker 发布失败 (状态码: $exitCode)'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cloudflare Workers 发布中心',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                decoration: const InputDecoration(
                  labelText: '自定义 Worker 名称 (--name)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pathController,
                focusNode: _pathFocusNode,
                decoration: InputDecoration(
                  labelText: 'Worker 项目本地路径',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open, color: Colors.blue),
                    tooltip: '浏览选择本地文件夹',
                    onPressed: _pickDirectory,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: _isDeploying ? '正在发布 worker...' : '一键发布worker',
                onPressed: _isDeploying ? null : _startDeploy,
              ),
              const SizedBox(height: 24),
              const Expanded(child: LogConsoleWidget()),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
