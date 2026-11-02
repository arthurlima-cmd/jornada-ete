import 'package:flutter/material.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../tema.dart';
import '../widgets/comuns.dart';

/// Cadastro das turmas. Todos os seletores de turma do app leem esta lista.
/// O botão "Carregar turmas da escola" cadastra de uma vez as turmas oficiais
/// (integrado e subsequente) e remove os nomes antigos 1º/2º/3º TDG.
class TurmasTela extends StatefulWidget {
  const TurmasTela({super.key});
  @override
  State<TurmasTela> createState() => _TurmasTelaState();
}

class _TurmasTelaState extends State<TurmasTela> {
  late final Stream<List<Turma>> _turmas = Repo.turmas();
  final _nome = TextEditingController();
  String _modalidade = modalidadeIntegrado;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _carregarPadrao() async {
    final ok = await confirmar(context,
        titulo: 'Carregar turmas da escola',
        mensagem: 'Cadastrar as ${turmasDaEscola.length} turmas oficiais '
            '(integrado e subsequente) e remover os nomes antigos '
            '1º, 2º e 3º TDG? Turmas extras que você criou continuam na lista.',
        textoConfirmar: 'Carregar');
    if (!ok) return;
    setState(() => _salvando = true);
    try {
      final n = await Repo.carregarTurmasDaEscola();
      if (mounted) mostrarAviso(context, '$n turmas cadastradas.');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
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
      await Repo.adicionarTurma(nome, ordem, _modalidade);
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

  Widget _cartao(Turma t) {
    final sub = t.modalidade == modalidadeSubsequente;
    return Card(
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
          child: Icon(
            sub ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined,
            color: Cores.azul,
          ),
        ),
        title: Text(t.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub ? '5 aulas por noite' : '9 aulas por dia'),
        trailing: IconButton(
          tooltip: 'Excluir turma',
          icon: const Icon(Icons.delete_outline, color: Cores.vermelho),
          onPressed: () => _excluir(t),
        ),
      ),
    );
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
          final integrado =
              turmas.where((t) => t.modalidade != modalidadeSubsequente).toList();
          final subsequente =
              turmas.where((t) => t.modalidade == modalidadeSubsequente).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: _salvando ? null : _carregarPadrao,
                icon: const Icon(Icons.playlist_add),
                label: const Text('Carregar turmas da escola'),
              ),
              const SizedBox(height: 20),
              const Text('Adicionar outra turma',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: modalidadeIntegrado,
                    label: Text('Integrado'),
                    icon: Icon(Icons.wb_sunny_outlined),
                  ),
                  ButtonSegment(
                    value: modalidadeSubsequente,
                    label: Text('Subsequente'),
                    icon: Icon(Icons.nights_stay_outlined),
                  ),
                ],
                selected: {_modalidade},
                onSelectionChanged: (s) => setState(() => _modalidade = s.first),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nome,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Nome da turma',
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
              if (turmas.isEmpty)
                const EstadoVazio(
                  icone: Icons.groups_outlined,
                  mensagem: 'Nenhuma turma cadastrada.',
                  detalhe: 'Toque em "Carregar turmas da escola". Enquanto a '
                      'lista estiver vazia, o app usa as turmas oficiais.',
                ),
              if (integrado.isNotEmpty) ...[
                TituloSecao('Integrado · ${integrado.length} turmas'),
                for (final t in integrado) _cartao(t),
              ],
              if (subsequente.isNotEmpty) ...[
                TituloSecao('Subsequente · ${subsequente.length} turmas'),
                for (final t in subsequente) _cartao(t),
              ],
            ],
          );
        },
      ),
    );
  }
}
