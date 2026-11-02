import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../widgets/comuns.dart';
import 'completar_perfil.dart';
import 'conectar.dart';
import 'inicio_shell.dart';

/// Decide a primeira tela:
///  - sem login            -> Conectar (escolha estudante/professor)
///  - logado sem perfil    -> Completar perfil
///  - logado com perfil    -> Menu principal
/// Quem já está logado vai direto ao menu (no protótipo, sempre voltava ao login).
class PortaoAuth extends StatefulWidget {
  const PortaoAuth({super.key});
  @override
  State<PortaoAuth> createState() => _PortaoAuthState();
}

class _PortaoAuthState extends State<PortaoAuth> {
  final Stream<User?> _auth = FirebaseAuth.instance.authStateChanges();
  final _memo = MemoStream<Usuario?>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth,
      builder: (context, snapAuth) {
        if (snapAuth.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Carregando());
        }
        final user = snapAuth.data;
        if (user == null) return const ConectarTela();

        return StreamBuilder<Usuario?>(
          stream: _memo.obter(user.uid, () => Repo.usuario(user.uid)),
          builder: (context, snap) {
            if (snap.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ErroCarregar(erro: snap.error),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text('Sair'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Carregando());
            }
            final usuario = snap.data;
            if (usuario == null) return CompletarPerfilTela(user: user);
            return InicioShell(
              key: ValueKey(usuario.uid),
              usuario: usuario,
            );
          },
        );
      },
    );
  }
}
