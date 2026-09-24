import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

class _ToolProcess {
  _ToolProcess(this.process, this.lines, this.stderr);

  final Process process;
  final StreamIterator<String> lines;
  final Future<String> stderr;

  Future<void> stop() async {
    process.kill(ProcessSignal.sigterm);
    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
    }
    await lines.cancel();
  }
}

class _DartStressState {
  int connections = 0;
  int initializes = 0;
  int prompts = 0;
  int sessionCancels = 0;
  int requestCancels = 0;
  final List<String> permissionOutcomes = [];
  final List<String> fileContents = [];
}

class _DartStressAgent extends Agent implements ProtocolCancellationHandler {
  _DartStressAgent(this.client, this.state) {
    state.connections += 1;
  }

  final AgentSideConnection client;
  final _DartStressState state;
  final Set<String> sessions = {};
  final Map<String, Completer<void>> sessionCancellation = {};
  Completer<void>? requestCancellation;
  int nextSession = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async {
    state.initializes += 1;
    return InitializeResponse(
      protocolVersion: acpProtocolVersion,
      agentCapabilities: AgentCapabilities(loadSession: false),
      authMethods: const [],
    );
  }

  @override
  Future<NewSessionResponse> newSession(NewSessionRequest params) async {
    nextSession += 1;
    final sessionId = 'dart-${state.connections}-$nextSession';
    sessions.add(sessionId);
    return NewSessionResponse(sessionId: sessionId);
  }

  @override
  Future<PromptResponse> prompt(PromptRequest params) async {
    state.prompts += 1;
    if (!sessions.contains(params.sessionId)) {
      throw RequestError.resourceNotFound(params.sessionId);
    }
    final text = params.prompt
        .whereType<TextContentBlock>()
        .map((block) => block.text)
        .join();
    if (text == 'cancel-with-session') {
      final cancellation = Completer<void>();
      sessionCancellation[params.sessionId] = cancellation;
      await cancellation.future;
      sessionCancellation.remove(params.sessionId);
      return PromptResponse(stopReason: StopReason.cancelled);
    }
    if (text == 'cancel-with-request') {
      final cancellation = Completer<void>();
      requestCancellation = cancellation;
      await cancellation.future;
      requestCancellation = null;
      return PromptResponse(stopReason: StopReason.cancelled);
    }

    await client.sessionUpdate(
      SessionNotification(
        sessionId: params.sessionId,
        update: AgentMessageChunkSessionUpdate(
          content: TextContentBlock(text: '$text:first'),
        ),
      ),
    );
    final permission = await client.requestPermission(
      RequestPermissionRequest(
        sessionId: params.sessionId,
        toolCall: ToolCallUpdate(
          toolCallId: '$text-${params.sessionId}',
          title: 'Read file',
        ),
        options: [
          PermissionOption(
            optionId: 'allow',
            name: 'Allow once',
            kind: PermissionOptionKind.allowOnce,
          ),
          PermissionOption(
            optionId: 'reject',
            name: 'Reject once',
            kind: PermissionOptionKind.rejectOnce,
          ),
        ],
      ),
    );
    final outcome = switch (permission.outcome) {
      SelectedOutcome selected => selected.optionId,
      CancelledOutcome() => 'cancelled',
      _ => 'unknown',
    };
    state.permissionOutcomes.add(outcome);
    final file = await client.readTextFile(
      ReadTextFileRequest(
        sessionId: params.sessionId,
        path: '/virtual/project.txt',
        line: 1,
        limit: 20,
      ),
    );
    state.fileContents.add(file.content);
    await client.sessionUpdate(
      SessionNotification(
        sessionId: params.sessionId,
        update: AgentMessageChunkSessionUpdate(
          content: TextContentBlock(
            text: '$text:second:$outcome:${file.content}',
          ),
        ),
      ),
    );
    return PromptResponse(stopReason: StopReason.endTurn);
  }

  @override
  Future<void> cancel(CancelNotification params) async {
    state.sessionCancels += 1;
    final cancellation = sessionCancellation[params.sessionId];
    if (cancellation != null && !cancellation.isCompleted) {
      cancellation.complete();
    }
  }

  @override
  Future<void> cancelRequest(CancelRequestNotification params) async {
    state.requestCancels += 1;
    final cancellation = requestCancellation;
    if (cancellation != null && !cancellation.isCompleted) {
      cancellation.complete();
    }
  }
}

Future<_ToolProcess> _startTool(
  String script,
  Map<String, String> environment,
) async {
  final process = await Process.start(
    'bun',
    ['run', script],
    environment: {...Platform.environment, ...environment},
  );
  final lines = StreamIterator(
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
  );
  return _ToolProcess(
    process,
    lines,
    process.stderr.transform(utf8.decoder).join(),
  );
}

Map<String, dynamic> _map(dynamic value) =>
    Map<String, dynamic>.from(value as Map);

String _sessionId(dynamic response) => _map(response)['sessionId'] as String;

