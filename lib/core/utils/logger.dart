// ==============================================================================
// 所属模块: Core / Utils
// 文件路径: lib/core/utils/logger.dart
// 核心职责: 统一的日志输出工具类（基于 logger 包）
// ==============================================================================

import 'package:logger/logger.dart';

class AppLogger {
  static final Logger instance = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
}
