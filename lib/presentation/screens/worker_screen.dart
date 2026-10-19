// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/worker_screen.dart
// 核心职责: Worker 管理与发布视图（防重复点击，实时同步发布状态）
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
    _pathFocusNode.unfocus();
    _nameFocusNode.unfocus();
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
    // 【防重入保护】如果正在部署，直接拦截点击事件
    if (_isDeploying) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isDeploying = true);
    ref.read(deploymentStatusProvider.notifier).setWorkerDeploying();
    ref
        .read(logProvider.notifier)
        .appendLog('\n[开始] 准备触发 Worker 部署（目标名称: ${_nameController.text}）...\n');

    final usecase = DeployWorkerUsecase(wranglerService: WranglerService());
    final exitCode = await usecase.execute(
      projectDir: _pathController.text.trim(),
      workerName: _nameController.text.trim(),
      onLog: (log) {
        ref.read(logProvider.notifier).appendLog(log);
      },
    );

    if (mounted) {
      setState(() => _isDeploying = false);
      if (exitCode == 0) {
        ref.read(deploymentStatusProvider.notifier).setWorkerSuccess('发布成功');
      } else {
        ref
            .read(deploymentStatusProvider.notifier)
            .setWorkerFailed('发布失败 (状态码: $exitCode)');
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
                text: _isDeploying ? '正在发布 Worker...' : '一键发布 Worker',
                // 当处于部署状态时传 null 禁用按钮，彻底防止重复点击
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
