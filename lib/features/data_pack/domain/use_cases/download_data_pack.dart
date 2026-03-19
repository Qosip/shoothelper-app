import 'dart:io';
import '../../../../shared/data/data_sources/remote/data_pack_api.dart';
import '../../../../shared/data/data_sources/local/download_state_source.dart';

/// Progress callback: (downloaded files, total files).
typedef DownloadProgressCallback = void Function(int current, int total);

/// Downloads a complete data pack with atomic swap.
///
/// Pipeline:
/// 1. Fetch manifest
/// 2. Download shared files (if absent)
/// 3. Download body-specific files to temp dir
/// 4. Atomic swap: rename temp → final
/// 5. Update download_state.json
class DownloadDataPack {
  final DataPackApi _api;
  final DownloadStateSource _stateSource;
  final String _dataDir;

  const DownloadDataPack({
    required DataPackApi api,
    required DownloadStateSource stateSource,
    required String dataDir,
  })  : _api = api,
        _stateSource = stateSource,
        _dataDir = dataDir;

  /// Execute the full download pipeline.
  Future<void> call(
    String bodyId, {
    DownloadProgressCallback? onProgress,
  }) async {
    // 1. Fetch manifest
    final manifest = await _api.fetchManifest(bodyId);
    final packVersion = manifest['pack_version'] as String;
    final files = manifest['files'] as Map<String, dynamic>;
    final sharedFiles = manifest['shared_files'] as Map<String, dynamic>? ?? {};

    final totalFiles = files.length + sharedFiles.length;
    var downloaded = 0;

    // 2. Download shared files (skip if already present)
    final sharedDir = '$_dataDir/shared';
    for (final entry in sharedFiles.entries) {
      final fileInfo = entry.value as Map<String, dynamic>;
      final remotePath = fileInfo['path'] as String;
      final localPath = '$sharedDir/${entry.key}';

      if (!File(localPath).existsSync()) {
        await _api.downloadFile(remotePath, localPath);
      }
      downloaded++;
      onProgress?.call(downloaded, totalFiles);
    }

    // 3. Download body files to temp directory
    final tempDir = '$_dataDir/packs/${bodyId}_temp';
    final finalDir = '$_dataDir/packs/$bodyId';

    // Clean up any previous temp dir
    final tempDirectory = Directory(tempDir);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
    await tempDirectory.create(recursive: true);

    for (final entry in files.entries) {
      final fileInfo = entry.value as Map<String, dynamic>;
      final remotePath = fileInfo['path'] as String;
      final localPath = '$tempDir/${entry.key}';

      await _api.downloadFile(remotePath, localPath);
      downloaded++;
      onProgress?.call(downloaded, totalFiles);
    }

    // 4. Atomic swap: remove old final dir, rename temp → final
    final finalDirectory = Directory(finalDir);
    if (await finalDirectory.exists()) {
      await finalDirectory.delete(recursive: true);
    }
    await tempDirectory.rename(finalDir);

    // 5. Update download state
    await _stateSource.markPackComplete(bodyId, packVersion);
  }
}
