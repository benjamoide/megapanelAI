import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mega_panel_ai/services/ai_gateway.dart';

void main() {
  test('sends only query and bearer token to the HTTPS Worker', () async {
    final gateway = AiGateway(MockClient((request) async {
      expect(request.url, AiGateway.endpoint);
      expect(request.url.scheme, 'https');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(jsonDecode(request.body), {'query': 'consulta'});
      return http.Response('{"answer":"Respuesta"}', 200);
    }));
    expect(await gateway.ask(' consulta ', 'test-token'), 'Respuesta');
  });

  test('invalid inputs never reach the network', () async {
    final gateway =
        AiGateway(MockClient((_) async => fail('Unexpected request')));
    for (final query in ['', '  ', 'a' * 501]) {
      await expectLater(
          gateway.ask(query, 'token'), throwsA(isA<AiGatewayException>()));
    }
    await expectLater(
        gateway.ask('consulta', ''), throwsA(isA<AiGatewayException>()));
  });

  for (final status in [401, 403, 429, 500, 503]) {
    test('HTTP $status is sanitized and never retried', () async {
      var calls = 0;
      final gateway = AiGateway(MockClient((_) async {
        calls++;
        return http.Response('sensitive provider detail', status);
      }));
      await expectLater(
          gateway.ask('consulta', 'token'),
          throwsA(isA<AiGatewayException>().having(
              (e) => e.message, 'message', isNot(contains('sensitive')))));
      expect(calls, 1);
    });
  }

  for (final body in [
    'invalid json',
    '{}',
    '{"answer":42}',
    '{"answer":" "}',
    '[]'
  ]) {
    test('rejects malformed answer $body', () async {
      final gateway =
          AiGateway(MockClient((_) async => http.Response(body, 200)));
      await expectLater(
          gateway.ask('consulta', 'token'), throwsA(isA<AiGatewayException>()));
    });
  }

  test('network errors do not expose request details', () async {
    final gateway = AiGateway(
        MockClient((_) async => throw http.ClientException('secret')));
    await expectLater(
        gateway.ask('consulta', 'token'),
        throwsA(isA<AiGatewayException>()
            .having((e) => e.message, 'message', isNot(contains('secret')))));
  });
}
