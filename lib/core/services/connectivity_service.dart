import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that returns a Stream of connectivity status (Online/Offline).
/// Returns [true] if online, [false] if offline.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    // connectivity_plus 6.0 returns List<ConnectivityResult>
    return !results.contains(ConnectivityResult.none);
  });
});

/// Service class to check connectivity on demand (if needed outside of provider)
class ConnectivityService {
  Future<bool> get isOnline async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
