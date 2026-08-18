import 'package:logging/logging.dart';

final appLog = Logger('bulky');

void initLogging() {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final message = redactSecrets(record.message);
    final error = record.error == null ? '' : ' ${redactSecrets(record.error.toString())}';
    // ignore: avoid_print
    print('${record.level.name} ${record.time.toIso8601String()} ${record.loggerName}: $message$error');
  });
}

String redactSecrets(String input) {
  return input
      .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9._\-]+'), 'Bearer [redacted]')
      .replaceAll(RegExp(r'api[_-]?key["\s:=]+[A-Za-z0-9._\-]+', caseSensitive: false), 'api_key=[redacted]');
}
