import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/venue_repository.dart';

part 'm08_providers.g.dart';

@riverpod
VenueRepository venueRepository(VenueRepositoryRef ref) {
  return VenueRepository();
}

@riverpod
class VenueSettingsController extends _$VenueSettingsController {
  @override
  FutureOr<Map<String, dynamic>?> build(String venueId) async {
    final repo = ref.watch(venueRepositoryProvider);
    return repo.getVenueSettings(venueId);
  }

  Future<void> updateSettings({
    String? name,
    String? nip,
    String? address,
    String? logoUrl,
  }) async {
    final venueId = state.value?['id'];
    if (venueId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(venueRepositoryProvider);
      await repo.updateVenueSettings(
        venueId,
        name: name,
        nip: nip,
        address: address,
        logoUrl: logoUrl,
      );
      return repo.getVenueSettings(venueId);
    });
  }

  Future<String> uploadLogo(File file) async {
    final venueId = state.value?['id'];
    if (venueId == null) throw Exception('Venue ID not found');

    final repo = ref.read(venueRepositoryProvider);
    return repo.uploadLogo(file, venueId);
  }
}
