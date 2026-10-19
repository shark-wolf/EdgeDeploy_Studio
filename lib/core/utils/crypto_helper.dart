// ==============================================================================
// 所属模块: Core / Utils
// 文件路径: lib/core/utils/crypto_helper.dart
// 核心职责: 敏感信息加密与解密辅助工具（如本地临时敏感缓存加解密）
// ==============================================================================

import 'dart:convert';

class CryptoHelper {
  /// 简单的 Base64 混淆编码（高级敏感数据已由系统的 SecureStorage 托管）
  static String obfuscate(String plainText) {
    return base64Encode(utf8.encode(plainText));
  }

  /// 解密混淆文本
  static String deobfuscate(String encodedText) {
    try {
      return utf8.decode(base64Decode(encodedText));
    } catch (e) {
      return '';
    }
  }
}
