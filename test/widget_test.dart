import 'package:flutter_test/flutter_test.dart';
import 'package:jornada_ete/constantes.dart';

void main() {
  test('as 9 aulas ficam em ordem alfabética = ordem do dia', () {
    final ordenadas = [...aulasDoDia]..sort();
    expect(ordenadas, aulasDoDia);
    expect(aulasDoDia.length, 9);
  });

  test('slug remove acentos e símbolos', () {
    expect(slug('1º TDG'), '1TDG');
  });
}
