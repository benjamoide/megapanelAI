import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mega_panel_ai/views/secure_ai_view.dart';

class TestUser extends Fake implements User {
  bool verified = false;
  bool verificationSent = false;
  bool refreshedToken = false;
  @override
  String get email => 'test@example.com';
  @override
  bool get emailVerified => verified;
  @override
  Future<void> reload() async {}
  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {
    verificationSent = true;
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    refreshedToken = forceRefresh;
    return 'test-token';
  }
}

class TestCredential extends Fake implements UserCredential {}

class TestAuth extends Fake implements FirebaseAuth {
  final account = TestUser();
  User? signedIn;
  bool failLogin = false;
  @override
  User? get currentUser => signedIn;
  @override
  Future<void> signOut() async {
    signedIn = null;
  }

  @override
  Future<void> setLanguageCode(String? languageCode) async {}
  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    if (failLogin) throw FirebaseAuthException(code: 'invalid-credential');
    signedIn = account;
    return TestCredential();
  }
}

void main() {
  testWidgets('login, email verification, authenticated query and logout',
      (tester) async {
    final auth = TestAuth();
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response('{"answer":"Respuesta de prueba"}', 200);
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body:
                SecureAiView(authFactory: () async => auth, client: client))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'not-a-real-password');
    await tester.tap(find.text('Acceder a IA'));
    await tester.pumpAndSettle();
    expect(find.text('Consultar IA'), findsNothing);
    expect(calls, 0);
    await tester.tap(find.text('Enviar correo de verificacion'));
    await tester.pumpAndSettle();
    expect(auth.account.verificationSent, isTrue);
    await tester.tap(find.text('Ya he verificado'));
    await tester.pumpAndSettle();
    expect(find.text('Consultar IA'), findsNothing);
    auth.account.verified = true;
    await tester.tap(find.text('Ya he verificado'));
    await tester.pumpAndSettle();
    expect(auth.account.refreshedToken, isTrue);
    await tester.enterText(find.byType(TextField), 'Consulta de prueba');
    await tester.tap(find.text('Consultar IA'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Respuesta de prueba'), findsOneWidget);
    await tester.tap(find.text('Cerrar acceso IA'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
    expect(find.text('Respuesta de prueba'), findsNothing);
    expect(find.text('Acceder a IA'), findsOneWidget);
  });

  testWidgets('failed login clears password and keeps query unavailable',
      (tester) async {
    final auth = TestAuth()..failLogin = true;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SecureAiView(authFactory: () async => auth))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.text('Acceder a IA'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        isEmpty);
    expect(find.text('Consultar IA'), findsNothing);
    expect(find.textContaining('Comprueba tu correo'), findsOneWidget);
  });
}
