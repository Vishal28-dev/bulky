import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/config.dart';
import '../../data/db/queue_database.dart';
import '../../domain/media/media_classifier.dart';
import '../../domain/queue/queue_worker.dart';

import '../theme.dart';

// ─── Main Page ─────────────────────────────────────────────────────────────

class BulkyPage extends ConsumerStatefulWidget {
  const BulkyPage({super.key});

  @override
  ConsumerState<BulkyPage> createState() => _BulkyPageState();
}

class _BulkyPageState extends ConsumerState<BulkyPage> {
  bool _busy = false;
  String? _notice;
  bool _settingsOpen = false;

  Future<void> _pickFolder() async {
    setState(() => _busy = true);
    _notice = null;
    try {
      final result = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Pick folder of videos/images');
      if (result == null) return;

      final worker = ref.read(queueWorkerProvider);
      final classified = await worker.scanAndValidate(result);
      if (!mounted) return;

      if (classified.isEmpty) {
        setState(() => _notice = 'No supported files found in that folder.');
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _ScanReviewDialog(classified: classified),
      );
      if (confirmed != true) {
        setState(() => _notice = 'Cancelled — nothing was queued.');
        return;
      }

      final enqueueResult = await worker.enqueueClassified(result, classified);
      setState(() => _notice = _enqueueNotice(enqueueResult));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _enqueueNotice(EnqueueResult result) {
    if (result.isEmpty) {
      return 'No new files added — everything in that folder is already queued, in progress, or already published.';
    }
    final first = result.firstSlot?.toLocal();
    if (first == null) return '${result.added} added to queue.';
    final hour = first.hour % 12 == 0 ? 12 : first.hour % 12;
    final minute = first.minute.toString().padLeft(2, '0');
    final ampm = first.hour < 12 ? 'AM' : 'PM';
    return '${result.added} queued · 15 per day every 15 min · first at $hour:$minute $ampm.';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final cap = ref.watch(stitchCapProvider).maybeWhen(data: (v) => v, orElse: () => null);
    final jobs = jobsAsync.valueOrNull ?? const <QueueJob>[];
    final counts = _counts(jobs);
    final working = jobs.where(
      (j) =>
          j.status == JobStatus.uploading ||
          j.status == JobStatus.stitching ||
          j.status == JobStatus.preparing ||
          j.status == JobStatus.publishing,
    );
    final current = working.isEmpty ? null : working.first;
    final isPaused = ref.watch(queueWorkerProvider).isPaused;

    return Scaffold(
      body: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────────
          _TopBar(
            workspaceName: session.activeWorkspaceName ?? 'bulky',
            youtubeUsername: session.youtubeUsername ?? 'YouTube',
            stitchReady: cap?.available ?? false,
            onSettings: () => setState(() => _settingsOpen = !_settingsOpen),
            onReconnect: () => ref.read(sessionProvider.notifier).reconnectYouTube(),
            onSignOut: () => ref.read(sessionProvider.notifier).signOut(),
          ),

          const Divider(height: 1, color: Colors.black54),

          // ── Controls bar ───────────────────────────────────────────────
          Container(
            color: BulkyTheme.panel,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Actions (left) and stat chips (right) share one row instead
                // of stacking — fills the width instead of leaving it empty.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _busy ? null : _pickFolder,
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('Add Folder'),
                        ),
                        _OutlineBtn(
                          icon: isPaused ? Icons.play_arrow : Icons.pause,
                          label: isPaused ? 'Resume' : 'Pause',
                          onTap: () => ref.read(queueWorkerProvider).setPaused(!isPaused),
                        ),
                        _OutlineBtn(
                          icon: Icons.clear_all,
                          label: 'Cancel Pending',
                          onTap: () => ref.read(databaseProvider).cancelPending(),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatChip('Queued', counts[JobStatus.pending] ?? 0, BulkyTheme.muted),
                        _StatChip(
                          'Working',
                          (counts[JobStatus.preparing] ?? 0) +
                              (counts[JobStatus.stitching] ?? 0) +
                              (counts[JobStatus.uploading] ?? 0) +
                              (counts[JobStatus.publishing] ?? 0),
                          BulkyTheme.accent,
                        ),
                        _StatChip('Published', counts[JobStatus.published] ?? 0, BulkyTheme.ok),
                        _StatChip('Scheduled', counts[JobStatus.scheduled] ?? 0, BulkyTheme.accent),
                        _StatChip('Failed', counts[JobStatus.failed] ?? 0, BulkyTheme.danger),
                        _StatChip('Skipped', counts[JobStatus.skipped] ?? 0, BulkyTheme.muted),
                      ],
                    ),
                  ],
                ),

                // Active job progress
                if (current != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BulkyTheme.panelAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${current.stageLabel}  ·  ${p.basename(current.sourcePath)}',
                                style: const TextStyle(color: BulkyTheme.text, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${current.progress}%',
                              style: const TextStyle(color: BulkyTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: current.progress / 100,
                            color: BulkyTheme.accent,
                            backgroundColor: BulkyTheme.bg,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_notice != null) ...[
                  const SizedBox(height: 12),
                  _InlineBanner(icon: Icons.info_outline, color: BulkyTheme.muted, text: _notice!),
                ],

                if (isPaused) ...[
                  const SizedBox(height: 12),
                  const _InlineBanner(
                    icon: Icons.pause_circle_outline,
                    color: BulkyTheme.accent,
                    text: 'Queue is paused',
                  ),
                ],
              ],
            ),
          ),

