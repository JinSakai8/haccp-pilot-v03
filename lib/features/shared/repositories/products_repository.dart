import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';

// Model
class Product {
  final String id;
  final String name;
  final String type; // 'cooling', 'roasting', 'general'
  final String? venueId;

  Product({required this.id, required this.name, required this.type, this.venueId});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      venueId: json['venue_id'] as String?,
    );
  }
}

// Repository
class ProductsRepository {
  final SupabaseClient _client;

  ProductsRepository(this._client);

  /// Fetches global products (venue_id is null) AND products for the specific venue.
  Future<List<Product>> getProducts(String type, {String? venueId}) async {
    try {
      var query = _client
          .from('products')
          .select()
          .eq('type', type);
      
      if (venueId != null) {
        query = query.or('venue_id.is.null,venue_id.eq.$venueId');
      } else {
        // Safe fallback for "venue_id IS NULL" using the 'or' syntax which we know works
        query = query.or('venue_id.is.null');
      }

      final response = await query.order('name', ascending: true);
      
      final products = (response as List).map((e) => Product.fromJson(e)).toList();

      // Fallback if DB is empty (Vital for Pilot stability)
      if (products.isEmpty && venueId == null) {
        // Only return fallback for global context or if explicitly requested
        return [
           Product(id: 'fallback-1', name: 'Pierogi z Mięsem', type: 'cooling'),
           Product(id: 'fallback-2', name: 'Pierogi Ruskie', type: 'cooling'),
           Product(id: 'fallback-3', name: 'Gołąbki', type: 'cooling'),
           Product(id: 'fallback-4', name: 'Udka z Kurczaka', type: 'roasting'),
           Product(id: 'fallback-5', name: 'Schab Pieczony', type: 'roasting'),
        ].where((p) => p.type == type).toList();
      }

      return products;

    } catch (e) {
      // ignore: avoid_print
      print('Error fetching products: $e');
      // Fallback on error too
      return [
           Product(id: 'error-1', name: 'Pierogi (Tryb Awaryjny)', type: 'cooling'),
      ].where((p) => p.type == type).toList();
    }
  }

  Future<void> addProduct({required String name, required String type, required String venueId}) async {
     await _client.from('products').insert({
       'name': name,
       'type': type,
       'venue_id': venueId,
     });
  }

  Future<void> updateProduct({required String id, required String name, required String type}) async {
    await _client.from('products').update({
      'name': name,
      'type': type,
    }).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }
}

// Providers
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(Supabase.instance.client);
});

final productsProvider = FutureProvider.family<List<Product>, String>((ref, type) async {
  final repo = ref.watch(productsRepositoryProvider);
  
  // Try to get venueId from employee zones (first zone)
  // This assumes the user is logged in
  final zones = await ref.watch(employeeZonesProvider.future);
  final venueId = zones.isNotEmpty ? zones.first.venueId : null;
  
  return await repo.getProducts(type, venueId: venueId);
});
