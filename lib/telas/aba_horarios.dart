import 'package:flutter/material.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../widgets/campo_turma.dart';
import '../widgets/comuns.dart';
import '../widgets/grade_dia.dart';
import 'cadastro_horarios.dart';

/// Quadro de horários (substitui horariosaulas, horariosubsequente,
/// Horariosgabriel e as cópias, que eram só caixas coloridas sem dados).
class AbaHorarios extends StatefulWidget {
  final Usuario usuario;
  const AbaHorarios({super.key, required this.usuario});
  @override
  State<AbaHorarios> createState() => _AbaHorariosState();
}

class _AbaHorariosState extends State<AbaHorarios> {
  late String? _turma =
      widget.usuario.turma.isNotEmpty ? widget.usuario.turma : null;
  String _dia = diaDeHoje();

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quadro de horários'),
        actions: [
          if (u.ehProfessor)
            IconButton(
              tooltip: 'Cadastrar horários',
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CadastroHorariosTela(professor: u),
              )),
            ),
        ],
      ),
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
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              diasExtenso[_dia] ?? _dia,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          if (_turma == null)
            const EstadoVazio(
              icone: Icons.groups_outlined,
              mensagem: 'Escolha uma turma',
              detalhe: 'Selecione a turma acima para ver o quadro de horários.',
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InfoModalidade(turma: _turma!),
            ),
          if (_turma != null) GradeDoDia(turma: _turma!, dia: _dia),
        ],
      ),
    );
  }
}