          // ── Settings panel (collapsible) ──────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _settingsOpen ? const _SettingsPanel() : const SizedBox.shrink(),
          ),

          if (_settingsOpen) const Divider(height: 1, color: Colors.black54),

          const Divider(height: 1, color: Colors.black54),

          // ── Job list ──────────────────────────────────────────────────
          Expanded(
            child: jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.upload_file_outlined, size: 52, color: BulkyTheme.panelAlt),
                        const SizedBox(height: 16),
                        const Text(
                          'No files queued yet',
                          style: TextStyle(color: BulkyTheme.muted, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click "Add Folder" to point to a folder of videos,\nimages, or Insta360 files.',
                          style: TextStyle(color: BulkyTheme.muted, fontSize: 13, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) => _JobTile(job: jobs[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _counts(List<QueueJob> jobs) {
    final map = <String, int>{};
    for (final job in jobs) {
      map[job.status] = (map[job.status] ?? 0) + 1;
    }
    return map;
  }
}

// ─── Top bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.workspaceName,
    required this.youtubeUsername,
    required this.stitchReady,
    required this.onSettings,
    required this.onReconnect,
    required this.onSignOut,
  });

  final String workspaceName;
  final String youtubeUsername;
  final bool stitchReady;
  final VoidCallback onSettings;
  final VoidCallback onReconnect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BulkyTheme.panel,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Text(
            'bulky',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: BulkyTheme.accent,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 1,
            height: 16,
            color: BulkyTheme.panelAlt,
          ),
          Tooltip(
            message: workspaceName,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: BulkyTheme.panelAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspaces_outlined, size: 14, color: BulkyTheme.muted),
                  const SizedBox(width: 6),
                  Text(workspaceName, style: const TextStyle(color: BulkyTheme.muted, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: BulkyTheme.panelAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_fill, size: 14, color: Color(0xFFFF4444)),
                const SizedBox(width: 6),
                Text(youtubeUsername, style: const TextStyle(color: BulkyTheme.muted, fontSize: 13)),
              ],
            ),
          ),
          const Spacer(),
          // Stitch badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: stitchReady ? const Color(0x203DDC97) : const Color(0x20E8A317),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.panorama_outlined,
                  size: 13,
                  color: stitchReady ? BulkyTheme.ok : BulkyTheme.accent,
                ),
                const SizedBox(width: 5),
                Text(
                  stitchReady ? '360° ready' : 'ffmpeg missing',
                  style: TextStyle(
                    color: stitchReady ? BulkyTheme.ok : BulkyTheme.accent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'YouTube settings',
            icon: const Icon(Icons.tune, color: BulkyTheme.muted, size: 20),
            onPressed: onSettings,
          ),
          IconButton(
            tooltip: 'Reconnect YouTube',
            icon: const Icon(Icons.link, color: BulkyTheme.muted, size: 20),
            onPressed: onReconnect,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: BulkyTheme.muted, size: 20),
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}

