
import 'dart:async';

import 'package:flutter_architecture_showcase/core/sync/domain/repositories/sync_coordinator.dart';
import 'package:flutter_architecture_showcase/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:flutter_architecture_showcase/features/sync/presentation/cubit/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

class MockSyncCoordinator extends Mock implements SyncCoordinator {}

void main() {
  late MockSyncCoordinator coordinator;

  setUp(() {
    coordinator = MockSyncCoordinator();

    when(() => coordinator.synchronize()).thenAnswer((_) async {});
  });

  group('SyncCubit', () {
    test('initial state is correct', () {
      final cubit = SyncCubit(coordinator);

      expect(cubit.state.status, SyncStatus.initial);
      expect(cubit.state.isRunning, isFalse);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.lastSyncedAt, isNull);

      cubit.close();
    });

    blocTest<SyncCubit, SyncState>(
      'emits running and success when synchronization succeeds',
      build: () => SyncCubit(coordinator),
      act: (cubit) => cubit.synchronize(),
      expect: () => [
        isA<SyncState>()
            .having((state) => state.status, 'status', SyncStatus.running)
            .having((state) => state.isRunning, 'isRunning', isTrue),
        isA<SyncState>()
            .having((state) => state.status, 'status', SyncStatus.success)
            .having((state) => state.isRunning, 'isRunning', isFalse)
            .having((state) => state.lastSyncedAt, 'lastSyncedAt', isNotNull)
            .having((state) => state.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verify(() => coordinator.synchronize()).called(1);
      },
    );

    blocTest<SyncCubit, SyncState>(
      'emits running and failure when synchronization throws',
      setUp: () {
        when(() => coordinator.synchronize())
            .thenThrow(Exception('Network error'));
      },
      build: () => SyncCubit(coordinator),
      act: (cubit) => cubit.synchronize(),
      expect: () => [
        isA<SyncState>().having(
              (state) => state.status,
          'status',
          SyncStatus.running,
        ),
        isA<SyncState>()
            .having((state) => state.status, 'status', SyncStatus.failure)
            .having(
              (state) => state.errorMessage,
          'errorMessage',
          'Exception: Network error',
        )
            .having((state) => state.isRunning, 'isRunning', isFalse),
      ],
      verify: (_) {
        verify(() => coordinator.synchronize()).called(1);
      },
    );

    test('ignores duplicate synchronization requests', () async {
      final completer = Completer<void>();

      when(() => coordinator.synchronize())
          .thenAnswer((_) => completer.future);

      final cubit = SyncCubit(coordinator);

      final firstRequest = cubit.synchronize();

      expect(cubit.state.status, SyncStatus.running);

      final secondRequest = cubit.synchronize();

      verify(() => coordinator.synchronize()).called(1);

      completer.complete();

      await Future.wait([firstRequest, secondRequest]);

      expect(cubit.state.status, SyncStatus.success);
      expect(cubit.state.lastSyncedAt, isNotNull);

      await cubit.close();
    });

    blocTest<SyncCubit, SyncState>(
      'allows synchronization again after a failure',
      setUp: () {
        var callCount = 0;

        when(() => coordinator.synchronize()).thenAnswer((_) async {
          callCount++;

          if (callCount == 1) {
            throw Exception('Network error');
          }
        });
      },
      build: () => SyncCubit(coordinator),
      act: (cubit) async {
        await cubit.synchronize();
        await cubit.synchronize();
      },
      expect: () => [
        isA<SyncState>().having(
              (state) => state.status,
          'status',
          SyncStatus.running,
        ),
        isA<SyncState>()
            .having((state) => state.status, 'status', SyncStatus.failure)
            .having(
              (state) => state.errorMessage,
          'errorMessage',
          'Exception: Network error',
        ),
        isA<SyncState>()
            .having((state) => state.status, 'status', SyncStatus.running)
            .having((state) => state.errorMessage, 'errorMessage', isNull),
        isA<SyncState>()
            .having((state) => state.status, 'status', SyncStatus.success)
            .having((state) => state.lastSyncedAt, 'lastSyncedAt', isNotNull),
      ],
      verify: (_) {
        verify(() => coordinator.synchronize()).called(2);
      },
    );
  });
}
