// ==============================================================================
// 所属模块: Presentation / Screens
// 文件路径: lib/presentation/screens/dashboard_screen.dart
// 核心职责: 主控看板视图，集成双擎总览（实时同步发布状态）、多标签页切换与全局焦点托管
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/wrangler_service.dart';
import '../providers/deployment_status_provider.dart';
import '../widgets/sidebar_navigation.dart';
import 'worker_screen.dart';
import 'pages_screen.dart';
import 'app_info_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const DashboardScreen({super.key, required this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _screens = [
    WorkersAndPagesOverviewTab(onNavigate: _switchTab),
    const WorkerScreen(),
    const PagesScreen(),
    const AppInfoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Row(
        children: [
          SidebarNavigation(
            currentIndex: _currentIndex,
            onDestinationSelected: (index) {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() {
                _currentIndex = index;
              });
            },
            onLogout: () {
              FocusManager.instance.primaryFocus?.unfocus();
              widget.onLogout();
            },
          ),
          const VerticalDivider(
              width: 1, thickness: 1, color: Color(0xFFCBD5E1)),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}

/// Workers 与 Pages 专属架构总览视图（支持状态响应）
class WorkersAndPagesOverviewTab extends ConsumerStatefulWidget {
  final ValueChanged<int> onNavigate;

  const WorkersAndPagesOverviewTab({super.key, required this.onNavigate});

  @override
  ConsumerState<WorkersAndPagesOverviewTab> createState() =>
      _WorkersAndPagesOverviewTabState();
}

class _WorkersAndPagesOverviewTabState
    extends ConsumerState<WorkersAndPagesOverviewTab> {
  final WranglerService _wranglerService = WranglerService();
  String _envSummary = '正在加载 Wrangler 运行环境...';

  @override
  void initState() {
    super.initState();
    _loadEnvSummary();
  }

  Future<void> _loadEnvSummary() async {
    final status = await _wranglerService.checkWhoAmI();
    if (mounted) {
      setState(() {
        if (status.contains('Email:')) {
          _envSummary = '已通过 Wrangler 授权连接';
        } else {
          _envSummary =
              status.length > 60 ? '${status.substring(0, 60)}...' : status;
        }
      });
    }
  }

  Color _getStatusColor(DeployStatus status) {
    switch (status) {
      case DeployStatus.deploying:
        return Colors.orange;
      case DeployStatus.success:
        return Colors.green;
      case DeployStatus.failed:
        return Colors.red;
      case DeployStatus.idle:
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听全局部署状态（已移除无效的 const 关键字修饰）
    final deployState = ref.watch(deploymentStatusProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部欢迎标语与环境徽章
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EdgeDeploy-Studio 边缘控制台',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '基于 Wrangler 优先架构的高性能 Cloudflare 桌面端多环境部署管理中心。',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(_envSummary,
                          style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 双擎卡片展示区 (Workers & Pages，附带实时状态)
            Row(
              children: [
                // Workers 概览卡片
                Expanded(
                  child: _buildEngineCard(
                    title: 'Cloudflare Workers',
                    subtitle: 'Serverless 边缘计算与 API 代理',
                    icon: Icons.cloud_upload_outlined,
                    iconColor: Colors.orange,
                    statusText: deployState.workerMessage,
                    statusColor: _getStatusColor(deployState.workerStatus),
                    features: [
                      '毫秒级全球冷启动与 V8 隔离环境',
                      '支持 wrangler.toml 零配置本地调试',
                      '适用于高性能 API 网关与量化交易代理',
                    ],
                    buttonText: '进入 Workers 管理',
                    onPressed: () => widget.onNavigate(1),
                  ),
                ),
                const SizedBox(width: 20),
                // Pages 概览卡片
                Expanded(
                  child: _buildEngineCard(
                    title: 'Cloudflare Pages',
                    subtitle: '全栈静态与全动态前端托管',
                    icon: Icons.web_outlined,
                    iconColor: Colors.blue,
                    statusText: deployState.pagesMessage,
                    statusColor: _getStatusColor(deployState.pagesStatus),
                    features: [
                      '无限制的全球 CDN 边缘节点加速',
                      '支持 Vite、Flutter Web、React 等产物托管',
                      '极速一键部署，自动化构建与发布',
                    ],
                    buttonText: '进入 Pages 管理',
                    onPressed: () => widget.onNavigate(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 底部快捷提示卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 架构提示与开发指引',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '当前项目所有操作均由本地封装的 Wrangler CLI 进程驱动。如需核对当前账号的详细权限、Token 范围或凭证路径，请随时访问左侧的“应用信息”菜单。',
                    style: TextStyle(
                        color: Color(0xFF475569), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String statusText,
    required Color statusColor,
    required List<String> features,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              // 实时状态徽章
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(feature,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF334155)))),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
