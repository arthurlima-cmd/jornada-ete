import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dados/repositorio.dart';
import '../widgets/campo_turma.dart';
import '../widgets/comuns.dart';

/// Para contas antigas (criadas no protótipo) que não têm perfil no Firestore.
class CompletarPerfilTela extends StatefulWidget {
  final User user;
  const CompletarPerfilTela({super.key, required this.user});
  @override
  State<CompletarPerfilTela> createState() => _CompletarPerfilTelaState();
}

class _CompletarPerfilTelaState extends State<CompletarPerfilTela> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.user.displayName ?? '');
  final _matricula = TextEditingController();
  String? _turma;
  String? _erroTurma;
  bool _professor = false;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _matricula.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final ok = _form.currentState!.validate();
    final turmaOk = _professor || (_turma?.isNotEmpty ?? false);
    setState(() => _erroTurma = turmaOk ? null : 'Selecione sua turma.');
    if (!ok || !turmaOk) return;
    setState(() => _salvando = true);
    try {
      await widget.user.updateDisplayName(_nome.text.trim());
      await Repo.criarUsuario(
        uid: widget.user.uid,
        email: widget.user.email ?? '',
        nome: _nome.text.trim(),
        turma: _professor ? '' : _turma!,
        matricula: _matricula.text.trim(),
        solicitouProfessor: _professor,
      );
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete seu perfil'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Olá! Precisamos de alguns dados para personalizar o app '
                    'para ${widget.user.email ?? 'você'}.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                    validator: (v) =>
                        (v ?? '').trim().length < 3 ? 'Informe seu nome.' : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sou professor(a)'),
                    subtitle: const Text('O acesso é liberado pela gestão.'),
                    value: _professor,
                    onChanged: (v) => setState(() => _professor = v),
                  ),
                  if (!_professor) ...[
                    CampoTurma(
                      valor: _turma,
                      erro: _erroTurma,
                      onChanged: (v) => setState(() {
                        _turma = v;
                        _erroTurma = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _matricula,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Matrícula (opcional)'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _salvando ? null : _salvar,
                    child: Text(_salvando ? 'Salvando...' : 'Continuar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
