import 'package:flutter/material.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../tema.dart';
import '../widgets/comuns.dart';

/// Cadastro das turmas. Todos os seletores de turma do app leem esta lista,
/// então basta cadastrar as 12 turmas uma única vez.
class TurmasTela extends StatefulWidget {
  const TurmasTela({super.key});
  @override
  State<TurmasTela> createState() => _TurmasTelaState();
}

class _TurmasTelaState extends State<TurmasTela> {
  late final Stream<List<Turma>> _turmas = Repo.turmas();
  final _nome = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _adicionar(List<Turma> atuais) async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      mostrarAviso(context, 'Digite o nome da turma.', erro: true);
      return;
    }
    if (atuais.any((t) => t.nome.toLowerCase() == nome.toLowerCase())) {
      mostrarAviso(context, 'Esta turma já existe.', erro: true);
      return;
    }
    setState(() => _salvando = true);
    try {
      final ordem = atuais.isEmpty
          ? 1
          : atuais.map((t) => t.ordem).reduce((a, b) => a > b ? a : b) + 1;
      await Repo.adicionarTurma(nome, ordem);
      _nome.clear();
      if (mounted) mostrarAviso(context, 'Turma $nome adicionada.');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir(Turma t) async {
    final ok = await confirmar(context,
        titulo: 'Excluir turma',
        mensagem:
            'Excluir "${t.nome}" da lista? Horários e provas já cadastrados não são apagados.',
        textoConfirmar: 'Excluir');
    if (!ok) return;
    try {
      await Repo.excluirTurma(t.id);
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turmas')),
      body: StreamBuilder<List<Turma>>(
        stream: _turmas,
        builder: (context, snap) {
          if (snap.hasError) return ErroCarregar(erro: snap.error);
          if (!snap.hasData) return const Carregando();
          final turmas = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nome,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Nova turma',
                        hintText: 'Ex.: 1º TDG A',
                      ),
                      onSubmitted: (_) => _adicionar(turmas),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(56, 52)),
                      onPressed: _salvando ? null : () => _adicionar(turmas),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (turmas.isEmpty)
                EstadoVazio(
                  icone: Icons.groups_outlined,
                  mensagem: 'Nenhuma turma cadastrada.',
                  detalhe:
                      'Enquanto a lista estiver vazia, o app usa: ${turmasPadrao.join(', ')}.',
                ),
              for (final t in turmas)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Cores.borda),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Cores.azulClaro,
                      child: Text('${t.ordem}',
                          style: const TextStyle(color: Cores.azul, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(t.nome),
                    trailing: IconButton(
                      tooltip: 'Excluir turma',
                      icon: const Icon(Icons.delete_outline, color: Cores.vermelho),
                      onPressed: () => _excluir(t),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
