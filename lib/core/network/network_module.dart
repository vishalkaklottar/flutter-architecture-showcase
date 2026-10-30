import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'network_config.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio get dio => Dio(
    BaseOptions(
      baseUrl: NetworkConfig.baseUrl,
      connectTimeout: NetworkConfig.connectTimeout,
      receiveTimeout: NetworkConfig.receiveTimeout,
      sendTimeout: NetworkConfig.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
}
