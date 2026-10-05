import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';
import '../services/ai_gateway.dart';

class SecureAiView extends StatefulWidget {
  final Future<FirebaseAuth> Function()? authFactory;
  final http.Client? client;
  const SecureAiView({super.key, this.authFactory, this.client});
  @override
  State<SecureAiView> createState() => _SecureAiViewState();
}

class _SecureAiViewState extends State<SecureAiView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _query = TextEditingController();
  late final http.Client _client;
  FirebaseAuth? _auth;
  bool _busy = true;
  String _message = '';
  String _answer = '';

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Keep AI credentials separate from the legacy Firestore profile session.
      final FirebaseAuth auth;
      if (widget.authFactory != null) {
        auth = await widget.authFactory!();
      } else {
        final app =
            Firebase.apps.where((app) => app.name == 'secure-ai').firstOrNull ??
                await Firebase.initializeApp(
                    name: 'secure-ai',
                    options: DefaultFirebaseOptions.currentPlatform);
        auth = FirebaseAuth.instanceFor(app: app);
      }
      await auth.signOut();
      await auth.setLanguageCode('es');
      if (mounted) setState(() => _auth = auth);
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'No se pudo iniciar el acceso IA. Vuelve a abrir esta pantalla.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _message = switch (e.code) {
              'too-many-requests' =>
                'Demasiados intentos. Espera antes de volver a probar.',
              'network-request-failed' => 'Comprueba tu conexion a Internet.',
              _ =>
                'No se pudo completar el acceso. Comprueba tu correo y contrasena de Firebase.',
            });
      }
    } on AiGatewayException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'No se pudo completar la operacion. Intentalo mas tarde.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ask() async {
    final auth = _auth!;
    await auth.currentUser?.reload();
    final user = auth.currentUser;
    if (user == null || !user.emailVerified) {
      throw const AiGatewayException(
          'Verifica tu correo antes de consultar la IA.');
    }
    final token = await user.getIdToken(true);
    final answer = await AiGateway(_client).ask(_query.text, token ?? '');
    if (mounted) setState(() => _answer = answer);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _query.dispose();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth?.currentUser;
    return ListView(children: [
      const Text('Buscador IA',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text(
          'Informacion general, no diagnosticos ni instrucciones para el panel. No incluyas datos personales: tu consulta se envia a Cloudflare y Google.'),
      const SizedBox(height: 16),
      if (_busy) const LinearProgressIndicator(),
      if (user == null) ...[
        const Text(
            'Acceso IA con la cuenta creada en Firebase Authentication. Es independiente de tu perfil habitual.'),
        TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Correo de Firebase')),
        TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration:
                const InputDecoration(labelText: 'Contrasena de Firebase')),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: _busy || _auth == null
                ? null
                : () => _run(() async {
                      try {
                        await _auth!.signInWithEmailAndPassword(
                            email: _email.text.trim(),
                            password: _password.text);
                      } finally {
                        _password.clear();
                      }
                    }),
            child: const Text('Acceder a IA')),
      ] else ...[
        Text('Cuenta IA: ${user.email ?? ""}'),
        TextButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await _auth!.signOut();
                      if (mounted) {
                        setState(() {
                          _answer = '';
                          _query.clear();
                        });
                      }
                    }),
            child: const Text('Cerrar acceso IA')),
        if (!user.emailVerified) ...[
          const Text(
              'Debes verificar tu correo. Revisa tambien la carpeta de spam.'),
          OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await user.sendEmailVerification();
                        if (mounted) {
                          setState(() => _message =
                              'Correo enviado. Abre el enlace y pulsa Ya he verificado.');
                        }
                      }),
              child: const Text('Enviar correo de verificacion')),
          OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await user.reload();
                        final refreshed = _auth!.currentUser;
                        if (refreshed?.emailVerified == true) {
                          await refreshed!.getIdToken(true);
                        }
                        if (mounted) {
                          setState(() => _message = refreshed?.emailVerified ==
                                  true
                              ? 'Correo verificado. Ya puedes consultar.'
                              : 'El correo sigue pendiente de verificacion.');
                        }
                      }),
              child: const Text('Ya he verificado')),
        ] else ...[
          TextField(
              controller: _query,
              enabled: !_busy,
              maxLength: 500,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Tu consulta')),
          FilledButton(
              onPressed: _busy ? null : () => _run(_ask),
              child: const Text('Consultar IA')),
        ],
      ],
      if (_message.isNotEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_message, semanticsLabel: _message)),
      if (_answer.isNotEmpty)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(_answer))),
    ]);
  }
}
