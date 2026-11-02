import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'servicos/notificacoes.dart';
import 'tema.dart';
import 'telas/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Ex.: versão iOS sem o GoogleService-Info.plist. Mostra o motivo em vez
    // de uma tela branca.
    runApp(_ErroConfiguracao(mensagem: e.toString()));
    return;
  }
  runApp(const JornadaEteApp());
}

class _ErroConfiguracao extends StatelessWidget {
  final String mensagem;
  const _ErroConfiguracao({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Não foi possível iniciar o Jornada ETE.\n\n$mensagem',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class JornadaEteApp extends StatelessWidget {
  const JornadaEteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jornada ETE',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: Notificacoes.mensageiro,
      theme: temaJornada(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashTela(),
    );
  }
}
