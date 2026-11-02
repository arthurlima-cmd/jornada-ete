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

  // --------------------------------------------------------------- turmas
  static Stream<List<Turma>> turmas() => _col('turmas').snapshots().map((s) {
        final lista = s.docs.map(Turma.doDoc).where((t) => t.nome.isNotEmpty).toList();
        lista.sort((a, b) {
          final c = a.ordem.compareTo(b.ordem);
          return c != 0 ? c : a.nome.compareTo(b.nome);
        });
        return lista;
      });

  static Future<void> adicionarTurma(String nome, int ordem) =>
      _col('turmas').doc(slug(nome)).set({'nome': nome, 'ordem': ordem});

  static Future<void> excluirTurma(String id) => _col('turmas').doc(id).delete();

  // ------------------------------------------------------------- horários
  static List<Horario> _ordenarHorarios(QuerySnapshot<Map<String, dynamic>> s) {
    final lista = s.docs.map(Horario.doDoc).toList();
    lista.sort((a, b) => a.horario.compareTo(b.horario));
    return lista;
  }

  static Stream<List<Horario>> horariosDaTurma(String turma, String dia) =>
      _col('horarios')
          .where('turma', isEqualTo: turma)
          .where('dia_semana', isEqualTo: dia)
          .snapshots()
          .map(_ordenarHorarios);

  static Stream<List<Horario>> horariosDoProfessor(Usuario prof, String dia) =>
      _col('horarios')
          .where('professor', isEqualTo: prof.ref)
          .where('dia_semana', isEqualTo: dia)
          .snapshots()
          .map(_ordenarHorarios);

  /// Um documento por turma + dia + aula: impossível duplicar a mesma aula.
  static String idHorario(String turma, String dia, String horario) =>
      '${slug(turma)}_${dia}_${numeroDaAula(horario)}';

  static Future<void> salvarHorario({
    required Usuario professor,
    required String turma,
    required String dia,
    required String horario,
    required String disciplina,
    required String conteudo,
  }) async {
    final id = idHorario(turma, dia, horario);
    final ref = _col('horarios').doc(id);

    // 1) A aula já pertence a outro professor?
    final atual = await ref.get();
    if (atual.exists) {
      final h = Horario.doDoc(atual);
      if (!h.ehDe(professor.uid)) {
        throw ErroApp(
            'Esta aula já está ocupada por ${h.professorNome.isEmpty ? 'outro professor' : h.professorNome}.');
      }
    }

    // 2) O professor já dá aula em outra turma neste mesmo horário?
    final conflito = await _col('horarios')
        .where('professor', isEqualTo: professor.ref)
        .where('dia_semana', isEqualTo: dia)
        .where('horario', isEqualTo: horario)
        .get();
    for (final d in conflito.docs) {
      if (d.id != id) {
        final outra = Horario.doDoc(d);
        throw ErroApp(
            'Você já tem aula na turma ${outra.turma} neste horário.');
      }
    }

    await ref.set({
      'aulas': disciplina,
      'conteudo': conteudo,
      'horario': horario,
      'dia_semana': dia,
      'turma': turma,
      'professor': professor.ref,
      'professor_nome': professor.nome,
      'atualizado_em': FieldValue.serverTimestamp(),
    });
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
