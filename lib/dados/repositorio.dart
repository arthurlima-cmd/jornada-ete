import 'package:cloud_firestore/cloud_firestore.dart';

import '../constantes.dart';
import 'modelos.dart';

/// Erro com mensagem pronta para mostrar ao usuário.
class ErroApp implements Exception {
  final String mensagem;
  const ErroApp(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Todo o acesso ao Firestore fica aqui.
///
/// As consultas usam só filtros de igualdade e ordenam no próprio app,
/// por isso nenhuma precisa de índice composto.
class Repo {
  Repo._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> _col(String nome) =>
      _db.collection(nome);

  // ------------------------------------------------------------- usuários
  static Stream<Usuario?> usuario(String uid) => _col('usuarios')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? Usuario.doDoc(d) : null);

  static Future<void> criarUsuario({
    required String uid,
    required String email,
    required String nome,
    required String turma,
    required String matricula,
    required bool solicitouProfessor,
  }) {
    return _col('usuarios').doc(uid).set({
      'uid': uid,
      'email': email,
      'display_name': nome,
      // Todo cadastro nasce como estudante. A gestão promove professores
      // alterando este campo no console do Firebase.
      'tipo': 'estudante',
      'turma': turma,
      'matricula': matricula,
      'solicitou_professor': solicitouProfessor,
      'created_time': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> atualizarPerfil(
    String uid, {
    required String nome,
    required String matricula,
    String? turma,
  }) {
    final dados = <String, dynamic>{
      'display_name': nome,
      'matricula': matricula,
    };
    if (turma != null) dados['turma'] = turma;
    return _col('usuarios').doc(uid).update(dados);
  }

  /// Apaga o perfil do usuário (a conta de login é apagada em seguida).
  static Future<void> excluirPerfil(String uid) =>
      _col('usuarios').doc(uid).delete();

  // --------------------------------------------------------------- turmas
  /// Modalidade de cada turma (atualizado sempre que a lista é lida).
  static final Map<String, String> _modalidades = {};

  /// "integrado" ou "subsequente" para o nome da turma.
  static String modalidadeDaTurma(String nome) =>
      _modalidades[nome] ?? modalidadePeloNome(nome);

  /// As aulas do dia da turma: 9 no integrado, 5 (noite) no subsequente.
  static List<String> aulasDaTurma(String nome) =>
      aulasDaModalidade(modalidadeDaTurma(nome));

  static Stream<List<Turma>> turmas() => _col('turmas').snapshots().map((s) {
        final lista = s.docs.map(Turma.doDoc).where((t) => t.nome.isNotEmpty).toList();
        lista.sort((a, b) {
          final c = a.ordem.compareTo(b.ordem);
          return c != 0 ? c : a.nome.compareTo(b.nome);
        });
        for (final t in lista) {
          _modalidades[t.nome] = t.modalidade;
        }
        return lista;
      });

  static Future<void> adicionarTurma(String nome, int ordem, String modalidade) =>
      _col('turmas').doc(slug(nome)).set({
        'nome': nome,
        'ordem': ordem,
        'modalidade': modalidade,
      });

  static Future<void> excluirTurma(String id) => _col('turmas').doc(id).delete();

  /// Cadastra/atualiza as turmas oficiais (constantes.turmasDaEscola) na ordem
  /// da lista e remove os nomes antigos renomeados (1º/2º/3º TDG -> STDG).
  /// Turmas extras cadastradas à mão são mantidas.
  static Future<int> carregarTurmasDaEscola() async {
    final batch = _db.batch();
    var ordem = 1;
    for (final t in turmasDaEscola) {
      batch.set(_col('turmas').doc(slug(t.nome)), {
        'nome': t.nome,
        'ordem': ordem++,
        'modalidade': t.modalidade,
      });
    }
    final atuais = await _col('turmas').get();
    for (final d in atuais.docs) {
      final nome = Turma.doDoc(d).nome;
      if (turmasRenomeadas.containsKey(nome)) batch.delete(d.reference);
    }
    await batch.commit();
    return turmasDaEscola.length;
  }

  // ------------------------------------------------------------- horários
  /// Ordena pela hora ("07:40" < "19:10"), para misturar integrado e
  /// subsequente na lista do professor sem bagunçar a ordem.
  static List<Horario> _ordenarHorarios(QuerySnapshot<Map<String, dynamic>> s) {
    final lista = s.docs.map(Horario.doDoc).toList();
    lista.sort((a, b) {
      final c = horaDaAula(a.horario).compareTo(horaDaAula(b.horario));
      return c != 0 ? c : a.horario.compareTo(b.horario);
    });
    return lista;
  }

  static Stream<List<Horario>> horariosDaTurma(String turma, String dia) =>
      _col('horarios')
          .where('turma', isEqualTo: turma)
          .where('dia_semana', isEqualTo: dia)
          .snapshots()
          .map(_ordenarHorarios);

  /// Aulas do professor no dia: as que ele cadastrou e as do horário oficial
  /// em que o nome dele aparece (ex.: "Ana Nayara" para "Ana Nayara Silva").
  static Stream<List<Horario>> horariosDoProfessor(Usuario prof, String dia) =>
      _col('horarios')
          .where('dia_semana', isEqualTo: dia)
          .snapshots()
          .map((s) => _ordenarHorarios(s)
              .where((h) =>
                  h.ehDe(prof.uid) ||
                  (prof.nome.isNotEmpty && nomeCombina(h.professorNome, prof.nome)))
              .toList());

  /// Um documento por turma + dia + aula: impossível duplicar a mesma aula.
  static String idHorario(String turma, String dia, String horario) =>
      '${slug(turma)}_${dia}_${numeroDaAula(horario)}';

  static bool _mesmoProfessor(String a, String b) =>
      a.isNotEmpty &&
      b.isNotEmpty &&
      (semAcento(a) == semAcento(b) || nomeCombina(a, b) || nomeCombina(b, a));

  static Future<void> salvarHorario({
    required Usuario professor,
    required String turma,
    required String dia,
    required String horario,
    required String disciplina,
    required String conteudo,
    String? professorNome,
  }) async {
    final id = idHorario(turma, dia, horario);
    final ref = _col('horarios').doc(id);
    final nomeProf = (professorNome ?? '').trim().isEmpty
        ? professor.nome
        : professorNome!.trim();

    // 1) A aula já pertence a outro usuário?
    final atual = await ref.get();
    if (atual.exists) {
      final h = Horario.doDoc(atual);
      if (!h.ehDe(professor.uid)) {
        throw ErroApp(
            'Esta aula foi cadastrada por outra pessoa (${h.professorNome.isEmpty ? 'outro professor' : h.professorNome}).');
      }
    }

    // 2) O(a) professor(a) da aula já está em outra turma neste horário?
    final mesmoHorario = await _col('horarios')
        .where('dia_semana', isEqualTo: dia)
        .where('horario', isEqualTo: horario)
        .get();
    for (final d in mesmoHorario.docs) {
      if (d.id == id) continue;
      final outra = Horario.doDoc(d);
      if (_mesmoProfessor(outra.professorNome, nomeProf)) {
        throw ErroApp(
            '$nomeProf já tem aula na turma ${outra.turma} neste horário.');
      }
    }

    await ref.set({
      'aulas': disciplina,
      'conteudo': conteudo,
      'horario': horario,
      'dia_semana': dia,
      'turma': turma,
      'professor': professor.ref,
      'professor_nome': nomeProf,
      'atualizado_em': FieldValue.serverTimestamp(),
    });
  }

  /// Grava o HORÁRIO DE AULAS 2026 oficial (assets/dados/horario_2026.json).
  /// Quem importa fica como responsável pelas aulas (pode editar/excluir);
  /// o nome exibido é o do(a) professor(a) da grade oficial.
  /// Aulas já cadastradas por outra pessoa são mantidas.
  /// Retorna (gravadas, mantidas).
  static Future<(int, int)> importarHorarioOficial(
      Usuario responsavel, List<Map<String, dynamic>> registros) async {
    final existentes = await _col('horarios').get();
    final donoPorId = {
      for (final d in existentes.docs) d.id: Horario.doDoc(d),
    };

    var gravadas = 0;
    var mantidas = 0;
    var lote = _db.batch();
    var noLote = 0;

    for (final r in registros) {
      final turma = r['turma'] as String;
      final dia = r['dia'] as String;
      final n = (r['aula'] as num).toInt();
      final aulas = aulasDaTurma(turma);
      if (n < 1 || n > aulas.length) continue;
      final horario = aulas[n - 1];
      final id = idHorario(turma, dia, horario);

      final atual = donoPorId[id];
      if (atual != null && !atual.ehDe(responsavel.uid)) {
        mantidas++;
        continue;
      }
      lote.set(_col('horarios').doc(id), {
        'aulas': r['disciplina'] as String,
        'conteudo': '',
        'horario': horario,
        'dia_semana': dia,
        'turma': turma,
        'professor': responsavel.ref,
        'professor_nome': r['professor'] as String,
        'oficial': true,
        'atualizado_em': FieldValue.serverTimestamp(),
      });
      gravadas++;
      if (++noLote == 400) {
        await lote.commit();
        lote = _db.batch();
        noLote = 0;
      }
    }
    if (noLote > 0) await lote.commit();
    return (gravadas, mantidas);
  }

  static Future<void> excluirHorario(String id) =>
      _col('horarios').doc(id).delete();

  // --------------------------------------------------------------- provas
  static List<Prova> _ordenarProvas(QuerySnapshot<Map<String, dynamic>> s) {
    final lista = s.docs.map(Prova.doDoc).toList();
    lista.sort((a, b) {
      final da = a.data ?? DateTime(2100);
      final db = b.data ?? DateTime(2100);
      return da.compareTo(db);
    });
    return lista;
  }

  static Stream<List<Prova>> provasDaTurma(String turma) => _col('provas')
      .where('turma', isEqualTo: turma)
      .snapshots()
      .map(_ordenarProvas);

  static Stream<List<Prova>> provasDoProfessor(Usuario prof) => _col('provas')
      .where('professor', isEqualTo: prof.ref)
      .snapshots()
      .map(_ordenarProvas);

  static Future<void> salvarProva({
    String? id,
    required Usuario professor,
    required String turma,
    required String disciplina,
    required String tipo,
    required DateTime data,
    required String conteudo,
  }) {
    final ref = id == null ? _col('provas').doc() : _col('provas').doc(id);
    return ref.set({
      'disciplina': disciplina,
      'tipo': tipo,
      'turma': turma,
      'data': Timestamp.fromDate(data),
      'conteudo': conteudo,
      'professor': professor.ref,
      'professor_nome': professor.nome,
      'atualizado_em': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> excluirProva(String id) => _col('provas').doc(id).delete();

  // --------------------------------------------------------------- avisos
  static Stream<List<Aviso>> avisos() => _col('avisos')
      .orderBy('criado_em', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(Aviso.doDoc).toList());

  static Future<void> publicarAviso({
    required Usuario autor,
    required String titulo,
    required String mensagem,
    required String tipo,
    required String turma,
    DateTime? data,
  }) {
    return _col('avisos').add({
      'titulo': titulo,
      'mensagem': mensagem,
      'tipo': tipo,
      'turma': turma,
      'data': data == null ? null : Timestamp.fromDate(data),
      'autor': autor.ref,
      'autor_nome': autor.nome,
      'criado_em': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> excluirAviso(String id) => _col('avisos').doc(id).delete();

  // ------------------------------------------------------------- cardápio
  static Stream<List<ItemCardapio>> cardapio(String dia) => _col('cardapio')
          .where('dia_semana', isEqualTo: dia)
          .snapshots()
          .map((s) {
        final lista = s.docs.map(ItemCardapio.doDoc).toList();
        int pos(String r) {
          final i = refeicoes.indexOf(r);
          return i < 0 ? 99 : i;
        }

        lista.sort((a, b) => pos(a.refeicao).compareTo(pos(b.refeicao)));
        return lista;
      });

  static Future<void> salvarItemCardapio({
    required String dia,
    required String refeicao,
    required String itens,
  }) {
    return _col('cardapio').add({
      'dia_semana': dia,
      'refeicao': refeicao,
      'itens': itens,
      'atualizado_em': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> excluirItemCardapio(String id) =>
      _col('cardapio').doc(id).delete();
}
