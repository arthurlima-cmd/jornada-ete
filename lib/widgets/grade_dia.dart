import 'package:flutter/material.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../tema.dart';
import 'comuns.dart';

/// Mostra as aulas de uma turma num dia (9 no integrado, 5 no subsequente),
/// inclusive as vagas.
/// Usada pelo aluno (somente leitura) e pelo professor (com edição).
class GradeDoDia extends StatefulWidget {
  final String turma;
  final String dia;

  /// Se informado, mostra os botões de cadastro/edição para este professor.
  final Usuario? professor;
  final void Function(String horario, Horario? existente)? onEditar;
  final void Function(Horario h)? onExcluir;

  const GradeDoDia({
    super.key,
    required this.turma,
    required this.dia,
    this.professor,
    this.onEditar,
    this.onExcluir,
  });

  @override
  State<GradeDoDia> createState() => _GradeDoDiaState();
}

class _GradeDoDiaState extends State<GradeDoDia> {
  final _memo = MemoStream<List<Horario>>();

  @override
  Widget build(BuildContext context) {
    final stream = _memo.obter('${widget.turma}|${widget.dia}',
        () => Repo.horariosDaTurma(widget.turma, widget.dia));

    return StreamBuilder<List<Horario>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return ErroCarregar(erro: snap.error);
        if (!snap.hasData) return const Carregando();

        // 9 aulas no integrado, 5 (noite) no subsequente.
        final aulas = Repo.aulasDaTurma(widget.turma);
        // Casa cada aula salva com a posição pelo NÚMERO da aula ("3ª aula"),
        // não pelo texto inteiro: assim, se o horário de uma aula mudar
        // (ex.: horários oficiais da noite), o que já foi cadastrado continua
        // aparecendo no lugar certo.
        final padrao = RegExp(r'^\d+ª aula');
        final numeros = {for (final a in aulas) numeroDaAula(a)};
        final porNumero = <String, Horario>{
          for (final h in snap.data!)
            if (padrao.hasMatch(h.horario)) numeroDaAula(h.horario): h,
        };
        final avulsas = snap.data!
            .where((h) =>
                !padrao.hasMatch(h.horario) ||
                !numeros.contains(numeroDaAula(h.horario)))
            .toList(); // registros antigos fora do padrão

        return Column(
          children: [
            for (final horario in aulas)
              _CartaoAula(
                horario: horario,
                aula: porNumero[numeroDaAula(horario)],
                professor: widget.professor,
                onEditar: widget.onEditar,
                onExcluir: widget.onExcluir,
              ),
            for (final h in avulsas)
              _CartaoAula(
                horario: h.horario.isEmpty ? 'Sem horário' : h.horario,
                aula: h,
                professor: widget.professor,
                onEditar: null,
                onExcluir: widget.onExcluir,
              ),
          ],
        );
      },
    );
  }
}

class _CartaoAula extends StatelessWidget {
  final String horario;
  final Horario? aula;
  final Usuario? professor;
  final void Function(String horario, Horario? existente)? onEditar;
  final void Function(Horario h)? onExcluir;

  const _CartaoAula({
    required this.horario,
    required this.aula,
    required this.professor,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final partes = horario.split('·');
    final rotuloAula = partes.first.trim();
    final hora = partes.length > 1 ? partes[1].trim() : '';
    final livre = aula == null;
    final minha = !livre && professor != null && aula!.ehDe(professor!.uid);
    final podeCriar = livre && professor != null && onEditar != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: livre ? Colors.white.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: podeCriar
              ? () => onEditar!(horario, null)
              : (minha && onEditar != null ? () => onEditar!(horario, aula) : null),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Cores.borda),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: livre ? Cores.fundo : Cores.azul,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        rotuloAula.replaceAll(' aula', ''),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: livre ? Cores.textoSecundario : Colors.white,
                        ),
                      ),
                      Text(
                        hora,
                        style: TextStyle(
                          fontSize: 12,
                          color: livre ? Cores.textoSecundario : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: livre
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            podeCriar ? 'Livre · toque para cadastrar' : 'Horário livre',
                            style: const TextStyle(color: Cores.textoSecundario),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              aula!.disciplina,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (aula!.professorNome.isNotEmpty)
                              Text(
                                'Prof. ${aula!.professorNome}',
                                style: const TextStyle(color: Cores.textoSecundario),
                              ),
                            if (aula!.conteudo.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  aula!.conteudo,
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                ),
                if (podeCriar)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.add_circle_outline, color: Cores.azulMedio),
                  ),
                if (minha && onEditar != null)
                  IconButton(
                    tooltip: 'Editar aula',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => onEditar!(horario, aula),
                  ),
                if (minha && onExcluir != null)
                  IconButton(
                    tooltip: 'Excluir aula',
                    icon: const Icon(Icons.delete_outline, color: Cores.vermelho),
                    onPressed: () => onExcluir!(aula!),
                  ),
                if (!livre && !minha && professor != null && onEditar != null)
                  const Tooltip(
                    message: 'Cadastrada por outro professor',
                    child: Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.lock_outline, color: Cores.textoSecundario),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Linha informativa: "Integrado · 9 aulas por dia" / "Subsequente · 5 aulas por noite".
class InfoModalidade extends StatelessWidget {
  final String turma;
  const InfoModalidade({super.key, required this.turma});

  @override
  Widget build(BuildContext context) {
    final mod = Repo.modalidadeDaTurma(turma);
    final sub = mod == modalidadeSubsequente;
    final qtd = aulasDaModalidade(mod).length;
    return Row(
      children: [
        Icon(sub ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined,
            size: 18, color: Cores.textoSecundario),
        const SizedBox(width: 6),
        Text(
          '${nomesModalidade[mod]} · $qtd aulas por ${sub ? 'noite' : 'dia'}',
          style: const TextStyle(color: Cores.textoSecundario),
        ),
      ],
    );
  }
}
