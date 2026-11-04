import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_architecture_showcase/app/app.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/cubit/product_cubit.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/cubit/product_state.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/screens/products_screen.dart';
import 'package:flutter_architecture_showcase/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:flutter_architecture_showcase/features/sync/presentation/cubit/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockProductCubit extends MockCubit<ProductState>
    implements ProductCubit {}

class MockSyncCubit extends MockCubit<SyncState> implements SyncCubit {}

final getIt = GetIt.instance;

void main() {
  late MockProductCubit mockProductCubit;
  late MockSyncCubit mockSyncCubit;

  setUp(() {
    mockProductCubit = MockProductCubit();
    mockSyncCubit = MockSyncCubit();

    when(() => mockProductCubit.state).thenReturn(const ProductState());
    when(() => mockProductCubit.stream)
        .thenAnswer((_) => const Stream<ProductState>.empty());
    when(() => mockProductCubit.loadProducts()).thenAnswer((_) async {});

    when(() => mockSyncCubit.state).thenReturn(const SyncState());
    when(() => mockSyncCubit.stream)
        .thenAnswer((_) => const Stream<SyncState>.empty());
    when(() => mockSyncCubit.synchronize()).thenAnswer((_) async {});

    getIt.registerFactory<ProductCubit>(() => mockProductCubit);
    getIt.registerFactory<SyncCubit>(() => mockSyncCubit);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'App renders ProductsScreen and triggers synchronization on launch',
    (WidgetTester tester) async {
      await tester.pumpWidget(const App());

      expect(find.byType(ProductsScreen), findsOneWidget);

      verify(() => mockSyncCubit.synchronize()).called(1);
      verify(() => mockProductCubit.loadProducts()).called(1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
