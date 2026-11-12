import 'package:flutter/material.dart';

import '../constantes.dart';
import '../tema.dart';

/// Quadro "Sobre o aplicativo" (créditos), usado em Contatos e em
/// Informações da escola.
class QuadroSobreApp extends StatelessWidget {
  const QuadroSobreApp({super.key});

  @override
  Widget build(BuildContext context) {
    const rotulo = TextStyle(fontWeight: FontWeight.w700, color: Cores.azul);
    Widget linha(String titulo, String nome) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$titulo: ', style: rotulo),
            TextSpan(text: nome),
          ])),
        );
    Widget lista(String titulo, List<String> nomes) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$titulo:', style: rotulo),
              for (final n in nomes)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text('•  $n'),
                ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre o aplicativo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          linha('Instituição Parceira', instituicaoParceira),
          linha('Coordenador', coordenadorProjeto),
          lista('Desenvolvedores', desenvolvedoresApp),
          lista('Designer', designersApp),
          linha('Criatividade', criatividadeApp),
          linha('Líder', liderApp),
        ],
      ),
    );
  }
}
