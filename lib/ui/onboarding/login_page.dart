import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/config.dart';
import '../theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _showPass = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill saved email.
    final savedEmail = ref.read(sessionProvider).savedEmail;
    if (savedEmail != null) _emailCtrl.text = savedEmail;
    // Spin up the Google-login popup hidden now, while the user is still
    // looking at this form, so clicking "Sign in with Google" feels instant
    // instead of visibly cold-starting a native window at that moment.
    unawaited(ref.read(sessionProvider.notifier).prewarmGoogleLogin());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(sessionProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passCtrl.text,
          );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: Row(
        children: [
          // Left branding strip
          Container(
            width: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF0D0D16)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: BulkyTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BulkyTheme.accent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.upload_rounded, color: BulkyTheme.accent, size: 28),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'bulky',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: BulkyTheme.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bulk upload hundreds of videos to YouTube with Nuke.',
                    style: TextStyle(
                      fontSize: 14,
                      color: BulkyTheme.muted,
                      height: 1.55,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _dot(BulkyTheme.accent),
                      const SizedBox(width: 8),
                      const Text(
                        'Queue-based, crash-safe',
                        style: TextStyle(color: BulkyTheme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _dot(BulkyTheme.ok),
                      const SizedBox(width: 8),
                      const Text(
                        'Supports Insta360 + images',
                        style: TextStyle(color: BulkyTheme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _dot(const Color(0xFF6B8BFF)),
                      const SizedBox(width: 8),
                      const Text(
                        'Direct-to-S3 at original quality',
                        style: TextStyle(color: BulkyTheme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right login form
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Sign in to Nuke',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Use Google or email. After sign-in, bulky checks that this account has an active plan and a connected YouTube channel.',
                          style: TextStyle(color: BulkyTheme.muted, fontSize: 14, height: 1.45),
                        ),

                        if (session.hasSetupInstructions) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            decoration: BoxDecoration(
                              color: BulkyTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: BulkyTheme.accent.withValues(alpha: 0.45)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.setupTitle ?? 'Finish setup on the Nuke website first',
                                  style: const TextStyle(
                                    color: BulkyTheme.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  session.setupBody!,
                                  style: const TextStyle(color: BulkyTheme.text, fontSize: 13, height: 1.5),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => ref.read(sessionProvider.notifier).openSetupWebsite(),
                                    icon: const Icon(Icons.open_in_browser, size: 18),
                                    label: const Text('Open Nuke website'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: BulkyTheme.accent,
                                      side: const BorderSide(color: BulkyTheme.accent),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        
                        // Google Login
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _submitting || session.loading
                                ? null
                                : () {
                                    ref.read(sessionProvider.notifier).loginWithGoogle();
                                  },
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Sign in with Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BulkyTheme.text,
                              side: const BorderSide(color: BulkyTheme.panelAlt),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: BulkyTheme.panelAlt)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(color: BulkyTheme.muted, fontSize: 12)),
                            ),
                            Expanded(child: Divider(color: BulkyTheme.panelAlt)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          enabled: !_submitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.mail_outline, color: BulkyTheme.muted),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required.';
                            if (!v.contains('@')) return 'Enter a valid email address.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passCtrl,
                          enabled: !_submitting,
                          obscureText: !_showPass,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, color: BulkyTheme.muted),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: BulkyTheme.muted,
                              ),
                              onPressed: () => setState(() => _showPass = !_showPass),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required.';
                            return null;
                          },
                        ),

                        // Error display
                        if (session.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: BulkyTheme.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: BulkyTheme.danger.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: BulkyTheme.danger, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    session.error!,
                                    style: const TextStyle(color: BulkyTheme.danger, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Sign in button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _submitting || session.loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BulkyTheme.accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _submitting || session.loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black54,
                                    ),
                                  )
                                : const Text(
                                    'Sign in with Nuke',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () => launchUrl(
                              Uri.parse(AppConfig.nukeWebBaseUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: const Text(
                              "Don't have an account? Open Nuke",
                              style: TextStyle(color: BulkyTheme.muted, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
