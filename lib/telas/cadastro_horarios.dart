import 'package:flutter/material.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../widgets/campo_turma.dart';
import '../widgets/comuns.dart';
import '../widgets/grade_dia.dart';

/// Cadastro de horários pelo professor, direto na grade das 9 aulas.
/// Corrige: DropDowns gravando "Option 1"/"1", textos fixos na lista,
/// ✏️ sem ação, falta de validação, duplicidade e conflito de horário.
class CadastroHorariosTela extends StatefulWidget {
  final Usuario professor;
  const CadastroHorariosTela({super.key, required this.professor});
  @override
  State<CadastroHorariosTela> createState() => _CadastroHorariosTelaState();
}

class _CadastroHorariosTelaState extends State<CadastroHorariosTela> {
  String? _turma;
  String _dia = diaDeHoje();

  Future<void> _editar(String horario, Horario? existente) async {
    final turma = _turma;
    if (turma == null) return;
    final salvo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FormAula(
        professor: widget.professor,
        turma: turma,
        dia: _dia,
        horario: horario,
        existente: existente,
      ),
    );
    if (salvo == true && mounted) mostrarAviso(context, 'Horário salvo!');
  }

  Future<void> _excluir(Horario h) async {
    final ok = await confirmar(context,
        titulo: 'Excluir aula',
        mensagem: 'Excluir ${h.disciplina} (${h.horario}) da turma ${h.turma}?',
        textoConfirmar: 'Excluir');
    if (!ok) return;
    try {
      await Repo.excluirHorario(h.id);
      if (mounted) mostrarAviso(context, 'Aula excluída.');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDeErro(e), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de horários')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CampoTurma(
            valor: _turma,
            onChanged: (v) => setState(() => _turma = v),
          ),
          const SizedBox(height: 12),
          SeletorDia(
            valor: _dia,
            dias: diasSemana,
            onChanged: (d) => setState(() => _dia = d),
          ),
          const SizedBox(height: 12),
          if (_turma == null)
            const EstadoVazio(
              icone: Icons.groups_outlined,
              mensagem: 'Escolha a turma',
              detalhe: 'Depois, toque numa aula livre para cadastrar.',
            )
          else ...[
            InfoModalidade(turma: _turma!),
            const SizedBox(height: 6),
            const Text(
              'Toque numa aula livre para cadastrar. Use ✏️ e 🗑️ nas suas aulas.',
            ),
            const SizedBox(height: 12),
            GradeDoDia(
              turma: _turma!,
              dia: _dia,
              professor: widget.professor,
              onEditar: _editar,
              onExcluir: _excluir,
            ),
          ],
        ],
      ),
    );
  }
}

class _FormAula extends StatefulWidget {
  final Usuario professor;
  final String turma;
  final String dia;
  final String horario;
  final Horario? existente;
  const _FormAula({
    required this.professor,
    required this.turma,
    required this.dia,
    required this.horario,
    required this.existente,
  });
  @override
  State<_FormAula> createState() => _FormAulaState();
}

class _FormAulaState extends State<_FormAula> {
  final _form = GlobalKey<FormState>();
  late final _disciplina =
      TextEditingController(text: widget.existente?.disciplina ?? '');
  late final _conteudo =
      TextEditingController(text: widget.existente?.conteudo ?? '');
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _disciplina.dispose();
    _conteudo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await Repo.salvarHorario(
        professor: widget.professor,
        turma: widget.turma,
        dia: widget.dia,
        horario: widget.horario,
        disciplina: _disciplina.text.trim(),
        conteudo: _conteudo.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + teclado),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existente == null ? 'Nova aula' : 'Editar aula',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('${widget.turma} · ${diasExtenso[widget.dia]} · ${widget.horario}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _disciplina,
              autofocus: widget.existente == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Disciplina'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Informe a disciplina.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _conteudo,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Conteúdo (opcional)'),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
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
