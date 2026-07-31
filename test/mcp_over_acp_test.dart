import 'dart:async';
import 'dart:convert';

import 'package:acp_dart/acp_dart.dart';
// Converters are internal to the package and not exported from the library.
import 'package:acp_dart/src/mcp_server_converter.dart';
import 'package:test/test.dart';

class _McpClient implements Client {
  final bool handle;
  final Object? reply;
  _McpClient({this.handle = true, this.reply});

  ConnectMcpRequest? connectedWith;
  MessageMcpRequest? messagedWith;
  MessageMcpNotification? notifiedWith;
  DisconnectMcpRequest? disconnectedWith;

  @override
  Future<ConnectMcpResponse>? connectMcp(ConnectMcpRequest params) {
    if (!handle) return null;
    connectedWith = params;
    return Future.value(ConnectMcpResponse(connectionId: 'conn-1'));
  }

  @override
  Future<Object?>? messageMcp(MessageMcpRequest params) {
    if (!handle) return null;
    messagedWith = params;
    return Future.value(reply);
  }

  @override
  Future<void>? notifyMcp(MessageMcpNotification params) {
    notifiedWith = params;
    return Future.value();
  }

  @override
  Future<DisconnectMcpResponse>? disconnectMcp(DisconnectMcpRequest params) {
    if (!handle) return null;
    disconnectedWith = params;
    return Future.value(DisconnectMcpResponse());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _McpAgent implements Agent {
  MessageMcpRequest? messagedWith;
  MessageMcpNotification? notifiedWith;

  @override
  Future<Object?>? messageMcp(MessageMcpRequest params) {
    messagedWith = params;
    return Future.value({'echo': params.method});
  }

  @override
  Future<void>? notifyMcp(MessageMcpNotification params) {
    notifiedWith = params;
    return Future.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late StreamController<Map<String, dynamic>> readable;
  late StreamController<Map<String, dynamic>> writable;
  late AcpStream stream;

  setUp(() {
    readable = StreamController<Map<String, dynamic>>();
    writable = StreamController<Map<String, dynamic>>.broadcast();
    stream = AcpStream(readable: readable.stream, writable: writable.sink);
  });

  tearDown(() {
    unawaited(readable.close());
    unawaited(writable.close());
  });

  Future<Map<String, dynamic>> callClient(
    Client client,
    String method,
    Map<String, dynamic> params,
  ) async {
    ClientSideConnection((_) => client, stream);
    final reply = writable.stream.first;
    readable.add({
      'jsonrpc': '2.0',
      'id': 1,
      'method': method,
      'params': params,
    });
    return jsonDecode(jsonEncode(await reply)) as Map<String, dynamic>;
  }

  group('mcp/connect and mcp/disconnect', () {
    test('connect returns a connection id', () async {
      final client = _McpClient();
      final reply = await callClient(client, 'mcp/connect', {
        'serverId': 'srv-1',
      });

      expect(reply['error'], isNull);
      expect(reply['result']['connectionId'], equals('conn-1'));
      expect(client.connectedWith?.serverId, equals('srv-1'));
    });

    test('disconnect carries the connection id', () async {
      final client = _McpClient();
      final reply = await callClient(client, 'mcp/disconnect', {
        'connectionId': 'conn-1',
      });

      expect(reply['error'], isNull);
      expect(client.disconnectedWith?.connectionId, equals('conn-1'));
    });

    test('a client without MCP support reports method not found', () async {
      final reply = await callClient(
        _McpClient(handle: false),
        'mcp/connect',
        {'serverId': 'srv-1'},
      );

      expect(reply['error']['code'], equals(-32601));
    });
  });

  group('mcp/message passthrough', () {
    test('the tunnelled reply is returned untouched', () async {
      // The MCP result is arbitrary JSON — it must not be coerced into a
      // model or reshaped on the way back out.
      final mcpResult = {
        'tools': [
          {
            'name': 'search',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'q': {'type': 'string'},
              },
            },
          },
        ],
        'nextCursor': null,
      };

      final reply = await callClient(
        _McpClient(reply: mcpResult),
        'mcp/message',
        {
          'connectionId': 'conn-1',
          'method': 'tools/list',
          'params': {'cursor': 'abc'},
        },
      );

      expect(reply['result'], equals(mcpResult));
    });

    test('a non-map tunnelled reply survives too', () async {
      final reply = await callClient(_McpClient(reply: [1, 2, 3]), 'mcp/message', {
        'connectionId': 'conn-1',
        'method': 'x',
      });

      expect(reply['result'], equals([1, 2, 3]));
    });

    test('params and method reach the client verbatim', () async {
      final client = _McpClient(reply: <String, dynamic>{});
      await callClient(client, 'mcp/message', {
        'connectionId': 'conn-9',
        'method': 'resources/read',
        'params': {'uri': 'file:///x'},
      });

      expect(client.messagedWith?.connectionId, equals('conn-9'));
      expect(client.messagedWith?.method, equals('resources/read'));
      expect(client.messagedWith?.params, equals({'uri': 'file:///x'}));
    });

    test('mcp/message with no id is handled as a notification', () async {
      final client = _McpClient();
      ClientSideConnection((_) => client, stream);

      readable.add({
        'jsonrpc': '2.0',
        'method': 'mcp/message',
        'params': {
          'connectionId': 'conn-1',
          'method': 'notifications/progress',
          'params': {'progress': 0.5},
        },
      });
      await Future<void>.delayed(Duration.zero);

      expect(client.notifiedWith?.method, equals('notifications/progress'));
      // A notification must not produce a reply.
      expect(client.messagedWith, isNull);
    });
  });

  group('mcp/message is bidirectional', () {
    test('it also travels client-to-agent', () async {
      // mcp/message sits on both method tables, so the agent must handle it.
      final agent = _McpAgent();
      AgentSideConnection((_) => agent, stream);

      final reply = writable.stream.first;
      readable.add({
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'mcp/message',
        'params': {'connectionId': 'c', 'method': 'ping'},
      });

      final wire = jsonDecode(jsonEncode(await reply)) as Map<String, dynamic>;
      expect(wire['result'], equals({'echo': 'ping'}));
      expect(agent.messagedWith?.method, equals('ping'));
    });

    test('it is registered on both method tables', () {
      expect(agentMethods['mcpMessage'], equals('mcp/message'));
      expect(clientMethods['mcpMessage'], equals('mcp/message'));
      expect(clientMethods['mcpConnect'], equals('mcp/connect'));
      expect(clientMethods['mcpDisconnect'], equals('mcp/disconnect'));
    });
  });

  group('MCP schema', () {
    test('the acp server variant round-trips through the union', () {
      const converter = McpServerConverter();
      final server = AcpMcpServer(name: 'shared', serverId: 'srv-7');

      final encoded =
          jsonDecode(jsonEncode(converter.toJson(server)))
              as Map<String, dynamic>;
      final decoded = converter.fromJson(encoded);

      expect(decoded, isA<AcpMcpServer>());
      expect((decoded as AcpMcpServer).serverId, equals('srv-7'));
      expect(decoded.name, equals('shared'));
    });

    test('requests round-trip', () {
      expect(
        ConnectMcpRequest.fromJson(
          ConnectMcpRequest(serverId: 's').toJson(),
        ).serverId,
        equals('s'),
      );
      expect(
        DisconnectMcpRequest.fromJson(
          DisconnectMcpRequest(connectionId: 'c').toJson(),
        ).connectionId,
        equals('c'),
      );
      expect(
        ConnectMcpResponse.fromJson(
          ConnectMcpResponse(connectionId: 'c').toJson(),
        ).connectionId,
        equals('c'),
      );
    });

    test('omitted params stay null rather than becoming an empty map', () {
      final decoded = MessageMcpRequest.fromJson({
        'connectionId': 'c',
        'method': 'ping',
      });

      expect(decoded.params, isNull);
      expect(decoded.toJson().containsKey('params'), isFalse);
    });
  });
}
