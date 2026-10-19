// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/app_info_screen.dart
// 核心职责: 应用信息与 Cloudflare 账户详情结构化展示视图（表格卡片排版）
// ==============================================================================

import 'package:flutter/material.dart';
import '../../core/services/wrangler_service.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  final WranglerService _wranglerService = WranglerService();
  bool _isLoading = true;
  final String _email = 'ccneosuper001@gmail.com';
  final String _configPath =
      r'C:\Users\Administrator\AppData\Roaming\xdg.config\.wrangler\config\default.toml';
  final String _accountName = "Ccneosuper001@gmail.com's Account";
  final String _accountId = 'edf7bb998ae4ccffc4f7606aac1f1c8b';
  final String _wranglerVersion = '4.151.1';

  final List<String> _permissions = [
    'user (read)',
    'offline_access',
    'k2.read',
    'k2.write',
    'account (read)',
    'workers (write)',
    'workers_kv (write)',
    'workers_routes (write)',
    'workers_scripts (write)',
    'workers_tail (read)',
    'd1 (write)',
    'pages (write)',
    'zone (read)',
    'ssl_certs (write)',
    'ai (write)',
    'ai-search (write)',
    'ai-search (run)',
    'agent-memory (write)',
    'queues (write)',
    'pipelines (write)',
    'secrets_store (write)',
    'artifacts (write)',
    'flagship (write)',
    'containers (write)',
    'cloudchamber (write)',
    'connectivity (admin)',
    'email_routing (write)',
    'email_sending (write)',
    'browser (write)',
    'challenge-widgets.write'
  ];

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    await _wranglerService.checkWhoAmI();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EdgeDeploy-Studio 应用与账户信息',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              '当前已连接的 Cloudflare 运行环境、账户授权凭证及 Token 权限清单。',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // 1. 基础环境与配置表
            _buildSectionCard(
              title: '基础环境与配置',
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(160), // 已修正为 FixedColumnWidth
                  1: FlexColumnWidth(),
                },
                children: [
                  _buildTableRow('Wrangler 版本', _wranglerVersion),
                  _buildTableRow('登录邮箱', _email),
                  _buildTableRow('凭证存储路径', _configPath),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. 关联账户信息表
            _buildSectionCard(
              title: '关联 Cloudflare 账户',
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(160), // 已修正为 FixedColumnWidth
                  1: FlexColumnWidth(),
                },
                children: [
                  _buildTableRow('账户名称 (Account Name)', _accountName),
                  _buildTableRow('账户 ID (Account ID)', _accountId),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Token 权限列表网格
            _buildSectionCard(
              title: 'Token 权限列表 (Token Permissions)',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _permissions
                    .map((perm) => Chip(
                          label: Text(perm,
                              style: const TextStyle(
                                  fontSize: 12, fontFamily: 'monospace')),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A))),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          child,
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SelectableText(value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
        ),
      ],
    );
  }
}
