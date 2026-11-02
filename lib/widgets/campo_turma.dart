import 'package:flutter/material.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import 'comuns.dart';

/// Lista de turmas vinda da coleção `turmas` (com lista padrão se vazia).
/// Todas as telas usam este mesmo widget, então o nome da turma é gravado
/// sempre igual — o erro "Option 1" do protótipo não acontece mais.
class CampoTurma extends StatefulWidget {
  final String? valor;
  final ValueChanged<String?>? onChanged;
  final bool incluirTodas;
  final String rotulo;
  final String? erro;

  const CampoTurma({
    super.key,
    required this.valor,
    required this.onChanged,
    this.incluirTodas = false,
    this.rotulo = 'Turma',
    this.erro,
  });

  @override
  State<CampoTurma> createState() => _CampoTurmaState();
}

class _CampoTurmaState extends State<CampoTurma> {
  late final Stream<List<Turma>> _turmas = Repo.turmas();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Turma>>(
      stream: _turmas,
      builder: (context, snap) {
        final nomes = <String>[];
        if (widget.incluirTodas) nomes.add(todasAsTurmas);
        final lista = snap.data ?? const <Turma>[];
        if (lista.isEmpty) {
          nomes.addAll(turmasPadrao);
        } else {
          nomes.addAll(lista.map((t) => t.nome));
        }
        // Mantém o valor atual visível mesmo que a turma tenha sido renomeada.
        final v = widget.valor;
        if (v != null && v.isNotEmpty && !nomes.contains(v)) {
          nomes.add(v);
        }
        return CampoSelecao(
          rotulo: widget.rotulo,
          valor: v,
          opcoes: nomes,
          onChanged: widget.onChanged,
          erro: widget.erro,
          icone: Icons.groups_outlined,
        );
      },
    );
  }
}
