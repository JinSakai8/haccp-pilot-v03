import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/venue_repository.dart';

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return VenueRepository();
});

// Controller for Venue Settings
// Uses family to fetch by venueId
final venueSettingsControllerProvider = StateNotifierProvider.family<VenueSettingsController, AsyncValue<Map<String, dynamic>?>, String>((ref, venueId) {
  return VenueSettingsController(ref.read(venueRepositoryProvider), venueId);
});

class VenueSettingsController extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final VenueRepository _repository;
  final String _venueId;

  VenueSettingsController(this._repository, this._venueId) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final data = await _repository.getSettings(_venueId);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings({
    required String name,
    required String nip,
    required String address,
    String? logoUrl,
  }) async {
    try {
      // Optimistic update or wait? Wait for safety.
      await _repository.updateSettings(
        venueId: _venueId,
        name: name,
        nip: nip,
        address: address,
        logoUrl: logoUrl,
      );
      // Reload to confirm
      await loadSettings();
    } catch (e) {
      // UI handles error showing, but we can also set state error if needed
      rethrow;
    }
  }

  Future<String?> uploadLogo(File file) async {
    return await _repository.uploadLogo(file, _venueId);
  }
}
