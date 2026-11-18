// Gera capturas de tela (PNG) das principais telas do Jornada ETEADC
// usando dados de demonstração (sem Firebase). Usado só no branch "capturas".
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jornada_ete/constantes.dart';
import 'package:jornada_ete/dados/modelos.dart';
import 'package:jornada_ete/dados/repositorio.dart';
import 'package:jornada_ete/tema.dart';
import 'package:jornada_ete/telas/agenda.dart';
import 'package:jornada_ete/telas/conectar.dart';
import 'package:jornada_ete/telas/contatos.dart';
import 'package:jornada_ete/telas/info_escola.dart';
import 'package:jornada_ete/telas/inicio_shell.dart';
import 'package:jornada_ete/telas/login.dart';
import 'package:jornada_ete/telas/splash.dart';

const _tamanho = Size(412, 892);
final _chave = GlobalKey();

const aluno = Usuario(
  uid: 'demo-aluno',
  nome: 'Maria Clara',
  email: 'aluna@exemplo.com',
  tipo: 'estudante',
  turma: '2º TDG A',
  matricula: '2026001',
  solicitouProfessor: false,
);

const professor = Usuario(
  uid: 'demo-prof',
  nome: 'Arthur Lima',
  email: 'professor@exemplo.com',
  tipo: 'professor',
  turma: '',
  matricula: '',
  solicitouProfessor: false,
);

Future<void> _carregarFontes() async {
  final pasta = Platform.environment['FONTES_MATERIAL'] ?? '';
  final roboto = FontLoader('Roboto');
  for (final f in Directory(pasta).listSync()) {
    final nome = f.path.split('/').last;
    if (nome.startsWith('Roboto') && nome.endsWith('.ttf')) {
      roboto.addFont(Future.value(ByteData.view(File(f.path).readAsBytesSync().buffer)));
    }
  }
  await roboto.load();
  final icones = FontLoader('MaterialIcons');
  icones.addFont(Future.value(
      ByteData.view(File('$pasta/MaterialIcons-Regular.otf').readAsBytesSync().buffer)));
  await icones.load();
}

void _dadosDemo() {
  Repo.demo = true;
  Repo.demoRegistros = (jsonDecode(File('assets/dados/horario_2026.json').readAsStringSync())
          as List)
      .cast<Map<String, dynamic>>();
  final hoje = DateUtils.dateOnly(DateTime.now());
  Repo.demoProvas = [
    Prova(
        id: 'p1',
        disciplina: 'Computação Gráfica',
        tipo: 'Prova',
        turma: aluno.turma,
        conteudo: 'Camadas, seleções e ajustes de cor',
        data: hoje.add(const Duration(days: 2)),
        professor: null,
        professorNome: 'Arthur Lima'),
    Prova(
        id: 'p2',
        disciplina: 'Matemática',
        tipo: 'Trabalho',
        turma: aluno.turma,
        conteudo: 'Lista de exercícios: funções',
        data: hoje.add(const Duration(days: 5)),
        professor: null,
        professorNome: 'Professor(a)'),
    Prova(
        id: 'p3',
        disciplina: 'Língua Portuguesa',
        tipo: 'Seminário',
        turma: aluno.turma,
        conteudo: 'Apresentação em grupo',
        data: hoje.add(const Duration(days: 9)),
        professor: null,
        professorNome: 'Professor(a)'),
  ];
  final agora = DateTime.now();
  Repo.demoAvisos = [
    Aviso(
        id: 'a1',
        titulo: 'Bem-vindos ao Jornada ETEADC!',
        mensagem: 'Agora horários, provas, avisos e a agenda da escola estão no seu celular.',
        tipo: 'Aviso',
        turma: 'Todas as turmas',
        data: null,
        criadoEm: agora.subtract(const Duration(hours: 2)),
        autor: null,
        autorNome: 'Gestão ETE'),
    Aviso(
        id: 'a2',
        titulo: 'Entrega do Moodboard',
        mensagem: 'Tragam o moodboard impresso para a aula de Artes.',
        tipo: 'Atividade',
        turma: aluno.turma,
        data: DateUtils.dateOnly(agora).add(const Duration(days: 3)),
        criadoEm: agora.subtract(const Duration(days: 1)),
        autor: null,
        autorNome: 'Arthur Lima'),
  ];
  final ano = agora.year;
  Repo.demoEventos = [
    for (final (i, e) in eventosAnuais.indexed)
      EventoAgenda(
          id: 'e$i',
          titulo: e.titulo,
          descricao: e.descricao,
          data: DateTime(ano, e.mes, e.dia),
          horaInicio: e.inicio,
          horaFim: e.fim,
          local: e.local,
          categoria: e.categoria),
  ];
}

