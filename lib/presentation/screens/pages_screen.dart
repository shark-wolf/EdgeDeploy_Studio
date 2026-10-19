// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/pages_screen.dart
// 核心职责: Pages 静态托管发布视图（防重复点击，实时同步发布状态）
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/wrangler_service.dart';
import '../../domain/usecases/deploy_page_usecase.dart';
import '../providers/log_provider.dart';
import '../providers/deployment_status_provider.dart';
import '../widgets/log_console_widget.dart';
import '../widgets/custom_button.dart';

class PagesScreen extends ConsumerStatefulWidget {
  const PagesScreen({super.key});

  @override
  ConsumerState<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends ConsumerState<PagesScreen> {
  final TextEditingController _pathController =
      TextEditingController(text: 'test-pages/dist');
  final TextEditingController _nameController =
      TextEditingController(text: 'test-pages-app');

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _pathFocusNode = FocusNode();
  bool _isDeploying = false;

  @override
  void dispose() {
    _nameFocusNode.unfocus();
    _pathFocusNode.unfocus();
    _nameFocusNode.dispose();
    _pathFocusNode.dispose();
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
    // 【防重入保护】防止重复点击
    if (_isDeploying) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isDeploying = true);
    ref.read(deploymentStatusProvider.notifier).setPagesDeploying();
    ref
        .read(logProvider.notifier)
        .appendLog('\n[开始] 部署 Pages 静态资产（项目名: ${_nameController.text}）...\n');

    final usecase = DeployPageUsecase(wranglerService: WranglerService());
    final exitCode = await usecase.execute(
      projectDir: '.',
      projectName: _nameController.text.trim(),
      outputDir: _pathController.text.trim(),
      onLog: (log) {
        ref.read(logProvider.notifier).appendLog(log);
      },
    );

    if (mounted) {
      setState(() => _isDeploying = false);
      if (exitCode == 0) {
        ref.read(deploymentStatusProvider.notifier).setPagesSuccess('部署成功');
      } else {
        ref
            .read(deploymentStatusProvider.notifier)
            .setPagesFailed('部署失败 (状态码: $exitCode)');
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
              const Text('Cloudflare Pages 静态托管中心',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                decoration: const InputDecoration(
                  labelText: '自定义 Pages 项目名称 (--project-name)',
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
                  labelText: '构建产物输出目录 (dist/build)',
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
                text: _isDeploying ? '正在部署 Pages...' : '部署静态资产到 Pages',
                // 处于部署状态时禁用按钮
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