// ─── Settings panel ─────────────────────────────────────────────────────────

class _SettingsPanel extends ConsumerStatefulWidget {
  const _SettingsPanel();

  @override
  ConsumerState<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<_SettingsPanel> {
  String _visibility = 'unlisted';
  String _categoryId = '22';
  String _playlistId = '';
  String _firstComment = '';
  bool _madeForKids = false;
  bool _containsAI = false;

  final _playlistCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    _visibility = await db.setting(SettingKeys.visibility) ?? 'unlisted';
    _categoryId = await db.setting(SettingKeys.ytCategoryId) ?? '22';
    _playlistId = await db.setting(SettingKeys.ytPlaylistId) ?? '';
    _firstComment = await db.setting(SettingKeys.ytFirstComment) ?? '';
    _madeForKids = await db.setting(SettingKeys.ytMadeForKids) == '1';
    _containsAI = await db.setting(SettingKeys.ytContainsAI) == '1';
    _playlistCtrl.text = _playlistId;
    _commentCtrl.text = _firstComment;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save(String key, String value) async {
    await ref.read(databaseProvider).setSetting(key, value);
  }

  @override
  void dispose() {
    _playlistCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: BulkyTheme.accent)),
      );
    }
    return Container(
      color: BulkyTheme.panel,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          _SettingField(
            label: 'Visibility',
            width: 170,
            child: _SettingDropdown<String>(
              value: _visibility,
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'unlisted', child: Text('Unlisted')),
                DropdownMenuItem(value: 'private', child: Text('Private')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _visibility = v);
                  unawaited(_save(SettingKeys.visibility, v));
                }
              },
            ),
          ),

          _SettingField(
            label: 'Category',
            width: 190,
            child: _SettingDropdown<String>(
              value: _categoryId,
              items: AppConfig.ytCategories.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _categoryId = v);
                  unawaited(_save(SettingKeys.ytCategoryId, v));
                }
              },
            ),
          ),

          _SettingField(
            label: 'Playlist ID',
            width: 220,
            child: _SettingTextField(
              controller: _playlistCtrl,
              hintText: 'PLxxxxxxxxxxxxxxxxxx',
              onChanged: (v) {
                _playlistId = v;
                unawaited(_save(SettingKeys.ytPlaylistId, v));
              },
            ),
          ),

          _SettingField(
            label: 'First Comment',
            width: 260,
            child: _SettingTextField(
              controller: _commentCtrl,
              hintText: 'Optional pinned comment…',
              onChanged: (v) {
                _firstComment = v;
                unawaited(_save(SettingKeys.ytFirstComment, v));
              },
            ),
          ),

          _SettingField(
            label: 'Made for Kids',
            width: 150,
            child: _SettingSwitch(
              value: _madeForKids,
              onChanged: (v) {
                setState(() => _madeForKids = v);
                unawaited(_save(SettingKeys.ytMadeForKids, v ? '1' : '0'));
              },
            ),
          ),

          _SettingField(
            label: 'Contains AI Media',
            width: 150,
            child: _SettingSwitch(
              value: _containsAI,
              onChanged: (v) {
                setState(() => _containsAI = v);
                unawaited(_save(SettingKeys.ytContainsAI, v ? '1' : '0'));
              },
            ),
          ),

          Tooltip(
            message: 'Every folder is scheduled 15 videos per day, 15 minutes apart. The first goes out 15 minutes after you add the folder. The next day starts exactly 24 hours after that first slot.',
            child: _SettingField(
              label: 'Schedule',
              width: 220,
              child: const SizedBox(
                height: 36,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '15 / day · every 15 min',
                    style: TextStyle(color: BulkyTheme.text, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One field's label + control, in a bordered card so every field reads as
/// the same kind of thing regardless of whether it holds a dropdown, a text
/// box, or a toggle — dropdowns/switches previously floated with no visual
/// container at all while text fields had one, which is what made the row
/// look scattered rather than like a single form.
class _SettingField extends StatelessWidget {
  const _SettingField({required this.label, required this.child, required this.width});
  final String label;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: BulkyTheme.panelAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: BulkyTheme.muted, fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Dropdown boxed to match the text fields' height and fill — the bare
/// underline-only DropdownButton used to look visually unrelated to every
/// other control on the same row.
class _SettingDropdown<T> extends StatelessWidget {
  const _SettingDropdown({required this.value, required this.items, required this.onChanged});
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: BulkyTheme.bg, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: BulkyTheme.panelAlt,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: BulkyTheme.muted),
          style: const TextStyle(color: BulkyTheme.text, fontSize: 13),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SettingTextField extends StatelessWidget {
  const _SettingTextField({required this.controller, required this.hintText, required this.onChanged});
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          filled: true,
          fillColor: BulkyTheme.bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: onChanged,
      ),
    );
  }
}

/// Switch plus an explicit On/Off label — a bare thumb on a dark track reads
/// as ambiguous at this size; the word next to it removes any doubt.
class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Transform.scale(
            scale: 0.85,
            alignment: Alignment.centerLeft,
            child: Switch(
              value: value,
              activeThumbColor: BulkyTheme.bg,
              activeTrackColor: BulkyTheme.accent,
              inactiveThumbColor: BulkyTheme.muted,
              inactiveTrackColor: BulkyTheme.bg,
              onChanged: onChanged,
            ),
          ),
          Text(
            value ? 'On' : 'Off',
            style: TextStyle(
              color: value ? BulkyTheme.accent : BulkyTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan review / approval dialog ──────────────────────────────────────────

class _ScanReviewDialog extends StatelessWidget {
  const _ScanReviewDialog({required this.classified});
  final List<ClassifiedMedia> classified;

  @override
  Widget build(BuildContext context) {
    final ready = classified.where((c) => !c.skipped).toList();
    final skipped = classified.where((c) => c.skipped).toList();

    final kindCounts = <String, int>{};
    for (final item in ready) {
      kindCounts[item.kind] = (kindCounts[item.kind] ?? 0) + 1;
    }

    return AlertDialog(
      backgroundColor: BulkyTheme.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Review before scheduling', style: TextStyle(color: BulkyTheme.text, fontSize: 18)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found ${classified.length} file${classified.length == 1 ? '' : 's'} in this folder.',
              style: const TextStyle(color: BulkyTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Ready-to-upload summary
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: BulkyTheme.ok),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ready.length} will be queued and scheduled, 15 per day every 15 minutes'
                    '${kindCounts.isEmpty ? '' : ' (${kindCounts.entries.map((e) => '${e.value} ${e.key}').join(', ')})'}',
                    style: const TextStyle(color: BulkyTheme.text, fontSize: 13),
                  ),
                ),
              ],
            ),

            if (skipped.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.block, size: 16, color: BulkyTheme.danger),
                  const SizedBox(width: 8),
                  Text(
                    '${skipped.length} will be skipped — not scheduled',
                    style: const TextStyle(color: BulkyTheme.danger, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: BulkyTheme.panelAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: skipped.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: BulkyTheme.bg),
                  itemBuilder: (context, i) {
                    final item = skipped[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.basename(item.primaryPath),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: BulkyTheme.text, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.skipReason ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: BulkyTheme.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: BulkyTheme.muted),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: ready.isEmpty ? null : () => Navigator.of(context).pop(true),
          child: Text(ready.isEmpty ? 'Nothing to queue' : 'Queue ${ready.length} & schedule'),
        ),
      ],
    );
  }
}

