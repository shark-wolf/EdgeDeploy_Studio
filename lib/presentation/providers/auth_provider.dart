// ==============================================================================
// 所属模块: Presentation / Providers
// 文件路径: lib/presentation/providers/auth_provider.dart
// 核心职责: 管理用户登录凭证与授权状态的 Riverpod 提供者
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/secure_storage_service.dart';

class AuthNotifier extends StateNotifier<String?> {
  final SecureStorageService storageService;

  AuthNotifier({required this.storageService}) : super(null) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await storageService.getApiToken();
    state = token;
  }

  Future<void> saveToken(String token) async {
    await storageService.saveApiToken(token);
    state = token;
  }

  Future<void> logout() async {
    await storageService.deleteApiToken();
    state = null;
  }
}

final secureStorageProvider = Provider((ref) => SecureStorageService());

final authProvider = StateNotifierProvider<AuthNotifier, String?>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storageService: storage);
});
