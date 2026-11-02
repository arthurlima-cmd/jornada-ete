import 'package:flutter/material.dart';

import '../constantes.dart';
import '../tema.dart';
import '../widgets/comuns.dart';

/// "Minha ETE": informações institucionais, com endereço e telefones clicáveis.
class InfoEscolaTela extends StatelessWidget {
  const InfoEscolaTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informações da escola')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Cores.borda),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logotipo_eteadc.png',
                width: 260,
                fit: BoxFit.contain,
                semanticLabel: nomeEscola,
                errorBuilder: (_, __, ___) => const Text(
                  nomeEscola,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Cores.azul,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const TituloSecao('Sobre a instituição'),
          const Text(sobreEscola, style: TextStyle(fontSize: 16, height: 1.5)),
          const TituloSecao('Endereço'),
          Card(
            elevation: 0,
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.place_outlined, color: Cores.azul),
              title: const Text(enderecoEscola),
              subtitle: const Text('Toque para abrir no mapa'),
              onTap: () => abrirLink(
                context,
                'https://www.google.com/maps/search/?api=1&query='
                '${Uri.encodeComponent('$nomeEscola $enderecoEscola')}',
              ),
            ),
          ),
          const TituloSecao('Telefones'),
          for (final t in telefonesEscola)
            Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.call_outlined, color: Cores.azul),
                title: Text(t),
                subtitle: const Text('Toque para ligar'),
                onTap: () =>
                    abrirLink(context, 'tel:${t.replaceAll(RegExp(r'[^0-9]'), '')}'),
              ),
            ),
        ],
      ),
    );
  }
}
