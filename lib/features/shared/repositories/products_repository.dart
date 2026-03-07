import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Product {
  final String id;
  final String name;
  final String type; // 'cooling', 'roasting', 'general', 'rooms'
  final String? venueId;

  Product({
    required this.id,
    required this.name,
    required this.type,
    this.venueId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      venueId: json['venue_id'] as String?,
    );
  }
}

class ProductsRepository {
  final SupabaseClient _client;

  ProductsRepository(this._client);

  /// Fetches global products (venue_id is null) AND products for the specific venue.
  Future<List<Product>> getProducts(String type, {String? venueId}) async {
    try {
      var query = _client.from('products').select().eq('type', type);

      if (venueId != null) {
        query = query.or('venue_id.is.null,venue_id.eq.$venueId');
      } else {
        query = query.or('venue_id.is.null');
      }

      final response = await query.order('name', ascending: true);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[M08] getProducts failed: $e');
      rethrow;
    }
  }

  Future<void> addProduct({
    required String name,
    required String type,
    required String venueId,
  }) async {
    await _client.from('products').insert({
      'name': name,
      'type': type,
      'venue_id': venueId,
    });
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String type,
  }) async {
    await _client
        .from('products')
        .update({'name': name, 'type': type})
        .eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(Supabase.instance.client);
});

final productsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  type,
) async {
  final repo = ref.watch(productsRepositoryProvider);
  final venueId = ref.watch(currentZoneProvider)?.venueId;
  return repo.getProducts(type, venueId: venueId);
});
