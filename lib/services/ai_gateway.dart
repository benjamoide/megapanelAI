import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiGatewayException implements Exception {
  final String message;
  const AiGatewayException(this.message);
  @override
  String toString() => message;
}

class AiGateway {
  static final endpoint = Uri.parse(
    'https://megapanel-private-ai.megapanel-private-ai.workers.dev/v1/guide',
  );
  final http.Client client;
  AiGateway(this.client);

  Future<String> ask(String query, String token) async {
    query = query.trim();
    if (query.isEmpty || query.length > 500) {
      throw const AiGatewayException(
          'Escribe una consulta de 1 a 500 caracteres.');
    }
    if (token.isEmpty) {
      throw const AiGatewayException('Inicia sesion para consultar la IA.');
    }
    http.Response response;
    try {
      // Never retry automatically: each request can consume the daily quota.
      response = await client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode({'query': query}),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const AiGatewayException(
          'La consulta ha tardado demasiado. Intentalo mas tarde.');
    } on http.ClientException {
      throw const AiGatewayException('No se pudo conectar con el servidor.');
    }
    switch (response.statusCode) {
      case 200:
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['answer'] is String) {
            final answer = (data['answer'] as String).trim();
            if (answer.isNotEmpty && answer.length <= 12000) return answer;
          }
        } on FormatException {
          // Do not display untrusted raw server responses.
        }
        throw const AiGatewayException(
            'El servidor devolvio una respuesta no valida.');
      case 401:
        throw const AiGatewayException(
            'Tu sesion no es valida. Cierra el acceso IA y vuelve a entrar.');
      case 403:
        throw const AiGatewayException(
            'Acceso denegado. Comprueba el correo verificado y el UID autorizado.');
      case 429:
        throw const AiGatewayException('Limite diario de consultas alcanzado.');
      default:
        throw const AiGatewayException(
            'IA no disponible temporalmente. Intentalo mas tarde.');
    }
  }
}
