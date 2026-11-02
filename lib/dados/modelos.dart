import 'package:cloud_firestore/cloud_firestore.dart';

import '../constantes.dart';

String _txt(dynamic v) => v is String ? v : (v == null ? '' : v.toString());
DateTime? _data(dynamic v) => v is Timestamp ? v.toDate() : null;
DocumentReference? _ref(dynamic v) => v is DocumentReference ? v : null;

/// Documento da coleção `usuarios` (ID = uid do Firebase Auth).
class Usuario {
  final String uid;
  final String nome;
  final String email;
  final String tipo; // "estudante" ou "professor"
  final String turma;
  final String matricula;
  final bool solicitouProfessor;

  const Usuario({
    required this.uid,
    required this.nome,
    required this.email,
    required this.tipo,
    required this.turma,
    required this.matricula,
    required this.solicitouProfessor,
  });

  bool get ehProfessor => tipo == 'professor';

  DocumentReference<Map<String, dynamic>> get ref =>
      FirebaseFirestore.instance.collection('usuarios').doc(uid);

  String get primeiroNome {
    final n = nome.trim();
    return n.isEmpty ? 'tudo bem' : n.split(' ').first;
  }

  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    final letras = partes.take(2).map((p) => p[0].toUpperCase()).join();
    return letras;
  }

  factory Usuario.doDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return Usuario(
      uid: d.id,
      nome: _txt(m['display_name']),
      email: _txt(m['email']),
      tipo: _txt(m['tipo']).isEmpty ? 'estudante' : _txt(m['tipo']),
      turma: _txt(m['turma']),
      matricula: _txt(m['matricula']),
      solicitouProfessor: m['solicitou_professor'] == true,
    );
  }
}

/// Documento da coleção `horarios` (uma aula de uma turma num dia).
class Horario {
  final String id;
  final String disciplina; // campo `aulas` (compatível com o FlutterFlow)
  final String conteudo;
  final String horario;
  final String diaSemana;
  final String turma;
  final DocumentReference? professor;
  final String professorNome;

  const Horario({
    required this.id,
    required this.disciplina,
    required this.conteudo,
    required this.horario,
    required this.diaSemana,
    required this.turma,
    required this.professor,
    required this.professorNome,
  });

  factory Horario.doDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return Horario(
      id: d.id,
      disciplina: _txt(m['aulas']),
      conteudo: _txt(m['conteudo']),
      horario: _txt(m['horario']),
      diaSemana: _txt(m['dia_semana']),
      turma: _txt(m['turma']),
      professor: _ref(m['professor']),
      professorNome: _txt(m['professor_nome']),
    );
  }

  bool ehDe(String uid) => professor?.id == uid;
}

/// Documento da coleção `provas`.
class Prova {
  final String id;
  final String disciplina;
  final String tipo;
  final String turma;
  final String conteudo;
  final DateTime? data;
  final DocumentReference? professor;
  final String professorNome;

  const Prova({
    required this.id,
    required this.disciplina,
    required this.tipo,
    required this.turma,
    required this.conteudo,
    required this.data,
    required this.professor,
    required this.professorNome,
  });

  factory Prova.doDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return Prova(
      id: d.id,
      disciplina: _txt(m['disciplina']),
      tipo: _txt(m['tipo']).isEmpty ? 'Prova' : _txt(m['tipo']),
      turma: _txt(m['turma']),
      conteudo: _txt(m['conteudo']),
      data: _data(m['data']),
      professor: _ref(m['professor']),
      professorNome: _txt(m['professor_nome']),
    );
  }

  bool ehDe(String uid) => professor?.id == uid;
}

/// Documento da coleção `avisos` (avisos, eventos e atividades).
class Aviso {
  final String id;
  final String titulo;
  final String mensagem;
  final String tipo;
  final String turma; // "Todas as turmas" ou o nome da turma
  final DateTime? data; // data do evento/atividade (opcional)
  final DateTime? criadoEm;
  final DocumentReference? autor;
  final String autorNome;

  const Aviso({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.turma,
    required this.data,
    required this.criadoEm,
    required this.autor,
    required this.autorNome,
  });

  factory Aviso.doDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return Aviso(
      id: d.id,
      titulo: _txt(m['titulo']),
      mensagem: _txt(m['mensagem']),
      tipo: _txt(m['tipo']).isEmpty ? 'Aviso' : _txt(m['tipo']),
      turma: _txt(m['turma']),
      data: _data(m['data']),
      criadoEm: _data(m['criado_em']),
      autor: _ref(m['autor']),
      autorNome: _txt(m['autor_nome']),
    );
  }

  bool ehDe(String uid) => autor?.id == uid;
}

/// Documento da coleção `cardapio`.
class ItemCardapio {
  final String id;
  final String diaSemana;
  final String refeicao;
  final String itens;

  const ItemCardapio({
    required this.id,
    required this.diaSemana,
    required this.refeicao,
    required this.itens,
  });

  factory ItemCardapio.doDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return ItemCardapio(
      id: d.id,
      diaSemana: _txt(m['dia_semana']),
      refeicao: _txt(m['refeicao']),
      itens: _txt(m['itens']),
    );
  }
}

/// Documento da coleção `turmas`.
class Turma {
  final String id;
  final String nome;
  final int ordem;
  final String modalidade; // "integrado" ou "subsequente"

  const Turma({
    required this.id,
    required this.nome,
    required this.ordem,
    required this.modalidade,
  });

  factory Turma.doDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    final o = m['ordem'];
    final nome = _txt(m['nome']);
    final mod = _txt(m['modalidade']);
    return Turma(
      id: d.id,
      nome: nome,
      ordem: o is num ? o.toInt() : 0,
      modalidade: mod.isEmpty ? modalidadePeloNome(nome) : mod,
    );
  }
}
