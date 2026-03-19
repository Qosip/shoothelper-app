import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../shared/domain/entities/catalog.dart';

/// Loads the catalog from bundled assets (MVP) or remote CDN (future).
class LoadCatalog {
  const LoadCatalog();

  Future<Catalog> call() async {
    final jsonStr = await rootBundle.loadString('assets/catalog.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return Catalog.fromJson(json);
  }
}
