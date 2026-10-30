import 'package:flutter_architecture_showcase/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('stores the success value', () {
        const result = Result<String>.success('Product created');

        expect(result, isA<Success<String>>());
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('fold calls onSuccess with the value', () {
        const result = Result<String>.success('Product created');

        final message = result.fold<String>(
          onSuccess: (value) => value,
          onFailure: (failure) => failure.message,
        );

        expect(message, 'Product created');
      });
    });

    group('Failure', () {
      test('stores the failure details', () {
        const failure = AppFailure(
          message: 'Network unavailable',
          code: 'network_error',
        );
        const result = Result<String>.failure(failure);

        expect(result, isA<Failure<String>>());
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
      });

      test('fold calls onFailure with the failure', () {
        const failure = AppFailure(
          message: 'Network unavailable',
          code: 'network_error',
        );
        const result = Result<String>.failure(failure);

        final message = result.fold<String>(
          onSuccess: (value) => value,
          onFailure: (failure) => failure.message,
        );

        expect(message, 'Network unavailable');
      });
    });

    group('AppFailure', () {
      test('code is optional', () {
        const failure = AppFailure(message: 'Something went wrong');

        expect(failure.message, 'Something went wrong');
        expect(failure.code, isNull);
      });
    });
  });
}
