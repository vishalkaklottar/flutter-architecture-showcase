import 'package:flutter/material.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/screens/product_form_screen.dart';
import 'package:flutter_architecture_showcase/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:flutter_architecture_showcase/features/sync/presentation/cubit/sync_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../widgets/product_empty_view.dart';
import '../widgets/product_list_view.dart';
import 'product_details_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProducts();
  }

  Future<void> _openProductForm({Product? product}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductCubit>(),
          child: ProductFormScreen(product: product),
        ),
      ),
    );
  }

  Future<void> _openProductDetails(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductCubit>(),
          child: ProductDetailsScreen(product: product),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          BlocBuilder<SyncCubit, SyncState>(
            builder: (context, state) {
              return IconButton(
                tooltip: state.isRunning ? 'Synchronizing...' : 'Sync now',
                onPressed: state.isRunning
                    ? null
                    : () => context.read<SyncCubit>().synchronize(),
                icon: state.isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        state.status == SyncStatus.failure
                            ? Icons.sync_problem
                            : Icons.sync,
                      ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<SyncCubit, SyncState>(
        listener: (context, state) {
          if (state.status == SyncStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Synchronization failed.'),
              ),
            );
          }
        },
        child: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            if (state.status == ProductStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == ProductStatus.failure &&
                state.products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.errorMessage ?? 'Something went wrong.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: context.read<ProductCubit>().loadProducts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state.products.isEmpty) {
              return const ProductEmptyView();
            }

            return ProductListView(
              products: state.products,
              onProductTap: _openProductDetails,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
