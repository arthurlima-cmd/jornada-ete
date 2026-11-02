import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constantes.dart';
import '../dados/modelos.dart';

/// Notificações de avisos, eventos e atividades (Firebase Cloud Messaging).
///
/// O celular se inscreve em "tópicos":
///   - todos            -> avisos para "Todas as turmas"
///   - turma_<turma>    -> avisos só da turma do estudante (ex.: turma_1TDGA)
/// A Cloud Function `notificarAviso` (pasta functions/) envia a notificação
/// para o tópico certo assim que um aviso é publicado.
class Notificacoes {
  Notificacoes._();

  static const topicoTodos = 'todos';
  static String topicoDaTurma(String turma) => 'turma_${slug(turma)}';

  /// Usado para mostrar o aviso quando o app está aberto.
  static final mensageiro = GlobalKey<ScaffoldMessengerState>();

  /// Muda de valor quando o usuário toca numa notificação (abre a aba Avisos).
  static final abrirAvisos = ValueNotifier<int>(0);

  static bool _ouvindo = false;
  static const _chaveTopico = 'topico_turma';

  /// Pede permissão e inscreve o celular nos tópicos do usuário.
  static Future<void> configurar(Usuario usuario) async {
    if (kIsWeb) return;
    try {
      final fm = FirebaseMessaging.instance;
      final permissao = await fm.requestPermission(alert: true, badge: true, sound: true);
      if (permissao.authorizationStatus == AuthorizationStatus.denied) return;

      await fm.subscribeToTopic(topicoTodos);

      final prefs = await SharedPreferences.getInstance();
      final anterior = prefs.getString(_chaveTopico);
      final atual = (!usuario.ehProfessor && usuario.turma.isNotEmpty)
          ? topicoDaTurma(usuario.turma)
          : null;
      if (anterior != null && anterior != atual) {
        await fm.unsubscribeFromTopic(anterior);
      }
      if (atual != null) {
        await fm.subscribeToTopic(atual);
        await prefs.setString(_chaveTopico, atual);
      } else {
        await prefs.remove(_chaveTopico);
      }

      if (!_ouvindo) {
        _ouvindo = true;
        FirebaseMessaging.onMessage.listen(_comAppAberto);
        FirebaseMessaging.onMessageOpenedApp.listen((_) => abrirAvisos.value++);
        final inicial = await fm.getInitialMessage();
        if (inicial != null) abrirAvisos.value++;
      }
    } catch (e) {
      // Ex.: iPhone sem as chaves de notificação da Apple configuradas.
      debugPrint('Notificações indisponíveis: $e');
    }
  }

  /// Ao sair da conta, o celular deixa de receber os avisos.
  static Future<void> desativar() async {
    if (kIsWeb) return;
    try {
      final fm = FirebaseMessaging.instance;
      await fm.unsubscribeFromTopic(topicoTodos);
      final prefs = await SharedPreferences.getInstance();
      final anterior = prefs.getString(_chaveTopico);
      if (anterior != null) await fm.unsubscribeFromTopic(anterior);
      await prefs.remove(_chaveTopico);
    } catch (e) {
      debugPrint('Erro ao desativar notificações: $e');
    }
  }

  /// Com o app aberto, o Android não mostra a notificação: mostramos um aviso.
  static void _comAppAberto(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    mensageiro.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          [n.title, n.body].whereType<String>().where((t) => t.isNotEmpty).join('\n'),
        ),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => abrirAvisos.value++,
        ),
      ),
    );
  }
}
