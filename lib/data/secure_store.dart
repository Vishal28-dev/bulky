import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Persists non-secret user preferences across app restarts.
/// - Email: pre-fills login form (not a secret, but stored securely for safety)
/// - WorkspaceId: last selected workspace (avoids re-picking every launch)
///
/// The access token is NEVER stored here — it lives in memory only.
/// The refresh cookie is stored by PersistCookieJar on disk (in NukeAuthClient).
class SecureStore {
  SecureStore({required this.supportPath});
  
  final String supportPath;
  File get _file => File(p.join(supportPath, 'store.json'));
  
  Map<String, dynamic> _readMap() {
    try {
      if (_file.existsSync()) {
        final content = _file.readAsStringSync();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }
  
  void _writeMap(Map<String, dynamic> map) {
    try {
      _file.writeAsStringSync(jsonEncode(map));
    } catch (_) {}
  }

  static const _emailKey = 'nuke_email';
  static const _workspaceIdKey = 'nuke_workspace_id';
  static const _workspaceNameKey = 'nuke_workspace_name';

  Future<String?> readEmail() async => _readMap()[_emailKey];
  Future<void> writeEmail(String value) async {
    final m = _readMap();
    m[_emailKey] = value.trim();
    _writeMap(m);
  }

  Future<String?> readWorkspaceId() async => _readMap()[_workspaceIdKey];
  Future<void> writeWorkspaceId(String value) async {
    final m = _readMap();
    m[_workspaceIdKey] = value;
    _writeMap(m);
  }

  Future<String?> readWorkspaceName() async => _readMap()[_workspaceNameKey];
  Future<void> writeWorkspaceName(String value) async {
    final m = _readMap();
    m[_workspaceNameKey] = value;
    _writeMap(m);
  }

  Future<void> clearWorkspace() async {
    final m = _readMap();
    m.remove(_workspaceIdKey);
    m.remove(_workspaceNameKey);
    _writeMap(m);
  }

  Future<void> clearAll() async {
    try {
      if (_file.existsSync()) _file.deleteSync();
    } catch (_) {}
  }
}
