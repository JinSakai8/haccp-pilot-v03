import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Model
class Product {
  final String id;
  final String name;
  final String type;

  Product({required this.id, required this.name, required this.type});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }
}

// Repository
class ProductsRepository {
  final SupabaseClient _client;

  ProductsRepository(this._client);

  Future<List<Product>> getProductsByType(String type) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('type', type)
          .order('name', ascending: true);

      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      // Fallback if table doesn't exist yet or connection error
      // Return empty list so UI works (but empty)
      return [];
    }
  }
}

// Providers
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(Supabase.instance.client);
});

final productsProvider = FutureProvider.family<List<Product>, String>((ref, type) async {
  final repo = ref.watch(productsRepositoryProvider);
  return await repo.getProductsByType(type);
});
