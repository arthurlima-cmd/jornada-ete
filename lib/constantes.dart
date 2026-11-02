// Valores fixos usados em todo o app.

const String nomeEscola = 'ETE Antônio Dourado Cavalcanti';

/// Dias letivos, no mesmo formato gravado no campo `dia_semana`.
const List<String> diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'];

const Map<String, String> diasExtenso = {
  'Seg': 'Segunda-feira',
  'Ter': 'Terça-feira',
  'Qua': 'Quarta-feira',
  'Qui': 'Quinta-feira',
  'Sex': 'Sexta-feira',
};

/// As 9 aulas do dia, no formato gravado no campo `horario`.
/// Começam com o número da aula, então a ordem alfabética já é a ordem certa.
const List<String> aulasDoDia = [
  '1ª aula · 07:40',
  '2ª aula · 08:30',
  '3ª aula · 09:40',
  '4ª aula · 10:30',
  '5ª aula · 11:20',
  '6ª aula · 13:00',
  '7ª aula · 13:50',
  '8ª aula · 15:00',
  '9ª aula · 15:50',
];

/// Usadas apenas enquanto a coleção `turmas` estiver vazia.
const List<String> turmasPadrao = ['1º TDG', '2º TDG', '3º TDG'];

const String todasAsTurmas = 'Todas as turmas';

const List<String> tiposDeProva = [
  'Prova',
  'Teste',
  'Trabalho',
  'Seminário',
  'Recuperação',
];

const List<String> tiposDeAviso = ['Aviso', 'Evento', 'Atividade'];

const List<String> refeicoes = [
  'Café da manhã',
  'Lanche da manhã',
  'Almoço',
  'Lanche da tarde',
];

/// Dia letivo de hoje ("Seg" ... "Sex"). Sábado e domingo retornam "Seg".
String diaDeHoje() {
  final w = DateTime.now().weekday; // 1 = segunda ... 7 = domingo
  if (w >= 1 && w <= 5) return diasSemana[w - 1];
  return 'Seg';
}

bool hojeEhDiaLetivo() => DateTime.now().weekday <= 5;

/// Remove acentos, espaços e símbolos para montar IDs de documento.
String slug(String texto) => texto.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

/// Número da aula (1..9) a partir do texto "1ª aula · 07:40".
String numeroDaAula(String horario) =>
    horario.isEmpty ? '0' : horario.substring(0, 1);

// ---------------------------------------------------------------------------
// Conteúdo institucional (vindo do protótipo, com erros de digitação corrigidos)
// ---------------------------------------------------------------------------

const String sobreEscola =
    'A $nomeEscola é uma escola técnica comprometida com a formação '
    'profissional e cidadã, oferecendo ensino de qualidade e preparando os '
    'alunos para os desafios do mercado de trabalho.';

const String enderecoEscola = 'Loteamento Frei Damião';
const List<String> telefonesEscola = ['(87) 3773-4940', '(87) 3773-4039'];

class Contato {
  final String nome;
  final String cargo;
  final String telefone; // somente dígitos com DDI, ex.: 5587981315064
  final String email;
  const Contato(this.nome, this.cargo, this.telefone, this.email);
}

const List<Contato> contatosEscola = [
  Contato('Gestão ETE', 'Secretaria e gestão', '5587988638350',
      'eteadc2014@gmail.com'),
  Contato('Leandro Rocha', 'Diretor', '5587981315064',
      'leandrorochaete@gmail.com'),
  Contato('Arthur Lima', 'Professor', '5581997754040',
      'arthurlima.upe@gmail.com'),
  Contato('Noel Félix', 'Professor', '5587999124595', 'noelfelixete@gmail.com'),
];
