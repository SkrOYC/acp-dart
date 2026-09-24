import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final sdkRoot = Platform.environment['ACP_TYPESCRIPT_SDK_DIR'];

  test(
    'official TypeScript v1.5 client completes ACP over Dart stdio agent',
    () async {
      if (sdkRoot == null || sdkRoot.isEmpty) return;

      final root = Directory.current.absolute.path;
      final process = await Process.start(
        'bun',
        ['run', 'tool/typescript_v15_interop.ts'],
        environment: {
          ...Platform.environment,
          'ACP_DART_ROOT': root,
          'ACP_TYPESCRIPT_SDK_DIR': sdkRoot,
        },
      );
      final stdout = process.stdout.transform(utf8.decoder).join();
      final stderr = process.stderr.transform(utf8.decoder).join();
      late final int exitCode;
      try {
        exitCode = await process.exitCode.timeout(const Duration(seconds: 45));
      } on TimeoutException {
        process.kill(ProcessSignal.sigterm);
        try {
          await process.exitCode.timeout(const Duration(seconds: 2));
        } on TimeoutException {
          process.kill(ProcessSignal.sigkill);
        }
        throw StateError('TypeScript v1.5 interop process timed out');
      }

      expect(exitCode, 0, reason: await stderr);
      final output = await stdout;
      expect(output, contains('"protocolVersion":1'));
      final result = jsonDecode(output) as Map<String, dynamic>;
      expect(result['permissionRequests'], greaterThanOrEqualTo(1));
      expect(result['stopReason'], 'end_turn');
      expect(result['sessionCancelStopReason'], 'cancelled');
      expect(result['cancellationNotifications'], 1);
      expect(result['cancellationStopReason'], anyOf('cancelled', 'end_turn'));
      expect(await stderr, isEmpty);
    },
    skip: sdkRoot == null || sdkRoot.isEmpty
        ? 'Set ACP_TYPESCRIPT_SDK_DIR to a local TypeScript SDK v1.5.0 clone'
        : false,
    timeout: const Timeout(Duration(seconds: 55)),
  );
}
