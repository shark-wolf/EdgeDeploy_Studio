// ==============================================================================
// 所属模块: Core / Services
// 文件路径: lib/core/services/secure_storage_service.dart
// 核心职责: 封装 flutter_secure_storage，用于安全存储用户的 Cloudflare API Token
// ==============================================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyApiToken = 'cf_api_token';
  static const String _keyProxyUrl = 'cf_proxy_url';

  /// 异步保存 Cloudflare API Token
  Future<void> saveApiToken(String token) async {
    await _storage.write(key: _keyApiToken, value: token);
  }

  /// 异步读取 Cloudflare API Token
  Future<String?> getApiToken() async {
    return await _storage.read(key: _keyApiToken);
  }

  /// 删除保存的 API Token
  Future<void> deleteApiToken() async {
    await _storage.delete(key: _keyApiToken);
  }

  /// 保存网络代理地址
  Future<void> saveProxyUrl(String proxyUrl) async {
    await _storage.write(key: _keyProxyUrl, value: proxyUrl);
  }

  /// 读取网络代理地址
  Future<String?> getProxyUrl() async {
    return await _storage.read(key: _keyProxyUrl);
  }
}
