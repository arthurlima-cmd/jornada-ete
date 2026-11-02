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
  });

  test('turmas oficiais: 12 do integrado e 3 do subsequente', () {
    final sub = turmasDaEscola.where((t) => t.modalidade == modalidadeSubsequente);
    expect(turmasDaEscola.length - sub.length, 12);
    expect(sub.length, 3);
  });

  test('slug remove acentos e símbolos', () {
    expect(slug('1º TDG A'), '1TDGA');
  });
}
