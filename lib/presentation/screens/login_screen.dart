// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/login_screen.dart
// 核心职责: Wrangler 独立授权登录视图（米白色明亮主题、日志控制台实时响应）
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/wrangler_service.dart';
import '../providers/log_provider.dart';
import '../widgets/log_console_widget.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final WranglerService _wranglerService = WranglerService();
  bool _isLoggingIn = false;

  Future<void> _handleLogin() async {
    if (_isLoggingIn) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoggingIn = true);

    ref.read(logProvider.notifier).appendLog('\n[开始] 正在发起 Wrangler 授权登录...\n');

    final success = await _wranglerService.login(
      onLog: (log) {
        ref.read(logProvider.notifier).appendLog(log);
      },
    );

    if (mounted) {
      setState(() => _isLoggingIn = false);
      if (success) {
        ref.read(logProvider.notifier).appendLog('\n[成功] 授权登录完成！\n');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🎉 Wrangler 授权登录成功！'),
              backgroundColor: Colors.green),
        );
        widget.onLoginSuccess();
      } else {
        ref.read(logProvider.notifier).appendLog('\n[失败] 授权登录未完成或中断。\n');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('❌ 授权登录失败，请检查控制台日志'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // 米白色明亮主题
      body: Center(
        child: Container(
          width: 650,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF2563EB), size: 32),
                  SizedBox(width: 12),
                  Text(
                    'EdgeDeploy-Studio 授权登录',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '本应用基于 Wrangler CLI 进程驱动。请点击下方按钮唤起默认浏览器完成 Cloudflare 账户授权。',
                style: TextStyle(
                    color: Color(0xFF475569), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoggingIn ? '正在等待浏览器授权...' : '使用 Wrangler 授权登录',
                  onPressed: _isLoggingIn ? null : _handleLogin,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '实时授权日志控制台:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                height: 200,
                child: LogConsoleWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
