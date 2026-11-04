import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../servicos/notificacoes.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import 'login.dart' show erroDeAutenticacao;

/// Exclusão da conta dentro do app (exigência do Google Play para apps
/// que permitem criar conta).
class ExcluirContaTela extends StatefulWidget {
  final Usuario usuario;
  const ExcluirContaTela({super.key, required this.usuario});
  @override
  State<ExcluirContaTela> createState() => _ExcluirContaTelaState();
}

class _ExcluirContaTelaState extends State<ExcluirContaTela> {
  final _senha = TextEditingController();
  bool _ocultar = true;
  bool _excluindo = false;

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  Future<void> _excluir() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    if (_senha.text.isEmpty) {
      mostrarAviso(context, 'Digite sua senha para confirmar.', erro: true);
      return;
    }
    final ok = await confirmar(context,
        titulo: 'Excluir conta definitivamente',
        mensagem: 'Seu perfil e seu acesso serão apagados e não poderão ser '
            'recuperados. Deseja continuar?',
        textoConfirmar: 'Excluir');
    if (!ok || !mounted) return;

    setState(() => _excluindo = true);
    try {
      // O Firebase exige um login recente para apagar a conta.
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: _senha.text),
      );
      await Notificacoes.desativar();
      await Repo.excluirPerfil(user.uid);
      await user.delete();
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      mostrarAviso(context, 'Sua conta foi excluída.');
    } catch (e) {
      if (mounted) mostrarAviso(context, erroDeAutenticacao(e), erro: true);
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Excluir minha conta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Cores.vermelho.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O que será apagado',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('• Seu acesso ao app (e-mail ${u.email})'),
                const Text('• Seu perfil: nome, turma e matrícula'),
                const Text('• O recebimento de notificações neste celular'),
                if (u.ehProfessor) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Horários, provas e avisos que você publicou continuam '
                    'visíveis para as turmas. Peça à gestão para removê-los, '
                    'se necessário.',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _senha,
            obscureText: _ocultar,
            decoration: InputDecoration(
              labelText: 'Sua senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _ocultar ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(_ocultar
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _ocultar = !_ocultar),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Cores.vermelho),
            onPressed: _excluindo ? null : _excluir,
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(_excluindo ? 'Excluindo...' : 'Excluir minha conta'),
          ),
        ],
      ),
    );
  }
}
