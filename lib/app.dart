// ==============================================================================
// 所属模块: Presentation / App
// 文件路径: lib/app.dart
// 核心职责: 根 MaterialApp，统一管理登录拦截、状态切换与米白色明亮主题
// ==============================================================================

import 'package:flutter/material.dart';
import 'core/services/wrangler_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';

class EdgeDeployApp extends StatefulWidget {
  const EdgeDeployApp({super.key});

  @override
  State<EdgeDeployApp> createState() => _EdgeDeployAppState();
}

class _EdgeDeployAppState extends State<EdgeDeployApp> {
  final WranglerService _wranglerService = WranglerService();
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final status = await _wranglerService.checkWhoAmI();
    // 判断 whoami 是否返回了有效账号信息
    final loggedIn = !status.contains('未检测到有效登录状态');
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdgeDeploy-Studio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFFAF9F6),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      home: _isChecking
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _isLoggedIn
              ? DashboardScreen(
                  onLogout: () {
                    setState(() {
                      _isLoggedIn = false;
                    });
                  },
                )
              : LoginScreen(
                  onLoginSuccess: () {
                    setState(() {
                      _isLoggedIn = true;
                    });
                  },
                ),
    );
  }
}
