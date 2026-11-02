import 'package:flutter/material.dart';

import '../constantes.dart';
import '../tema.dart';
import 'login.dart';

/// Escolha do perfil. Agora a escolha é PASSADA para o login
/// (no protótipo, os dois botões abriam a mesma tela e a escolha se perdia).
class ConectarTela extends StatelessWidget {
  const ConectarTela({super.key});

  void _abrir(BuildContext context, String perfil) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginTela(perfil: perfil)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.azul,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logotipo_mono_branco.png',
                      width: 220,
                      fit: BoxFit.contain,
                      semanticLabel: nomeEscola,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_rounded,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jornada ETE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Como você vai usar o app?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CartaoPerfil(
                    icone: Icons.backpack_outlined,
                    titulo: 'Sou estudante',
                    descricao:
                        'Veja seus horários, provas, avisos e o cardápio da escola.',
                    onTap: () => _abrir(context, 'estudante'),
                  ),
                  const SizedBox(height: 12),
                  _CartaoPerfil(
                    icone: Icons.co_present_outlined,
                    titulo: 'Sou professor(a)',
                    descricao:
                        'Cadastre horários e provas e publique avisos para as turmas.',
                    onTap: () => _abrir(context, 'professor'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoPerfil extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  const _CartaoPerfil({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Cores.azulClaro,
                child: Icon(icone, color: Cores.azul, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: const TextStyle(color: Cores.textoSecundario),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Cores.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}
