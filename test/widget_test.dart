import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jornada_ete/constantes.dart';

void main() {
  test('integrado: 9 aulas em ordem', () {
    expect(aulasIntegrado.length, 9);
    expect([...aulasIntegrado]..sort(), aulasIntegrado);
  });

  test('subsequente: 5 aulas por noite em ordem', () {
    expect(aulasSubsequente.length, 5);
    expect([...aulasSubsequente]..sort(), aulasSubsequente);
  });

  test('modalidade deduzida pelo nome', () {
    expect(modalidadePeloNome('1º TDG A'), modalidadeIntegrado);
    expect(modalidadePeloNome('2º TND'), modalidadeIntegrado);
    expect(modalidadePeloNome('3º STDG'), modalidadeSubsequente);
    expect(modalidadePeloNome('1º STND'), modalidadeSubsequente);
  });

  test('turmas oficiais: 12 do integrado e 6 do subsequente', () {
    final sub = turmasDaEscola.where((t) => t.modalidade == modalidadeSubsequente);
    expect(turmasDaEscola.length - sub.length, 12);
    expect(sub.length, 6);
  });

  test('slug remove acentos e símbolos', () {
    expect(slug('1º TDG A'), '1TDGA');
  });

  test('nomes de professor combinam sem acento', () {
    expect(nomeCombina('Ana Nayara', 'Ana Nayara Silva'), isTrue);
    expect(nomeCombina('Ítalo', 'italo souza'), isTrue);
    expect(nomeCombina('Géssica', 'Gessica Lima'), isTrue);
    expect(nomeCombina('Arthur', 'Lorena Arthuria'), isFalse);
  });

  test('horário oficial 2026: turmas, dias e aulas válidos', () {
    final dados = jsonDecode(
        File('assets/dados/horario_2026.json').readAsStringSync()) as List;
    expect(dados.length, 628);
    final turmas = turmasPadrao.toSet();
    for (final r in dados.cast<Map<String, dynamic>>()) {
      expect(turmas.contains(r['turma']), isTrue, reason: r['turma']);
      expect(diasSemana.contains(r['dia']), isTrue);
      final n = r['aula'] as int;
      expect(n >= 1 && n <= aulasDaModalidade(modalidadePeloNome(r['turma'])).length,
          isTrue, reason: '$r');
      expect((r['disciplina'] as String).isNotEmpty, isTrue);
      expect((r['professor'] as String).isNotEmpty, isTrue);
    }
  });
}
