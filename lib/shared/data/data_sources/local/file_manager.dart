import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Abstract filesystem interface for reading/writing JSON data packs.
/// Skill 12 §3 FileManager.
abstract class FileManager {
  /// Reads a JSON file and returns the parsed content.
  Future<dynamic> readJson(String relativePath);

  /// Writes JSON content to a file.
  Future<void> writeJson(String relativePath, dynamic data);

  /// Checks if a file exists.
  Future<bool> fileExists(String relativePath);

  /// Lists files in a directory.
  Future<List<String>> listFiles(String relativePath);

  /// Deletes a directory recursively.
  Future<void> deleteDirectory(String relativePath);

  /// Lists all downloaded data packs (body IDs).
  Future<List<String>> listDownloadedPacks();
}

/// Default implementation using dart:io filesystem.
class FileSystemManager implements FileManager {
  final String rootPath;

  const FileSystemManager({required this.rootPath});

  String _resolve(String relativePath) => p.join(rootPath, relativePath);

  @override
  Future<dynamic> readJson(String relativePath) async {
    final file = File(_resolve(relativePath));
    final content = await file.readAsString();
    return json.decode(content);
  }

  @override
  Future<void> writeJson(String relativePath, dynamic data) async {
    final file = File(_resolve(relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(json.encode(data));
  }

  @override
  Future<bool> fileExists(String relativePath) async {
    return File(_resolve(relativePath)).exists();
  }

  @override
  Future<List<String>> listFiles(String relativePath) async {
    final dir = Directory(_resolve(relativePath));
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => p.basename(f.path))
        .toList();
  }

  @override
  Future<void> deleteDirectory(String relativePath) async {
    final dir = Directory(_resolve(relativePath));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<List<String>> listDownloadedPacks() async {
    final packsDir = Directory(_resolve('packs'));
    if (!await packsDir.exists()) return [];
    return packsDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList();
  }
}
