import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture_showcase/core/di/injection.dart';
import 'package:flutter_architecture_showcase/core/network/network_config.dart';

void main() {
  group('NetworkModule', () {
    setUp(() async {
      await configureDependencies();
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('registers Dio as a configured singleton', () {
      final dio = getIt<Dio>();
      final anotherDio = getIt<Dio>();

      expect(identical(dio, anotherDio), isTrue);

      expect(dio.options.baseUrl, NetworkConfig.baseUrl);
      expect(dio.options.connectTimeout, NetworkConfig.connectTimeout);
      expect(dio.options.receiveTimeout, NetworkConfig.receiveTimeout);
      expect(dio.options.sendTimeout, NetworkConfig.sendTimeout);
      expect(dio.options.contentType, Headers.jsonContentType);
      expect(dio.options.responseType, ResponseType.json);
    });
  });
}
