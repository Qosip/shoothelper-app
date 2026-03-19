import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

enum NetworkStatus { online, offline }

/// Detects real network connectivity (not just Wi-Fi presence).
class ConnectivityService {
  final Connectivity _connectivity;
  final Dio _dio;
  final String _healthUrl;

  final _controller = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  NetworkStatus _lastStatus = NetworkStatus.offline;

  ConnectivityService({
    Connectivity? connectivity,
    Dio? dio,
    required String healthUrl,
  })  : _connectivity = connectivity ?? Connectivity(),
        _dio = dio ?? Dio(),
        _healthUrl = healthUrl;

  NetworkStatus get lastStatus => _lastStatus;
  Stream<NetworkStatus> get statusStream => _controller.stream;

  /// Start listening for connectivity changes.
  void start() {
    _sub = _connectivity.onConnectivityChanged.listen((results) async {
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _update(NetworkStatus.offline);
        return;
      }
      // Real ping to verify actual internet access
      final online = await _ping();
      _update(online ? NetworkStatus.online : NetworkStatus.offline);
    });
  }

  /// One-shot check: do we have real internet?
  Future<bool> checkOnline() async {
    final results = await _connectivity.checkConnectivity();
    final hasInterface = results.any((r) => r != ConnectivityResult.none);
    if (!hasInterface) return false;
    return _ping();
  }

  Future<bool> _ping() async {
    try {
      final response = await _dio.head(
        _healthUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode != null && response.statusCode! < 400;
    } catch (_) {
      return false;
    }
  }

  void _update(NetworkStatus status) {
    if (status != _lastStatus) {
      _lastStatus = status;
      _controller.add(status);
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
