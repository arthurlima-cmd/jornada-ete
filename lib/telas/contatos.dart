import 'package:flutter/material.dart';

import '../constantes.dart';
import '../tema.dart';
import '../widgets/comuns.dart';

/// Contatos com botões de ligar, WhatsApp e e-mail
/// (no protótipo, eram textos posicionados com espaços e não clicáveis).
class ContatosTela extends StatelessWidget {
  const ContatosTela({super.key});

  String _formatar(String tel) {
    // 5587981315064 -> (87) 9 8131-5064
    if (tel.length != 13) return tel;
    return '(${tel.substring(2, 4)}) ${tel.substring(4, 5)} '
        '${tel.substring(5, 9)}-${tel.substring(9)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contatos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final c in contatosEscola)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Cores.borda),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.nome,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(c.cargo, style: const TextStyle(color: Cores.textoSecundario)),
                  const SizedBox(height: 8),
                  Text(_formatar(c.telefone)),
                  Text(c.email),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Botao(
                        icone: Icons.call_outlined,
                        texto: 'Ligar',
                        onTap: () => abrirLink(context, 'tel:+${c.telefone}'),
                      ),
                      _Botao(
                        icone: Icons.chat_outlined,
                        texto: 'WhatsApp',
                        onTap: () => abrirLink(context, 'https://wa.me/${c.telefone}'),
                      ),
                      _Botao(
                        icone: Icons.mail_outline,
                        texto: 'E-mail',
                        onTap: () => abrirLink(context, 'mailto:${c.email}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const _Creditos(),
        ],
      ),
    );
  }
}

class _Botao extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;
  const _Botao({required this.icone, required this.texto, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        onPressed: onTap,
        icon: Icon(icone, size: 18),
        label: Text(texto),
      );
}

/// Créditos: instituição parceira e equipe do projeto.
class _Creditos extends StatelessWidget {
  const _Creditos();

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
