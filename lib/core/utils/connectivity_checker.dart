/// Connectivity checker utility.
///
/// Provides a simple interface to check network availability
/// before making API requests.

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityChecker {
  final Connectivity _connectivity;

  ConnectivityChecker({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Returns true if device has an active network connection.
  Future<bool> get hasConnection async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Stream of connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
