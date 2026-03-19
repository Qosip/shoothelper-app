import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// API client for fetching data packs from the CDN.
class DataPackApi {
  final Dio _dio;
  final String _baseUrl;

  DataPackApi({required Dio dio, required String baseUrl})
      : _dio = dio,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  /// Fetch catalog.json listing all available bodies.
  Future<Map<String, dynamic>> fetchCatalog() async {
    final response = await _dio.get<String>('$_baseUrl/catalog.json');
    return jsonDecode(response.data!) as Map<String, dynamic>;
  }

  /// Fetch manifest for a specific body pack.
  Future<Map<String, dynamic>> fetchManifest(String bodyId) async {
    final response =
        await _dio.get<String>('$_baseUrl/$bodyId/manifest.json');
    return jsonDecode(response.data!) as Map<String, dynamic>;
  }

  /// Download a file to a local path.
  Future<void> downloadFile(String remotePath, String localPath) async {
    // Ensure parent directory exists
    final file = File(localPath);
    await file.parent.create(recursive: true);

    await _dio.download(
      '$_baseUrl/$remotePath',
      localPath,
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  /// Fetch health.json for connectivity check.
  Future<bool> pingHealth() async {
    try {
      final response = await _dio.head(
        '$_baseUrl/health.json',
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
}
