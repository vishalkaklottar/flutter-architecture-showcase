import 'package:flutter_architecture_showcase/core/config/app_environment.dart';

abstract final class NetworkConfig {
  static const String baseUrl = AppEnvironment.baseUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}
