import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'example agent and client complete a prompt across processes',
    () async {
      final process = await Process.start(Platform.resolvedExecutable, [
        'run',
        'example/client.dart',
      ]);
      process.stdin.writeln('1');
      await process.stdin.flush();
      await process.stdin.close();

      final stdout = process.stdout.transform(utf8.decoder).join();
      final stderr = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          process.kill();
          throw StateError('Example process did not finish');
        },
      );

      expect(exitCode, 0);
      expect(await stderr, isNot(contains('[Client] Error:')));
      expect(await stdout, contains('Agent completed with stop reason'));
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );
}