Widget _app(Widget tela) => RepaintBoundary(
      key: _chave,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaJornada(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: tela,
      ),
    );

Future<void> _preparar(WidgetTester tester) async {
  tester.view.physicalSize = _tamanho * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _imagens(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final el in find.byType(Image).evaluate()) {
      final w = el.widget as Image;
      try {
        await precacheImage(w.image, el);
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> capturar(WidgetTester tester, String nome) async {
  await tester.pump(const Duration(milliseconds: 500));
  await _imagens(tester);
  await tester.pump(const Duration(milliseconds: 500));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_chave));
  final bytes = await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 3);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('capturas/$nome.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('captura: $nome.png');
}

Future<void> _rolarAteFim(WidgetTester tester) async {
  final rolavel = find.byType(Scrollable).first;
  await tester.drag(rolavel, const Offset(0, -3000));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await _carregarFontes();
    _dadosDemo();
  });

  testWidgets('splash', (tester) async {
    await _preparar(tester);
    await tester.pumpWidget(_app(const SplashTela()));
    await _imagens(tester);
    await tester.pump(const Duration(milliseconds: 2600));
    await capturar(tester, '01_splash');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('conectar', (tester) async {
    await _preparar(tester);
    await tester.pumpWidget(_app(const ConectarTela()));
    await capturar(tester, '02_conectar');
  });

  testWidgets('login', (tester) async {
    await _preparar(tester);
    await tester.pumpWidget(_app(const LoginTela(perfil: 'estudante')));
    await capturar(tester, '03_login_estudante');
    await tester.pumpWidget(_app(const LoginTela(perfil: 'professor')));
    await capturar(tester, '04_login_professor');
  });

  testWidgets('abas do estudante', (tester) async {
    await _preparar(tester);
    await tester.pumpWidget(_app(const InicioShell(usuario: aluno)));
    await capturar(tester, '05_inicio_estudante');
    final abas = {'Horários': '06_horarios', 'Provas': '07_provas', 'Avisos': '08_avisos', 'Perfil': '09_perfil'};
    for (final a in abas.entries) {
      await tester.tap(find.text(a.key).last);
      await tester.pump(const Duration(milliseconds: 600));
      await capturar(tester, a.value);
    }
    await _rolarAteFim(tester);
    await capturar(tester, '10_perfil_fim');
  });

  testWidgets('professor', (tester) async {
    await _preparar(tester);
    await tester.pumpWidget(_app(const InicioShell(usuario: professor)));
    await capturar(tester, '11_inicio_professor');
    await tester.tap(find.text('Horários').last);
    await tester.pump(const Duration(milliseconds: 600));
    await capturar(tester, '12_horarios_professor');
    await tester.tap(find.text('Perfil').last);
    await tester.pump(const Duration(milliseconds: 600));
    await capturar(tester, '13_perfil_professor');
  });

  testWidgets('agenda', (tester) async {
    await _preparar(tester);
    await tester.pumpWidget(_app(const AgendaTela(usuario: aluno)));
    await capturar(tester, '14_agenda');
  });

  testWidgets('contatos', (tester) async {
    await _preparar(tester);
    await tester.pumpWidget(_app(const ContatosTela()));
    await capturar(tester, '15_contatos');
    await _rolarAteFim(tester);
    await capturar(tester, '16_contatos_creditos');
  });

  testWidgets('informacoes', (tester) async {
    await _preparar(tester);
    await tester.pumpWidget(_app(const InfoEscolaTela()));
    await capturar(tester, '17_info_escola');
    await _rolarAteFim(tester);
    await capturar(tester, '18_info_escola_fim');
  });
}
