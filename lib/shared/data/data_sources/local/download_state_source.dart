import 'dart:convert';
import 'dart:io';

/// Tracks download completion status for data packs.
class DownloadStateSource {
  final String _statePath;

  DownloadStateSource({required String dataDir})
      : _statePath = '$dataDir/meta/download_state.json';

  /// Load the full download state.
  Future<Map<String, dynamic>> load() async {
    final file = File(_statePath);
    if (!await file.exists()) {
      return {'packs': <String, dynamic>{}};
    }
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Save the full download state.
  Future<void> save(Map<String, dynamic> state) async {
    final file = File(_statePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state));
  }

  /// Check if a body pack is fully downloaded.
  Future<bool> isPackComplete(String bodyId) async {
    final state = await load();
    final packs = state['packs'] as Map<String, dynamic>? ?? {};
    final pack = packs[bodyId] as Map<String, dynamic>?;
    return pack?['status'] == 'complete';
  }

  /// Mark a body pack as complete.
  Future<void> markPackComplete(String bodyId, String packVersion) async {
    final state = await load();
    final packs = state['packs'] as Map<String, dynamic>? ?? {};
    packs[bodyId] = {
      'status': 'complete',
      'pack_version': packVersion,
      'completed_at': DateTime.now().toIso8601String(),
    };
    state['packs'] = packs;
    await save(state);
  }

  /// Mark a body pack as incomplete (e.g., interrupted download).
  Future<void> markPackIncomplete(
    String bodyId, {
    Map<String, bool>? fileStatus,
  }) async {
    final state = await load();
    final packs = state['packs'] as Map<String, dynamic>? ?? {};
    packs[bodyId] = {
      'status': 'incomplete',
      if (fileStatus case final fs?) 'files': fs,
    };
    state['packs'] = packs;
    await save(state);
  }

  /// Remove a pack's download state entirely.
  Future<void> removePack(String bodyId) async {
    final state = await load();
    final packs = state['packs'] as Map<String, dynamic>? ?? {};
    packs.remove(bodyId);
    state['packs'] = packs;
    await save(state);
  }
}
