import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@riverpod
Stream<bool> connectivity(Ref ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    if (results.isEmpty) return false;
    // Consider as online if any result is not 'none'
    return results.any((result) => result != ConnectivityResult.none);
  });
}

@riverpod
bool isOnline(Ref ref) {
  return ref.watch(connectivityProvider).value ?? true;
}
