// Valores fixos usados em todo o app.

const String nomeEscola = 'ETE Antônio Dourado Cavalcanti';

/// Páginas públicas (GitHub Pages, pasta docs/ do repositório).
const String urlSite = 'https://arthurlima-cmd.github.io/jornada-ete';
const String urlPrivacidade = '$urlSite/privacidade.html';
const String urlExcluirConta = '$urlSite/excluir-conta.html';

/// Dias letivos, no mesmo formato gravado no campo `dia_semana`.
const List<String> diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'];

const Map<String, String> diasExtenso = {
  'Seg': 'Segunda-feira',
  'Ter': 'Terça-feira',
  'Qua': 'Quarta-feira',
  'Qui': 'Quinta-feira',
  'Sex': 'Sexta-feira',
};

// ---------------------------------------------------------------------------
// Modalidades e aulas
// ---------------------------------------------------------------------------

const String modalidadeIntegrado = 'integrado';
const String modalidadeSubsequente = 'subsequente';

const Map<String, String> nomesModalidade = {
  modalidadeIntegrado: 'Integrado',
  modalidadeSubsequente: 'Subsequente',
};

/// Integrado: 9 aulas por dia, de segunda a sexta (formato do campo `horario`).
/// Começam com o número da aula, então a ordem alfabética já é a ordem certa.
const List<String> aulasIntegrado = [
  '1ª aula · 07:40–08:30',
  '2ª aula · 08:30–09:20',
  '3ª aula · 09:40–10:30',
  '4ª aula · 10:30–11:20',
  '5ª aula · 11:20–12:10',
  '6ª aula · 13:00–13:50',
  '7ª aula · 13:50–14:40',
  '8ª aula · 15:00–15:50',
  '9ª aula · 15:50–16:40',
];

/// Subsequente: 5 aulas por noite, de segunda a sexta, conforme o
/// HORÁRIO DE AULAS 2026 – ETEADC: dois blocos presenciais (cada um com
/// 2 aulas) e uma aula EaD (terças e quintas).
const List<String> aulasSubsequente = [
  '1ª aula · 19:15–20:25',
  '2ª aula · 19:15–20:25',
  '3ª aula · 20:25–21:30',
  '4ª aula · 20:25–21:30',
  '5ª aula · EaD',
];

/// Pausas mostradas na grade, depois da aula de número indicado
/// (0 = antes da primeira aula).
const Map<String, Map<int, String>> intervalosDaModalidade = {
  modalidadeIntegrado: {
    2: 'Intervalo · 09:20–09:40',
    5: 'Almoço · 12:10–13:00',
    7: 'Intervalo · 14:40–15:00',
  },
  modalidadeSubsequente: {
    0: 'Lanche · 19:00–19:15',
  },
};

List<String> aulasDaModalidade(String modalidade) =>
    modalidade == modalidadeSubsequente ? aulasSubsequente : aulasIntegrado;

class TurmaPadrao {
  final String nome;
  final String modalidade;
  const TurmaPadrao(this.nome, this.modalidade);
}

/// Turmas oficiais da escola. Usadas enquanto a coleção `turmas` estiver
/// vazia e pelo botão "Carregar turmas da escola" (tela Turmas).
const List<TurmaPadrao> turmasDaEscola = [
  // Integrado — 9 aulas por dia
  TurmaPadrao('1º TDG A', modalidadeIntegrado),
  TurmaPadrao('1º TDG B', modalidadeIntegrado),
  TurmaPadrao('1º TDG C', modalidadeIntegrado),
  TurmaPadrao('2º TDG A', modalidadeIntegrado),
  TurmaPadrao('2º TDG B', modalidadeIntegrado),
  TurmaPadrao('3º TDG A', modalidadeIntegrado),
  TurmaPadrao('3º TDG B', modalidadeIntegrado),
  TurmaPadrao('1º TND A', modalidadeIntegrado),
  TurmaPadrao('1º TND B', modalidadeIntegrado),
  TurmaPadrao('2º TND', modalidadeIntegrado),
  TurmaPadrao('3º TND A', modalidadeIntegrado),
  TurmaPadrao('3º TND B', modalidadeIntegrado),
  // Subsequente — 5 aulas por noite
  TurmaPadrao('1º STND', modalidadeSubsequente),
  TurmaPadrao('2º STND', modalidadeSubsequente),
  TurmaPadrao('3º STND', modalidadeSubsequente),
  TurmaPadrao('1º STDG', modalidadeSubsequente),
  TurmaPadrao('2º STDG', modalidadeSubsequente),
  TurmaPadrao('3º STDG', modalidadeSubsequente),
];

List<String> get turmasPadrao => [for (final t in turmasDaEscola) t.nome];

/// Nomes antigos que foram renomeados (antigo -> novo).
const Map<String, String> turmasRenomeadas = {
  '1º TDG': '1º STDG',
  '2º TDG': '2º STDG',
  '3º TDG': '3º STDG',
};

/// Modalidade deduzida do nome, para turmas sem o campo `modalidade`:
/// nomes como "1º STDG" (com "S" logo após o ano) são do subsequente.
String modalidadePeloNome(String nomeTurma) {
  for (final t in turmasDaEscola) {
    if (t.nome == nomeTurma) return t.modalidade;
  }
  return RegExp(r'^\d+\s*[ºª°]?\s*S', caseSensitive: false).hasMatch(nomeTurma.trim())
      ? modalidadeSubsequente
      : modalidadeIntegrado;
}

const String todasAsTurmas = 'Todas as turmas';

const List<String> tiposDeProva = [
  'Prova',
  'Teste',
  'Trabalho',
  'Seminário',
  'Recuperação',
];

const List<String> tiposDeAviso = ['Aviso', 'Evento', 'Atividade'];

