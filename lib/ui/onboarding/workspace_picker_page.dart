import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/nuke/nuke_models.dart';
import '../theme.dart';

class WorkspacePickerPage extends ConsumerWidget {
  const WorkspacePickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: BulkyTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BulkyTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.workspaces_outlined, color: BulkyTheme.accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Workspace',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Choose the workspace to upload videos from.',
                          style: TextStyle(color: BulkyTheme.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                if (session.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BulkyTheme.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(session.error!, style: const TextStyle(color: BulkyTheme.danger, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Workspace tiles
                ...session.workspaces.map((ws) => _WorkspaceTile(
                      workspace: ws,
                      onTap: session.loading
                          ? null
                          : () => ref.read(sessionProvider.notifier).selectWorkspace(ws),
                    )),

                if (session.loading) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator(color: BulkyTheme.accent)),
                ],

                const SizedBox(height: 28),
                TextButton(
                  onPressed: session.loading ? null : () => ref.read(sessionProvider.notifier).signOut(),
                  child: const Text('Sign out', style: TextStyle(color: BulkyTheme.muted, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceTile extends StatefulWidget {
  const _WorkspaceTile({required this.workspace, required this.onTap});

  final NukeWorkspace workspace;
  final VoidCallback? onTap;

  @override
  State<_WorkspaceTile> createState() => _WorkspaceTileState();
}

class _WorkspaceTileState extends State<_WorkspaceTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: _hovered ? BulkyTheme.panelAlt : BulkyTheme.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? BulkyTheme.accent.withValues(alpha: 0.4) : BulkyTheme.panelAlt,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: BulkyTheme.accent.withValues(alpha: 0.18),
                      child: Text(
                        widget.workspace.name.isNotEmpty
                            ? widget.workspace.name[0].toUpperCase()
                            : 'W',
                        style: const TextStyle(
                          color: BulkyTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.workspace.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            widget.workspace.role,
                            style: const TextStyle(color: BulkyTheme.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: BulkyTheme.muted, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
