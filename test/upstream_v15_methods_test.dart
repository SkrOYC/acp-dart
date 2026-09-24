import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

// Source: typescript-sdk v1.5.0, src/schema/index.ts.
const _agentMethods = <String>{
  'initialize',
  'authenticate',
  'providers/list',
  'providers/set',
  'providers/disable',
  'session/new',
  'session/load',
  'session/set_mode',
  'session/set_config_option',
  'session/prompt',
  'session/cancel',
  'mcp/message',
  'session/list',
  'session/delete',
  'session/fork',
  'session/resume',
  'session/close',
  'logout',
  'nes/start',
  'nes/suggest',
  'nes/accept',
  'nes/reject',
  'nes/close',
  'document/didOpen',
  'document/didChange',
  'document/didClose',
  'document/didSave',
  'document/didFocus',
};

const _clientMethods = <String>{
  'session/request_permission',
  'session/update',
  'fs/write_text_file',
  'fs/read_text_file',
  'terminal/create',
  'terminal/output',
  'terminal/release',
  'terminal/wait_for_exit',
  'terminal/kill',
  'mcp/connect',
  'mcp/message',
  'mcp/disconnect',
  'elicitation/create',
  'elicitation/complete',
};

void main() {
  test('protocol version matches upstream v1.5.0', () {
    expect(acpProtocolVersion, 1);
  });

  test('agent method inventory covers upstream v1.5.0', () {
    expect(agentMethods.values.toSet(), containsAll(_agentMethods));
  });

  test('client method inventory covers upstream v1.5.0', () {
    expect(clientMethods.values.toSet(), containsAll(_clientMethods));
  });
}
