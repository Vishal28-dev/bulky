import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/app_paths.dart';
import 'core/env.dart';
import 'core/local_data.dart';
import 'core/logger.dart';
import 'data/nuke/nuke_auth_client.dart';

import 'package:desktop_webview_window/desktop_webview_window.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
  initLogging();
  await AppEnv.load();
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(900, 620),
      title: 'bulky',
      backgroundColor: Colors.transparent,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  final support = await getApplicationSupportDirectory();
  final paths = await AppPaths.create(Directory(p.join(support.path, 'bulky')));
  await LocalData.syncNukeHost(paths);

  // NukeAuthClient needs the support path for the persistent cookie jar.
  final authClient = await NukeAuthClient.create(
    appSupportPath: paths.supportDir.path,
  );

  final container = ProviderContainer(
    overrides: [
      appPathsProvider.overrideWithValue(paths),
      nukeAuthClientProvider.overrideWithValue(authClient),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BulkyApp(),
    ),
  );
}
