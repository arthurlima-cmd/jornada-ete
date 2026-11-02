import 'package:flutter/material.dart';

import '../dados/modelos.dart';
import '../servicos/notificacoes.dart';
import 'aba_avisos.dart';
import 'aba_horarios.dart';
import 'aba_inicio.dart';
import 'aba_perfil.dart';
import 'aba_provas.dart';

/// Estrutura principal com barra de navegação inferior.
/// Substitui os botões "voltar" que empilhavam páginas no protótipo.
class InicioShell extends StatefulWidget {
  final Usuario usuario;
  const InicioShell({super.key, required this.usuario});
  @override
  State<InicioShell> createState() => _InicioShellState();
}

class _InicioShellState extends State<InicioShell> {
  int _aba = 0;

  void _irPara(int i) => setState(() => _aba = i);

  void _abrirAvisos() {
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    _irPara(3);
  }

  @override
  void initState() {
    super.initState();
    Notificacoes.abrirAvisos.addListener(_abrirAvisos);
    Notificacoes.configurar(widget.usuario);
  }

  @override
  void didUpdateWidget(covariant InicioShell antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.usuario.turma != widget.usuario.turma ||
        antigo.usuario.tipo != widget.usuario.tipo) {
      Notificacoes.configurar(widget.usuario); // trocou de turma
    }
  }

  @override
  void dispose() {
    Notificacoes.abrirAvisos.removeListener(_abrirAvisos);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final abas = <Widget>[
      AbaInicio(usuario: u, irPara: _irPara),
      AbaHorarios(usuario: u),
      AbaProvas(usuario: u),
      AbaAvisos(usuario: u),
      AbaPerfil(usuario: u),
    ];

    return PopScope(
      canPop: _aba == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _irPara(0); // "voltar" do Android leva ao Início
      },
      child: Scaffold(
        body: IndexedStack(index: _aba, children: abas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _aba,
          onDestinationSelected: _irPara,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Horários',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Provas',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Avisos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
