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
              color: Cores.azul,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.apartment, color: Colors.white, size: 36),
                SizedBox(height: 10),
                Text(
                  nomeEscola,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
