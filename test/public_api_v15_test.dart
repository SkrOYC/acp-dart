import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

void main() {
  test('JSON-RPC and server API types are public', () {
    Future<dynamic> handleRequest(String method, dynamic params) async => null;
    Future<void> handleNotification(String method, dynamic params) async {}
    Future<dynamic> handleContextual(
      String method,
      dynamic params,
      RequestContext context,
    ) async => null;

    final error = ErrorResponse(code: -32602, message: 'Invalid params');
    RequestHandler request = handleRequest;
    NotificationHandler notification = handleNotification;
    RequestContextHandler contextual = handleContextual;
    AsyncDisposable? disposable;
    AcpAgentFactory? agentFactory;

    expect(error.toJson()['code'], -32602);
    expect(request, isA<Function>());
    expect(notification, isA<Function>());
    expect(contextual, isA<Function>());
    expect(disposable, isNull);
    expect(agentFactory, isNull);
  });
}
