import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../widgets/campo_turma.dart';
import '../widgets/comuns.dart';
import 'aba_provas.dart';

/// Lista das provas do professor com cadastro, edição e exclusão.
class CadastroProvasTela extends StatefulWidget {
  final Usuario professor;
  const CadastroProvasTela({super.key, required this.professor});
  @override
  State<CadastroProvasTela> createState() => _CadastroProvasTelaState();
}

class _CadastroProvasTelaState extends State<CadastroProvasTela> {
  late final Stream<List<Prova>> _provas = Repo.provasDoProfessor(widget.professor);

  Future<void> _abrirForm([Prova? existente]) async {
    final salvo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FormProva(professor: widget.professor, existente: existente),
    );
    if (salvo == true && mounted) mostrarAviso(context, 'Prova salva!');
  }

  Future<void> _excluir(Prova p) async {
    final ok = await confirmar(context,
        titulo: 'Excluir prova',
        mensagem: 'Excluir ${p.tipo.toLowerCase()} de ${p.disciplina} (${p.turma})?',
        textoConfirmar: 'Excluir');
    if (!ok) return;
    try {
      await Repo.excluirProva(p.id);
      if (mounted) mostrarAviso(context, 'Prova excluída.');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas provas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nova prova'),
      ),
      body: StreamBuilder<List<Prova>>(
        stream: _provas,
        builder: (context, snap) {
          if (snap.hasError) return ErroCarregar(erro: snap.error);
          if (!snap.hasData) return const Carregando();
          final lista = snap.data!;
          if (lista.isEmpty) {
            return const EstadoVazio(
              icone: Icons.assignment_outlined,
              mensagem: 'Você ainda não cadastrou provas.',
              detalhe: 'Toque em "Nova prova" para começar.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final p in lista)
                CartaoProva(
                  prova: p,
                  mostrarTurma: true,
                  onEditar: () => _abrirForm(p),
                  onExcluir: () => _excluir(p),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FormProva extends StatefulWidget {
  final Usuario professor;
  final Prova? existente;
  const _FormProva({required this.professor, required this.existente});
  @override
  State<_FormProva> createState() => _FormProvaState();
}

class _FormProvaState extends State<_FormProva> {
  final _form = GlobalKey<FormState>();
  late final _disciplina =
      TextEditingController(text: widget.existente?.disciplina ?? '');
  late final _conteudo =
      TextEditingController(text: widget.existente?.conteudo ?? '');
  late String? _turma = widget.existente?.turma;
  late String _tipo = widget.existente?.tipo ?? tiposDeProva.first;
  late DateTime? _data = widget.existente?.data;
  String? _erroTurma;
  String? _erroData;
  bool _salvando = false;

  @override
  void dispose() {
    _disciplina.dispose();
    _conteudo.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final primeiro = hoje.subtract(const Duration(days: 365));
    final ultimo = hoje.add(const Duration(days: 365 * 2));
    final atual = _data;
    final inicial = (atual != null && !atual.isBefore(primeiro) && !atual.isAfter(ultimo))
        ? atual
        : hoje;
    final d = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primeiro,
      lastDate: ultimo,
    );
    if (d != null) setState(() {
      _data = d;
      _erroData = null;
    });
  }

  Future<void> _salvar() async {
    final ok = _form.currentState!.validate();
    setState(() {
      _erroTurma = _turma == null ? 'Selecione a turma.' : null;
      _erroData = _data == null ? 'Escolha a data.' : null;
    });
    if (!ok || _turma == null || _data == null) return;
    setState(() => _salvando = true);
    try {
      await Repo.salvarProva(
        id: widget.existente?.id,
        professor: widget.professor,
        turma: _turma!,
        disciplina: _disciplina.text.trim(),
        tipo: _tipo,
        data: _data!,
        conteudo: _conteudo.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + teclado),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existente == null ? 'Nova prova' : 'Editar prova',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            CampoTurma(
              valor: _turma,
              erro: _erroTurma,
              onChanged: (v) => setState(() {
                _turma = v;
                _erroTurma = null;
              }),
            ),
            const SizedBox(height: 12),
            CampoSelecao(
              rotulo: 'Tipo',
              valor: _tipo,
              opcoes: tiposDeProva,
              icone: Icons.category_outlined,
              onChanged: (v) => setState(() => _tipo = v ?? _tipo),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _disciplina,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Disciplina',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Informe a disciplina.' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _escolherData,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data',
                  errorText: _erroData,
                  prefixIcon: const Icon(Icons.event_outlined),
                ),
                child: Text(_data == null
                    ? 'Toque para escolher'
                    : DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR').format(_data!)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _conteudo,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Conteúdo da prova (opcional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
