import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constantes.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import 'cadastro_horarios.dart';
import 'cadastro_provas.dart';
import 'cardapio.dart';
import 'contatos.dart';
import 'info_escola.dart';
import 'publicar_aviso.dart';
import 'turmas.dart';

/// Menu principal com dados reais do usuário logado
/// (o protótipo mostrava "Olá Estudante!", "3 aulas restantes" etc. fixos).
class AbaInicio extends StatefulWidget {
  final Usuario usuario;
  final ValueChanged<int> irPara;
  const AbaInicio({super.key, required this.usuario, required this.irPara});
  @override
  State<AbaInicio> createState() => _AbaInicioState();
}

class _AbaInicioState extends State<AbaInicio> {
  final _memoAulas = MemoStream<List<Horario>>();
  final _memoProvas = MemoStream<List<Prova>>();

  void _abrir(Widget tela) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final hoje = diaDeHoje();
    final dataHoje = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Jornada ETE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _Saudacao(usuario: u, dataHoje: dataHoje),
          if (u.solicitouProfessor && !u.ehProfessor) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Cores.amarelo.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top, color: Cores.texto),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Seu acesso de professor está aguardando liberação da gestão.',
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ------------------------------------------------ aulas de hoje
          TituloSecao(
            u.ehProfessor ? 'Minhas aulas hoje' : 'Aulas de hoje',
            acao: TextButton(
              onPressed: () => widget.irPara(1),
              child: const Text('Ver semana'),
            ),
          ),
          if (!hojeEhDiaLetivo())
            const _CaixaInfo(
              icone: Icons.weekend_outlined,
              texto: 'Hoje não há aulas. Bom descanso!',
            )
          else if (!u.ehProfessor && u.turma.isEmpty)
            const _CaixaInfo(
              icone: Icons.info_outline,
              texto: 'Defina sua turma na aba Perfil para ver seus horários.',
            )
          else
            StreamBuilder<List<Horario>>(
              stream: _memoAulas.obter(
                '${u.ehProfessor}|${u.turma}|$hoje',
                () => u.ehProfessor
                    ? Repo.horariosDoProfessor(u, hoje)
                    : Repo.horariosDaTurma(u.turma, hoje),
              ),
              builder: (context, snap) {
                if (snap.hasError) return ErroCarregar(erro: snap.error);
                if (!snap.hasData) return const Carregando();
                final aulas = snap.data!;
                if (aulas.isEmpty) {
                  return const _CaixaInfo(
                    icone: Icons.event_available_outlined,
                    texto: 'Nenhuma aula cadastrada para hoje.',
                  );
                }
                return Column(
                  children: [
                    for (final a in aulas)
                      _LinhaAula(aula: a, mostrarTurma: u.ehProfessor),
                  ],
                );
              },
            ),

          // ------------------------------------------------ próximas provas
          if (!u.ehProfessor && u.turma.isNotEmpty) ...[
            TituloSecao(
              'Próximas provas',
              acao: TextButton(
                onPressed: () => widget.irPara(2),
                child: const Text('Ver todas'),
              ),
            ),
            StreamBuilder<List<Prova>>(
              stream: _memoProvas.obter(u.turma, () => Repo.provasDaTurma(u.turma)),
              builder: (context, snap) {
                if (snap.hasError) return ErroCarregar(erro: snap.error);
                if (!snap.hasData) return const Carregando();
                final inicioHoje = DateUtils.dateOnly(DateTime.now());
                final proximas = snap.data!
                    .where((p) => p.data != null && !p.data!.isBefore(inicioHoje))
                    .take(3)
                    .toList();
                if (proximas.isEmpty) {
                  return const _CaixaInfo(
                    icone: Icons.celebration_outlined,
                    texto: 'Nenhuma prova marcada.',
                  );
                }
                return Column(
                  children: [for (final p in proximas) _LinhaProva(prova: p)],
                );
              },
            ),
          ],

          // ------------------------------------------------ atalhos
          const TituloSecao('Acesso rápido'),
          GradeAtalhos(filhos: [
            CardAtalho(
              icone: Icons.restaurant_menu,
              titulo: 'Cardápio',
              cor: Cores.verde,
              onTap: () => _abrir(CardapioTela(usuario: u)),
            ),
            CardAtalho(
              icone: Icons.campaign_outlined,
              titulo: 'Avisos e eventos',
              cor: Cores.vermelho,
              onTap: () => widget.irPara(3),
            ),
            CardAtalho(
              icone: Icons.apartment_outlined,
              titulo: 'Minha ETE',
              onTap: () => _abrir(const InfoEscolaTela()),
            ),
            CardAtalho(
              icone: Icons.contact_phone_outlined,
              titulo: 'Contatos',
              cor: Cores.azulMedio,
              onTap: () => _abrir(const ContatosTela()),
            ),
          ]),

          // ------------------------------------------------ área do professor
          if (u.ehProfessor) ...[
            const TituloSecao('Área do professor'),
            GradeAtalhos(filhos: [
              CardAtalho(
                icone: Icons.edit_calendar_outlined,
                titulo: 'Cadastrar horários',
                onTap: () => _abrir(CadastroHorariosTela(professor: u)),
              ),
              CardAtalho(
                icone: Icons.post_add,
                titulo: 'Cadastrar provas',
                cor: Cores.azulMedio,
                onTap: () => _abrir(CadastroProvasTela(professor: u)),
              ),
              CardAtalho(
                icone: Icons.add_alert_outlined,
                titulo: 'Publicar aviso',
                cor: Cores.vermelho,
                onTap: () => _abrir(PublicarAvisoTela(autor: u)),
              ),
              CardAtalho(
                icone: Icons.groups_outlined,
                titulo: 'Turmas',
                cor: Cores.verde,
                onTap: () => _abrir(const TurmasTela()),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _Saudacao extends StatelessWidget {
  final Usuario usuario;
  final String dataHoje;
  const _Saudacao({required this.usuario, required this.dataHoje});

  @override
  Widget build(BuildContext context) {
    final papel = usuario.ehProfessor
        ? 'Professor(a)'
        : (usuario.turma.isEmpty ? 'Estudante' : 'Estudante · ${usuario.turma}');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Cores.azul, Cores.azulMedio],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              usuario.iniciais,
              style: const TextStyle(
                color: Cores.azul,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${usuario.primeiroNome}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(papel, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  dataHoje[0].toUpperCase() + dataHoje.substring(1),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaixaInfo extends StatelessWidget {
  final IconData icone;
  final String texto;
  const _CaixaInfo({required this.icone, required this.texto});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.borda),
      ),
      child: Row(
        children: [
          Icon(icone, color: Cores.textoSecundario),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _LinhaAula extends StatelessWidget {
  final Horario aula;
  final bool mostrarTurma;
  const _LinhaAula({required this.aula, required this.mostrarTurma});
  @override
  Widget build(BuildContext context) {
    final partes = aula.horario.split('·');
    final hora = partes.length > 1 ? partes[1].trim() : aula.horario;
    final detalhe = mostrarTurma ? aula.turma : aula.professorNome;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Cores.borda),
      ),
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Cores.azul,
          child: Text(
            numeroDaAula(aula.horario),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(aula.disciplina, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([hora, if (detalhe.isNotEmpty) detalhe].join(' · ')),
      ),
    );
  }
}

class _LinhaProva extends StatelessWidget {
  final Prova prova;
  const _LinhaProva({required this.prova});
  @override
  Widget build(BuildContext context) {
    final d = prova.data!;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Cores.borda),
      ),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(DateFormat('dd', 'pt_BR').format(d),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Cores.azul)),
            Text(DateFormat('MMM', 'pt_BR').format(d).toUpperCase(),
                style: const TextStyle(fontSize: 11, color: Cores.textoSecundario)),
          ],
        ),
        title: Text('${prova.tipo} · ${prova.disciplina}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: prova.conteudo.isEmpty ? null : Text(prova.conteudo, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