Future<void> _expectRequestError(
  Future<dynamic> request,
  int expectedCode,
) async {
  try {
    await request;
    fail('Expected request error $expectedCode');
  } on RequestError catch (error) {
    expect(error.code, expectedCode);
  }
}

Future<int> _malformedHttpProbe(String url) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers.contentType = ContentType.json;
    request.write('{malformed-json');
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, dynamic>> _httpJson(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    expect(response.statusCode, HttpStatus.ok, reason: body);
    return _map(jsonDecode(body));
  } finally {
    client.close(force: true);
  }
}

Future<void> _runDartClientRound(
  String endpoint,
  MemoryAcpCookieStore cookies, {
  required bool full,
}) async {
  final updates = <String, List<String>>{};
  var permissions = 0;
  var reads = 0;
  final app = client()
      .onRequest('session/request_permission', (params, _) {
        permissions += 1;
        final request = _map(params);
        final toolCall = _map(request['toolCall']);
        final id = toolCall['toolCallId'] as String;
        if (id.contains('cancel-permission')) {
          return {
            'outcome': {'outcome': 'cancelled'},
          };
        }
        final wanted = id.contains('reject-permission') ? 'reject' : 'allow';
        return {
          'outcome': {'outcome': 'selected', 'optionId': wanted},
        };
      })
      .onRequest('fs/read_text_file', (params, _) {
        reads += 1;
        expect(_map(params)['path'], '/virtual/project.txt');
        return {'content': 'dart-client-file'};
      })
      .onNotification('session/update', (params, _) {
        final notification = _map(params);
        final update = _map(notification['update']);
        if (update['sessionUpdate'] == 'agent_message_chunk') {
          final content = _map(update['content']);
          (updates[notification['sessionId'] as String] ??= []).add(
            content['text'] as String,
          );
        }
      });
  final stream = createHttpStream(
    endpoint,
    options: HttpStreamOptions(
      headers: const {'X-Interop-Token': 'dart-client'},
      cookieStore: cookies,
    ),
  );
  final context = app.connect(stream);
  await context.ready;
  try {
    final initialized = _map(
      await context.request(
        'initialize',
        params: {
          'protocolVersion': acpProtocolVersion,
          'clientCapabilities': {
            'fs': {'readTextFile': true, 'writeTextFile': false},
          },
        },
      ),
    );
    expect(initialized['protocolVersion'], acpProtocolVersion);

    if (!full) {
      final sessionId = _sessionId(
        await context.request(
          'session/new',
          params: {'cwd': '/interop/reconnect', 'mcpServers': []},
        ),
      );
      final result = _map(
        await context.request(
          'session/prompt',
          params: {
            'sessionId': sessionId,
            'prompt': [
              {'type': 'text', 'text': 'reconnect'},
            ],
          },
        ),
      );
      expect(result['stopReason'], 'end_turn');
      expect(permissions, 1);
      expect(reads, 1);
      return;
    }

    await _expectRequestError(
      context.request('interop/missing', params: {}),
      -32601,
    );
    await _expectRequestError(
      context.request(
        'session/prompt',
        params: {
          'sessionId': 'missing-session',
          'prompt': [
            {'type': 'text', 'text': 'invalid'},
          ],
        },
      ),
      -32002,
    );

    const labels = [
      'allow-permission',
      'reject-permission',
      'cancel-permission',
    ];
    final sessionIds = await Future.wait(
      labels.map(
        (label) async => _sessionId(
          await context.request(
            'session/new',
            params: {'cwd': '/interop/$label', 'mcpServers': []},
          ),
        ),
      ),
    );
    final prompts = await Future.wait(
      List.generate(labels.length, (index) async {
        return _map(
          await context.request(
            'session/prompt',
            params: {
              'sessionId': sessionIds[index],
              'prompt': [
                {'type': 'text', 'text': labels[index]},
              ],
            },
          ),
        );
      }),
    );
    expect(
      prompts.map((result) => result['stopReason']),
      everyElement('end_turn'),
    );
    for (var index = 0; index < labels.length; index += 1) {
      final values = updates[sessionIds[index]];
      expect(values, hasLength(2));
      expect(values!.first, '${labels[index]}:first');
      expect(values.last, startsWith('${labels[index]}:second:'));
    }
    expect(permissions, labels.length);
    expect(reads, labels.length);

    final sessionCancelId = _sessionId(
      await context.request(
        'session/new',
        params: {'cwd': '/interop/session-cancel', 'mcpServers': []},
      ),
    );
    final sessionPrompt = context.request(
      'session/prompt',
      params: {
        'sessionId': sessionCancelId,
        'prompt': [
          {'type': 'text', 'text': 'cancel-with-session'},
        ],
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await context.notify('session/cancel', {'sessionId': sessionCancelId});
    expect(_map(await sessionPrompt)['stopReason'], 'cancelled');

    final requestCancelId = _sessionId(
      await context.request(
        'session/new',
        params: {'cwd': '/interop/request-cancel', 'mcpServers': []},
      ),
    );
    final cancellation = Completer<void>();
    final requestPrompt = context.request(
      'session/prompt',
      params: {
        'sessionId': requestCancelId,
        'prompt': [
          {'type': 'text', 'text': 'cancel-with-request'},
        ],
      },
      cancellation: cancellation.future,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    cancellation.complete();
    expect(_map(await requestPrompt)['stopReason'], 'cancelled');
  } finally {
    context.close();
    await stream.writable.close();
  }
  await expectLater(
    context.request('initialize', params: {}),
    throwsStateError,
  );
}

void main() {
  final sdkRoot = Platform.environment['ACP_TYPESCRIPT_SDK_DIR'];
  final skipReason = sdkRoot == null || sdkRoot.isEmpty
      ? 'Set ACP_TYPESCRIPT_SDK_DIR to a local TypeScript SDK v1.5.0 clone'
      : false;

  test(
    'Dart client interoperates with official TypeScript HTTP/SSE server under stress',
    () async {
      final server = await _startTool('tool/typescript_v15_http_server.ts', {
        'ACP_TYPESCRIPT_SDK_DIR': sdkRoot!,
      });
      addTearDown(server.stop);
      expect(
        await server.lines.moveNext().timeout(const Duration(seconds: 10)),
        isTrue,
      );
      final ready = _map(jsonDecode(server.lines.current));
      final endpoint = ready['url'] as String;
      expect(await _malformedHttpProbe(endpoint), HttpStatus.badRequest);

      final cookies = MemoryAcpCookieStore();
      await _runDartClientRound(endpoint, cookies, full: true);
      await _runDartClientRound(endpoint, cookies, full: false);

      final metrics = await _httpJson(
        endpoint.replaceFirst('/acp', '/metrics'),
      );
      expect(metrics['initialize'], 2);
      expect(metrics['prompt'], 7);
      expect(metrics['permission'], 4);
      expect(metrics['fileRead'], 4);
      expect(metrics['sessionCancel'], 1);
      expect(metrics['requestCancel'], 1);
      expect(
        metrics['permissionOutcomes'],
        containsAll(['allow', 'reject', 'cancelled']),
      );
      expect(metrics['authenticated'], greaterThan(0));
      expect(metrics['connectionHeader'], greaterThan(0));
      expect(metrics['sessionHeader'], greaterThan(0));
      expect(metrics['cookie'], greaterThan(0));
    },
    skip: skipReason,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  for (final transport in ['http', 'websocket']) {
    test(
      'official TypeScript client interoperates with Dart $transport server under stress',
      () async {
        final state = _DartStressState();
        final server = await AcpHttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
          agentFactory: (connection) => _DartStressAgent(connection, state),
        );
        addTearDown(server.close);
        final scheme = transport == 'http' ? 'http' : 'ws';
        final endpoint =
            '$scheme://${server.address.address}:${server.port}/acp';
        final clientProcess =
            await _startTool('tool/typescript_v15_transport_client.ts', {
              'ACP_TYPESCRIPT_SDK_DIR': sdkRoot!,
              'ACP_INTEROP_URL': endpoint,
              'ACP_INTEROP_TRANSPORT': transport,
            });
        addTearDown(clientProcess.stop);

        late final int exitCode;
        try {
          exitCode = await clientProcess.process.exitCode.timeout(
            const Duration(seconds: 45),
          );
        } on TimeoutException {
          clientProcess.process.kill(ProcessSignal.sigterm);
          rethrow;
        }
        final stderr = await clientProcess.stderr;
        expect(exitCode, 0, reason: stderr);
        expect(await clientProcess.lines.moveNext(), isTrue, reason: stderr);
        final summary = _map(jsonDecode(clientProcess.lines.current));
        expect(summary['rounds'], 2);
        expect(summary['prompts'], 4);
        expect(summary['updates'], 8);
        expect(summary['permissions'], 4);
        expect(summary['fileReads'], 4);
        expect(summary['methodNotFoundCode'], -32601);
        expect(summary['resourceNotFoundCode'], -32002);
        expect(summary['sessionCancelStopReason'], 'cancelled');
        expect(summary['requestCancelStopReason'], 'cancelled');
        if (transport == 'http') {
          expect(summary['malformedStatus'], HttpStatus.badRequest);
          expect(summary['observedConnectionHeaders'], greaterThan(0));
          expect(summary['observedSessionHeaders'], greaterThan(0));
          expect(summary['observedCustomHeaders'], greaterThan(0));
        } else {
          expect(summary['malformedWebSocketRecovered'], isTrue);
        }
        expect(state.connections, transport == 'http' ? 2 : 3);
        expect(state.initializes, transport == 'http' ? 2 : 3);
        expect(state.prompts, 7);
        expect(state.sessionCancels, 1);
        expect(state.requestCancels, 1);
        expect(
          state.permissionOutcomes,
          containsAll(['allow', 'reject', 'cancelled']),
        );
        expect(state.fileContents, everyElement('typescript-client-file'));
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  }
}
