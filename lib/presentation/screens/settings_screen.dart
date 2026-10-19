// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/settings_screen.dart
// 核心职责: Wrangler 体系全局设置视图（集成 wrangler login 授权与环境检测）
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/wrangler_service.dart';
import '../widgets/custom_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final WranglerService _wranglerService = WranglerService();
  String _accountStatus = '正在检查 Wrangler 登录状态...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshWhoAmI();
  }

  Future<void> _refreshWhoAmI() async {
    setState(() => _isLoading = true);
    final status = await _wranglerService.checkWhoAmI();
    setState(() {
      _accountStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _handleWranglerLogin() async {
    setState(() => _isLoading = true);

    // 拉起浏览器进行 wrangler login 授权
    await _wranglerService.login(
      onLog: (log) {
        debugPrint(log);
      },
    );

    await _refreshWhoAmI();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wrangler 运行环境与账户授权',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('当前 Wrangler 账户状态 (whoami):',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                SelectableText(
                  _accountStatus,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CustomButton(
                text: _isLoading ? '处理中...' : '浏览器授权登录 (wrangler login)',
                onPressed: _isLoading ? null : _handleWranglerLogin,
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : _refreshWhoAmI,
                child: const Text('刷新授权状态'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
