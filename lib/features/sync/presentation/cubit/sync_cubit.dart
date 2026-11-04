import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/sync/domain/repositories/sync_coordinator.dart';
import 'sync_state.dart';

@injectable
class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._coordinator) : super(const SyncState());

  final SyncCoordinator _coordinator;

  Future<void> synchronize() async {
    if (isClosed || state.isRunning) return;

    emit(state.copyWith(status: SyncStatus.running, clearError: true));

    try {
      await _coordinator.synchronize();

      if (isClosed) return;

      emit(
        state.copyWith(
          status: SyncStatus.success,
          lastSyncedAt: DateTime.now(),
          clearError: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;

      emit(
        state.copyWith(
          status: SyncStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
