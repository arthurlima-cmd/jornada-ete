import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../tema.dart';
import '../widgets/campo_turma.dart';
import '../widgets/comuns.dart';
import 'cadastro_provas.dart';

/// Calendário de provas da turma (substitui horarioprovaintegrado, que tinha
/// 39 campos editáveis que não gravavam nada).
class AbaProvas extends StatefulWidget {
  final Usuario usuario;
  const AbaProvas({super.key, required this.usuario});
  @override
  State<AbaProvas> createState() => _AbaProvasState();
}

class _AbaProvasState extends State<AbaProvas> {
  late String? _turma =
      widget.usuario.turma.isNotEmpty ? widget.usuario.turma : null;
  bool _anteriores = false;
  final _memo = MemoStream<List<Prova>>();

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Provas')),
      floatingActionButton: u.ehProfessor
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CadastroProvasTela(professor: u),
              )),
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar prova'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          CampoTurma(
            valor: _turma,
            onChanged: (v) => setState(() => _turma = v),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Próximas'), icon: Icon(Icons.event_outlined)),
              ButtonSegment(value: true, label: Text('Anteriores'), icon: Icon(Icons.history)),
            ],
            selected: {_anteriores},
            onSelectionChanged: (s) => setState(() => _anteriores = s.first),
          ),
          const SizedBox(height: 12),
          if (_turma == null)
            const EstadoVazio(
              icone: Icons.groups_outlined,
              mensagem: 'Escolha uma turma',
              detalhe: 'Selecione a turma para ver as provas.',
            )
          else
            StreamBuilder<List<Prova>>(
              stream: _memo.obter(_turma!, () => Repo.provasDaTurma(_turma!)),
              builder: (context, snap) {
                if (snap.hasError) return ErroCarregar(erro: snap.error);
                if (!snap.hasData) return const Carregando();
                final hoje = DateUtils.dateOnly(DateTime.now());
                var lista = snap.data!.where((p) {
                  if (p.data == null) return !_anteriores;
                  final passada = p.data!.isBefore(hoje);
                  return _anteriores ? passada : !passada;
                }).toList();
                if (_anteriores) lista = lista.reversed.toList();
                if (lista.isEmpty) {
                  return EstadoVazio(
                    icone: Icons.event_available_outlined,
                    mensagem: _anteriores
                        ? 'Nenhuma prova anterior.'
                        : 'Nenhuma prova marcada.',
                  );
                }
                return Column(
                  children: [for (final p in lista) CartaoProva(prova: p)],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Card de prova reutilizado na aba Provas e no cadastro do professor.
class CartaoProva extends StatelessWidget {
  final Prova prova;
  final VoidCallback? onEditar;
  final VoidCallback? onExcluir;
  final bool mostrarTurma;
  const CartaoProva({
    super.key,
    required this.prova,
    this.onEditar,
    this.onExcluir,
    this.mostrarTurma = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = prova.data;
    final hoje = DateUtils.dateOnly(DateTime.now());
    final ehHoje = d != null && DateUtils.isSameDay(d, hoje);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ehHoje ? Cores.amarelo : Cores.borda, width: ehHoje ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Cores.azulClaro,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    d == null ? '--' : DateFormat('dd', 'pt_BR').format(d),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Cores.azul),
                  ),
                  Text(
                    d == null ? '' : DateFormat('MMM', 'pt_BR').format(d).toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: Cores.textoSecundario),
                  ),
                  Text(
                    d == null ? '' : DateFormat('EEE', 'pt_BR').format(d),
                    style: const TextStyle(fontSize: 11, color: Cores.textoSecundario),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Cores.azul,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(prova.tipo,
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      if (ehHoje)
                        const Text('HOJE',
                            style: TextStyle(fontWeight: FontWeight.w800, color: Cores.vermelho)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(prova.disciplina,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (mostrarTurma)
                    Text('Turma ${prova.turma}',
                        style: const TextStyle(color: Cores.textoSecundario)),
                  if (prova.professorNome.isNotEmpty && !mostrarTurma)
                    Text('Prof. ${prova.professorNome}',
                        style: const TextStyle(color: Cores.textoSecundario)),
                  if (prova.conteudo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(prova.conteudo),
                    ),
                ],
              ),
            ),
            if (onEditar != null)
              IconButton(
                tooltip: 'Editar prova',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEditar,
              ),
            if (onExcluir != null)
              IconButton(
                tooltip: 'Excluir prova',
                icon: const Icon(Icons.delete_outline, color: Cores.vermelho),
                onPressed: onExcluir,
              ),
          ],
        ),
      ),
    );
  }
}