/// Categorias da Agenda (definem o ícone e as cores do cartão).
const Map<String, String> categoriasAgenda = {
  'festa': 'Festa / celebração',
  'musica': 'Música / carnaval',
  'solidariedade': 'Solidariedade',
  'homenagem': 'Homenagem',
  'familia': 'Família',
  'estudante': 'Estudantes',
  'esporte': 'Esporte',
  'academico': 'Acadêmico',
  'geral': 'Outro',
};

/// Evento anual de modelo (usado até a agenda ser salva no banco).
class EventoPadrao {
  final String titulo;
  final String descricao;
  final int mes;
  final int dia;
  final String inicio;
  final String fim;
  final String local;
  final String categoria;
  const EventoPadrao(this.titulo, this.descricao, this.mes, this.dia,
      this.inicio, this.fim, this.local, this.categoria);
}

/// Eventos anuais da escola (modelo enviado pela gestão).
const List<EventoPadrao> eventosAnuais = [
  EventoPadrao('Carnaval ETE', 'Muita música, alegria!', 2, 2, '08:00', '15:00', 'Pátio', 'musica'),
  EventoPadrao('Páscoa Solidária', 'Um momento de união!', 3, 15, '08:00', '15:00', 'Pátio', 'solidariedade'),
  EventoPadrao('Dia das mães', 'Homenagem especial!', 5, 10, '08:00', '15:00', 'Auditório', 'homenagem'),
  EventoPadrao('Junina ETE', 'Grande festa junina!', 6, 22, '08:00', '15:00', 'Refeitório', 'festa'),
  EventoPadrao('Dia dos pais', 'Homenagem especial!', 8, 9, '08:00', '15:00', 'Auditório', 'familia'),
  EventoPadrao('Dia do estudante', 'Nosso novo começo!', 8, 11, '08:00', '15:00', 'Quadra', 'estudante'),
  EventoPadrao('Interclasse', 'Tudo pela vitória!!', 9, 23, '08:00', '16:40', 'Quadra', 'esporte'),
];

const List<String> mesesAbrev = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];
const List<String> diasAbrev = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

/// Dia letivo de hoje ("Seg" ... "Sex"). Sábado e domingo retornam "Seg".
String diaDeHoje() {
  final w = DateTime.now().weekday; // 1 = segunda ... 7 = domingo
  if (w >= 1 && w <= 5) return diasSemana[w - 1];
  return 'Seg';
}

bool hojeEhDiaLetivo() => DateTime.now().weekday <= 5;

/// Remove acentos, espaços e símbolos para montar IDs de documento.
String slug(String texto) => texto.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

/// Hora "07:40–08:30" a partir do texto "1ª aula · 07:40–08:30" (para ordenar por hora).
String horaDaAula(String horario) {
  final partes = horario.split('·');
  return partes.length > 1 ? partes[1].trim() : horario;
}

/// Número da aula (1..9) a partir do texto "1ª aula · 07:40–08:30".
String numeroDaAula(String horario) =>
    horario.isEmpty ? '0' : horario.substring(0, 1);

/// Texto em maiúsculas e sem acentos, para comparar nomes.
String semAcento(String texto) {
  const de = 'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑáàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final c in texto.split('')) {
    final i = de.indexOf(c);
    b.write(i >= 0 ? para[i] : c);
  }
  return b.toString().toUpperCase().trim();
}

/// O nome do professor na grade ("Ana Nayara") pertence ao usuário
/// ("Ana Nayara Silva")? Todas as palavras da grade precisam estar no nome.
bool nomeCombina(String nomeNaGrade, String nomeDoUsuario) {
  final grade = semAcento(nomeNaGrade).split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final usuario = semAcento(nomeDoUsuario).split(RegExp(r'\s+')).toSet();
  return grade.isNotEmpty && grade.every(usuario.contains);
}

// ---------------------------------------------------------------------------
// Conteúdo institucional (vindo do protótipo, com erros de digitação corrigidos)
// ---------------------------------------------------------------------------

const String sobreEscola =
    'A $nomeEscola é uma escola técnica comprometida com a formação '
    'profissional e cidadã, oferecendo ensino de qualidade e preparando os '
    'alunos para os desafios do mercado de trabalho.';

const String enderecoEscola = 'Loteamento Frei Damião';
const List<String> telefonesEscola = ['(87) 98863-8350'];

class Contato {
  final String nome;
  final String cargo;
  final String telefone; // somente dígitos com DDI, ex.: 5587981315064
  final String email;
  const Contato(this.nome, this.cargo, this.telefone, this.email);
}

const List<Contato> contatosEscola = [
  Contato('Gestão ETE', 'Secretaria e gestão', '5587988638350',
      'gestaoeteadc@hotmail.com'),
  Contato('Leandro Rocha', 'Diretor', '5587981315064',
      'leandrorochaete@gmail.com'),
  Contato('Noel Félix', 'Assistente de Gestão', '5587999124595',
      'noelfelixete@gmail.com'),
  Contato('Arthur Lima', 'Professor - Desenvolvedor de Sistemas', '5581997754040',
      'arthurlima.upe@gmail.com'),
];

/// Créditos do aplicativo (tela Contatos).
const String instituicaoParceira = 'Artez Comunicação Visual';
const String coordenadorProjeto = 'Edyedson Arthur P. de Lima';
const List<String> desenvolvedoresApp = [
  'Gabriel Santos da Silva',
  'Luiz Henrique Cardoso dos Santos',
];
const List<String> designersApp = [
  'Evelyn Mylaine Ramos da Silva',
  'Maria Clara da Silva',
];
const String criatividadeApp = 'Maria Sophia de Araújo Santos';
const String liderApp = 'Claudyanny Joelly Oliveira de Mélo';
