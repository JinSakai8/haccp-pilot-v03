import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/venue_repository.dart';

part 'm08_providers.g.dart';

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return VenueRepository();
});

@riverpod
class VenueSettingsController extends _$VenueSettingsController {
  @override
  Future<Map<String, dynamic>?> build(String venueId) async {
    final repository = ref.read(venueRepositoryProvider);
    return repository.getSettings(venueId);
  }

  Future<void> updateSettings({
    required String name,
    required String nip,
    required String address,
    String? logoUrl,
  }) async {
    final repository = ref.read(venueRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateSettings(
        venueId: venueId,
        name: name,
        nip: nip,
        address: address,
        logoUrl: logoUrl,
      );
      // Return updated data
      return repository.getSettings(venueId);
    });
  }

  Future<String?> uploadLogo(File file) async {
    final repository = ref.read(venueRepositoryProvider);
    return await repository.uploadLogo(file, venueId);
  }
}
