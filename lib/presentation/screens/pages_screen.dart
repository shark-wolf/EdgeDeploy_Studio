// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/pages_screen.dart
// 核心职责: Pages 智能发布视图（每次发布自动写入历史流水）
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
  final TextEditingController _nameController =
      TextEditingController(text: 'test-pages-app');
  final TextEditingController _projectDirController =
      TextEditingController(text: 'test-pages');

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _projectDirFocusNode = FocusNode();

  bool _isDeploying = false;

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _projectDirFocusNode.dispose();
    _nameController.dispose();
    _projectDirController.dispose();
    super.dispose();
  }

  Future<void> _pickProjectDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _projectDirController.text = selectedDirectory;
      });
    }
  }

  Future<void> _startDeploy() async {
    if (_isDeploying) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final projectName = _nameController.text.trim();
    setState(() => _isDeploying = true);

    // 写入一条新的 Pages 发布历史记录（状态：正在发布）
    final deployId = ref.read(deploymentStatusProvider.notifier).recordStart(
          name: projectName,
          type: DeployType.page,
        );

    ref.read(logProvider.notifier).appendLog(
        '\n[开始] 智能部署 Pages 项目（目录: ${_projectDirController.text}）...\n');

    final usecase = DeployPageUsecase(wranglerService: WranglerService());
    final exitCode = await usecase.execute(
      projectDir: _projectDirController.text.trim(),
      projectName: projectName,
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
              message: '部署成功',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🎉 Page 部署成功！'), backgroundColor: Colors.green),
        );
      } else {
        ref.read(deploymentStatusProvider.notifier).recordResult(
              id: deployId,
              status: DeployStatus.failed,
              message: '部署失败 (状态码: $exitCode)',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Page 部署失败 (状态码: $exitCode)'),
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
                controller: _projectDirController,
                focusNode: _projectDirFocusNode,
                decoration: InputDecoration(
                  labelText: 'Pages 项目本地根路径 (自动检测并发布)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open, color: Colors.blue),
                    tooltip: '浏览选择项目根目录',
                    onPressed: _pickProjectDirectory,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: _isDeploying ? '正在发布 page...' : '一键发布page',
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