// ─── Job tile ──────────────────────────────────────────────────────────────

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});
  final QueueJob job;

  static const _trailingWidth = 168.0;
  static const _actionSlot = 34.0;

  @override
  Widget build(BuildContext context) {
    final isActive = job.status == JobStatus.preparing ||
        job.status == JobStatus.stitching ||
        job.status == JobStatus.uploading ||
        job.status == JobStatus.publishing;

    final isFailed = job.status == JobStatus.failed;

    final statusColor = switch (job.status) {
      JobStatus.published => BulkyTheme.ok,
      JobStatus.failed => BulkyTheme.danger,
      JobStatus.skipped => BulkyTheme.muted,
      JobStatus.scheduled => BulkyTheme.accent,
      _ when isActive => BulkyTheme.accent,
      _ => BulkyTheme.muted,
    };

    final kindIcon = switch (job.mediaKind) {
      'insv' || 'spherical_video' => Icons.panorama_outlined,
      'insp' || 'image' => Icons.image_outlined,
      _ => Icons.videocam_outlined,
    };

    final subtitle = [
      switch (job.status) {
        JobStatus.scheduled when job.scheduledFor != null =>
          'Scheduled for ${_formatDateTime(job.scheduledFor!)}',
        JobStatus.published when job.publishedAt != null =>
          'Published ✓ · ${_formatDateTime(job.publishedAt!)}',
        _ => job.stageLabel.isNotEmpty ? job.stageLabel : job.status,
      },
      if (isFailed && job.errorMessage != null && job.errorMessage!.isNotEmpty) job.errorMessage!,
    ].join('  ·  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: BulkyTheme.panel,
        borderRadius: BorderRadius.circular(10),
        border: isFailed ? Border.all(color: BulkyTheme.danger.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status-tinted icon chip.
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isFailed ? BulkyTheme.danger : statusColor).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFailed ? Icons.error_outline : kindIcon,
              color: isFailed ? BulkyTheme.danger : statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),

          // Title + subtitle.
          Expanded(
            child: Tooltip(
              message: isFailed && job.errorMessage != null ? job.errorMessage! : '',
              waitDuration: const Duration(milliseconds: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.basename(job.sourcePath),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BulkyTheme.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isFailed ? BulkyTheme.danger.withValues(alpha: 0.85) : BulkyTheme.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Fixed-width trailing zone — every row's status pill and action
          // button line up at the same x position regardless of state.
          SizedBox(
            width: _trailingWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(child: _StatusPill(job: job, color: statusColor, isActive: isActive)),
                const SizedBox(width: 6),
                SizedBox(
                  width: _actionSlot,
                  height: _actionSlot,
                  child: job.status == JobStatus.published && job.youtubeUrl != null
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.open_in_new, size: 16, color: BulkyTheme.muted),
                          tooltip: 'Open on YouTube',
                          onPressed: () => launchUrl(
                            Uri.parse(job.youtubeUrl!),
                            mode: LaunchMode.externalApplication,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small rounded status pill — replaces the old bare "%"/"✓" text so every
/// row's status reads consistently regardless of state.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.job, required this.color, required this.isActive});
  final QueueJob job;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              value: job.progress > 0 ? job.progress / 100 : null,
              color: BulkyTheme.accent,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text('${job.progress}%', style: const TextStyle(color: BulkyTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
    }

    final label = switch (job.status) {
      JobStatus.published => 'Published',
      JobStatus.failed => 'Failed',
      JobStatus.skipped => 'Skipped',
      JobStatus.scheduled => 'Scheduled',
      _ => 'Queued',
    };

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

final _dateTimeFormat = DateFormat('MMM d, h:mm a');

String _formatDateTime(DateTime dt) => _dateTimeFormat.format(dt.toLocal());

/// Colored stat pill — same visual language as the job list's status pills,
/// so the toolbar and the list read as one consistent design instead of two.
class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color),
            ),
            TextSpan(
              text: label,
              style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tinted, icon-led banner for one-line status/notice text — replaces bare
/// gray text so informational messages have the same visual weight as
/// everything else on the page instead of looking like an afterthought.
class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: BulkyTheme.muted,
        side: const BorderSide(color: BulkyTheme.panelAlt),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
