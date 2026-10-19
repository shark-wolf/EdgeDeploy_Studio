// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/login_screen.dart
// Service: 独立登录界面，通过 Wrangler 授权登录后方可进入系统
// ==============================================================================

import 'package:flutter/material.dart';
import '../../core/services/wrangler_service.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final WranglerService _wranglerService = WranglerService();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 1. 触发浏览器授权登录
    final success = await _wranglerService.login(
      onLog: (log) => debugPrint(log),
    );

    if (success) {
      // 2. 验证登录状态是否确实成功
      final whoami = await _wranglerService.checkWhoAmI();
      if (!whoami.contains('未检测到有效登录状态')) {
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = '登录未完成或凭证无效，请重试。';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Wrangler 登录流程中断或失败。';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'EdgeDeploy-Studio',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                '请先登录 Cloudflare 官方账户以继续使用桌面端',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_errorMessage,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? '正在等待网页授权...' : '使用 Cloudflare 账号登录',
                  onPressed: _isLoading ? null : _handleLogin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
